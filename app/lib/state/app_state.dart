import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/debt_sync_service.dart';
import '../data/mock_data.dart';
import '../data/order_sync_service.dart';
import '../data/price_sync_service.dart';
import '../models/client.dart';
import '../models/debt.dart';
import '../models/order.dart';
import '../models/product.dart';

enum AppScreen { login, registration, catalog, cart, orders, profile, supplierLock, supplierAdmin }

enum AdminTab { discounts, price, orders, debts }

const List<(AdminTab, String)> kAdminTabs = [
  (AdminTab.discounts, 'Скидки'),
  (AdminTab.price, 'Прайс и DBF'),
  (AdminTab.orders, 'Заказы клиентов'),
  (AdminTab.debts, 'Долги'),
];

/// App-wide store: navigation, cart, discounts, catalog search/filter,
/// registration draft, and the supplier/admin panel. Backed by the mock
/// price list / client registry / order history in [MockData] — there is
/// no backend wired up yet (see the "Focus on these files" handoff note).
///
/// This is a straight port of the state machine and pricing/order logic
/// authored in the `Component` class of `Аптека Опт v2.dc.html`.
class AppState extends ChangeNotifier {
  static const int minOrderSum = 15000;
  static const int _defaultGlobalDiscount = -3;
  static const _autoSyncInterval = Duration(minutes: 10);

  AppState({PriceSyncService? priceSync, OrderSyncService? orderSync, DebtSyncService? debtSync})
      : _priceSync = priceSync ?? const PriceSyncService(),
        _orderSync = orderSync ?? const OrderSyncService(),
        _debtSync = debtSync ?? const DebtSyncService() {
    // Live price on launch, then keep it fresh in the background — the
    // Google Apps Script endpoint itself re-checks Google Drive every 10
    // minutes, so polling any faster wouldn't see anything new.
    syncPrice(silent: true);
    // Same idea for the debt ledger, so every admin device converges on the
    // same balances rather than only what it posted itself.
    syncDebts();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      syncPrice(silent: true);
      syncDebts();
    });
  }

  final PriceSyncService _priceSync;
  final OrderSyncService _orderSync;
  final DebtSyncService _debtSync;
  Timer? _autoSyncTimer;

  // ---- navigation ----
  AppScreen screen = AppScreen.login;
  int regStep = 0;
  String? sheetId; // product id shown in the detail bottom sheet
  String? openOrderNumber; // order shown in the full-screen detail view

  // ---- login / session ----
  String loginCode = '';

  // ---- registration draft ----
  // Also doubles as the signed-in pharmacy's own editable profile once
  // logged in (see ProfileScreen) — empty until the user fills it in,
  // either through registration or by editing the account tab.
  String regName = '';
  String regPhone = '';
  String regInn = '';
  String regAddr = '';
  String region = MockData.regions.first;

  // ---- catalog ----
  String query = '';
  String filter = MockData.catalogFilters.first;
  bool priceStale = true;
  String priceUpdatedAt = 'сегодня, 08:14';
  bool syncing = false;

  // ---- cart ----
  final Map<String, int> cart = {};
  // Text currently being typed into a qty field, keyed by product id, shared
  // by the catalog row / cart line / detail sheet for that product — mirrors
  // `drafts` in the prototype.
  final Map<String, String> drafts = {};
  String comment = '';

  // ---- orders placed this session ----
  final List<Order> extraOrders = [];

  // ---- toast ----
  String? toast;
  Timer? _toastTimer;

  // ---- supplier / admin ----
  String pin = '';
  String pinMsg = '';
  AdminTab adminTab = AdminTab.discounts;
  String adminRegion = 'Все';
  int? globalDiscount; // null => use _defaultGlobalDiscount
  String? globalDraft;
  final Map<String, int> clientDiscs = {};
  final Map<String, String> clientDiscDrafts = {};

  // ---- supplier / admin — debts ----
  final Map<String, List<DebtOperation>> debtOps = {for (final e in MockData.debtOps.entries) e.key: [...e.value]};
  final Map<String, String> debtChargeDrafts = {};
  final Map<String, String> debtPaymentDrafts = {};
  final Map<String, String> debtComments = {};

  @override
  void dispose() {
    _toastTimer?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  // ───────────────────────── formatting ─────────────────────────

  String money(num n) {
    final rounded = n.round();
    final digits = rounded.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return '${rounded < 0 ? '-' : ''}$buf ₽';
  }

  String pct(int v) => '${v > 0 ? '+' : ''}$v%';

  // ───────────────────────── registration status ─────────────────────────

  /// Whether the currently entered delivery code belongs to a registered
  /// pharmacy — gates ordering (see [placeOrder]) but never browsing: an
  /// unregistered visitor can still look through the catalog.
  bool get isRegistered => MockData.findClient(loginCode.trim()) != null;

  /// Name to show in headers/cards before/without a completed registration.
  String get displayName => regName.trim().isEmpty ? 'Гостевой доступ' : regName.trim();

  // ───────────────────────── discounts / pricing ─────────────────────────

  int get globalDiscountValue => globalDiscount ?? _defaultGlobalDiscount;

  int clientDisc(String code) => clientDiscs[code] ?? MockData.findClient(code)?.discount ?? 0;

  int get myDisc => clientDisc(loginCode.trim());

  int get totalDisc => globalDiscountValue + myDisc;

  /// Combined price-list discount + personal discount, applied (or, if
  /// positive, added as a markup) to [base].
  double finalPrice(double base, {String? code}) {
    final d = globalDiscountValue + clientDisc(code ?? loginCode.trim());
    if (d == 0) return base;
    return d < 0 ? base * (1 - d.abs() / 100) : base * (1 + d / 100);
  }

  // ───────────────────────── toast ─────────────────────────

  void flash(String msg) {
    _toastTimer?.cancel();
    toast = msg;
    notifyListeners();
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      toast = null;
      notifyListeners();
    });
  }

  // ───────────────────────── cart qty handling ─────────────────────────

  void setQty(Product p, int next) {
    final q = next.clamp(0, p.stock);
    if (q == 0) {
      cart.remove(p.id);
    } else {
      cart[p.id] = q;
    }
    drafts.remove(p.id);
    notifyListeners();
  }

  void bump(Product p, int delta) {
    final cur = cart[p.id] ?? 0;
    if (delta > 0 && cur + delta > p.stock) {
      flash(p.stock == 0 ? 'Товара нет на складе — сообщим о поступлении' : 'Недостаточно товара. Остаток: ${p.stock}');
      return;
    }
    setQty(p, cur + delta);
  }

  void typeQty(Product p, String raw) {
    drafts[p.id] = raw.replaceAll(RegExp(r'[^0-9]'), '');
    notifyListeners();
  }

  void commitQty(Product p) {
    final raw = drafts[p.id];
    if (raw == null) return;
    final n = int.tryParse(raw);
    if (n == null || n <= 0) {
      setQty(p, 0);
      return;
    }
    if (n > p.stock) {
      flash('Недостаточно товара. Остаток: ${p.stock}');
      setQty(p, p.stock);
      return;
    }
    setQty(p, n);
  }

  void removeFromCart(Product p) {
    setQty(p, 0);
    flash('Позиция удалена из заказа');
  }

  String qtyText(Product p) {
    final d = drafts[p.id];
    if (d != null) return d;
    final q = cart[p.id] ?? 0;
    return q > 0 ? '$q' : '';
  }

  void clearCart() {
    cart.clear();
    drafts.clear();
    flash('Заказ очищен');
  }

  double get cartTotal => cart.entries.fold(0.0, (s, e) {
        final p = MockData.findProduct(e.key)!;
        return s + e.value * finalPrice(p.basePrice);
      });

  double get cartBaseTotal => cart.entries.fold(0.0, (s, e) {
        final p = MockData.findProduct(e.key)!;
        return s + e.value * p.basePrice;
      });

  int get cartPacks => cart.values.fold(0, (s, q) => s + q);
  bool get cartHasItems => cart.isNotEmpty;
  bool get cartMinMet => cartTotal >= minOrderSum;

  // ───────────────────────── catalog search / filter ─────────────────────────

  List<Product> get filteredProducts {
    final q = query.trim().toLowerCase();
    return MockData.priceList.where((p) {
      if (q.isNotEmpty) {
        final hay = '${p.name} ${p.producer} ${p.barcode} ${p.id}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      switch (filter) {
        case 'В заказе':
          return (cart[p.id] ?? 0) > 0;
        case 'Заканчивается':
          return p.lowStock;
        case 'Маркировка ЧЗ':
          return p.requiresMarking;
        case 'В наличии':
          return p.stock > 0;
        default:
          return true;
      }
    }).toList();
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setFilter(String v) {
    filter = v;
    notifyListeners();
  }

  void scan() => flash('Сканер штрихкода — откроется камера');

  /// Pulls the live price list from Google Drive (via the PriceSync Apps
  /// Script endpoint) and replaces [MockData.priceList] with it.
  ///
  /// [silent] skips the "Читаю прайс…" toast and, on failure, the error
  /// toast — used for the on-launch and background auto-refresh calls so
  /// they don't interrupt the user; the manual "Обновить" buttons pass the
  /// default (false) to get full feedback either way.
  Future<void> syncPrice({bool silent = false}) async {
    if (syncing) return;
    syncing = true;
    if (!silent) flash('Обновляю прайс…');
    notifyListeners();

    try {
      final result = await _priceSync.fetchPriceList();
      MockData.priceList = result.items;
      priceStale = false;
      priceUpdatedAt = _formatUpdatedAt(result.sourceModifiedAt ?? result.fetchedAt);
      if (!silent) flash('Прайс обновлён · ${result.items.length} позиций');
    } catch (e) {
      // Keep whatever price list we already had (seed data or a previous
      // successful sync) — a failed refresh shouldn't empty the catalog.
      // The underlying error (network/parsing detail) isn't shown to the
      // client — just that a refresh didn't happen.
      if (!silent) flash('Не удалось обновить прайс, попробуйте ещё раз');
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  String _formatUpdatedAt(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    if (sameDay) return 'сегодня, $time';
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}, $time';
  }

  // ───────────────────────── login / registration ─────────────────────────

  void setLoginCode(String v) {
    loginCode = v;
    notifyListeners();
  }

  void doLogin() {
    if (loginCode.trim().length < 4) {
      flash('Введите код доставки');
      return;
    }
    final c = MockData.findClient(loginCode.trim());
    screen = AppScreen.catalog;
    if (c != null) {
      regName = c.name;
      region = c.region;
      flash('${c.name} · скидка ${pct(globalDiscountValue + clientDisc(loginCode.trim()))}');
    } else {
      // Unknown code: let them browse, but ordering stays locked (see
      // placeOrder) until they complete registration.
      flash('Код не найден — прайс открыт для просмотра. Для заказа зарегистрируйте аптеку.');
    }
  }

  void goLogin() {
    screen = AppScreen.login;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void jumpToRegistration() {
    screen = AppScreen.registration;
    regStep = 0;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void regNext() {
    regStep = (regStep + 1).clamp(0, 2);
    notifyListeners();
  }

  /// Step back through registration, or return to login from the first step
  /// — used to give the (design-less) system back gesture somewhere to go.
  void regBack() {
    if (regStep == 0) {
      goLogin();
      return;
    }
    regStep -= 1;
    notifyListeners();
  }

  /// Registers the pharmacy being drafted in [regName]/[regPhone]/[regInn]/
  /// [regAddr]/[region], assigning it a fresh delivery code and logging in
  /// as it — unlocking ordering immediately (no manager review loop, unlike
  /// the copy on the pending screen suggests; there's no backend to review
  /// anything against here).
  void finishRegistration() {
    final code = _generateDeliveryCode();
    final name = regName.trim().isEmpty ? 'Аптека без названия' : regName.trim();
    MockData.clients = [...MockData.clients, Client(code: code, name: name, region: region, discount: 0, phone: regPhone.trim())];
    regName = name;
    loginCode = code;
    screen = AppScreen.catalog;
    flash('Аптека зарегистрирована · код доставки $code');
  }

  String _generateDeliveryCode() {
    final rnd = Random();
    String candidate;
    do {
      final client = 100000 + rnd.nextInt(900000);
      final suffix = rnd.nextInt(100).toString().padLeft(2, '0');
      candidate = '$client-$suffix';
    } while (MockData.findClient(candidate) != null);
    return candidate;
  }

  void setRegField({String? name, String? phone, String? inn, String? addr}) {
    if (name != null) regName = name;
    if (phone != null) regPhone = phone;
    if (inn != null) regInn = inn;
    if (addr != null) regAddr = addr;
    notifyListeners();
  }

  void pickRegion(String r) {
    region = r;
    flash('Регион: $r');
  }

  // ───────────────────────── orders ─────────────────────────

  List<Order> get allOrders => [...extraOrders, ...MockData.baseOrders];

  List<Order> get myOrders {
    final code = loginCode.trim();
    return allOrders.where((o) => o.code == code).toList();
  }

  List<Order> get adminOrders => allOrders.where((o) => adminRegion == 'Все' || o.region == adminRegion).toList();

  Order? get openOrder {
    if (openOrderNumber == null) return null;
    for (final o in allOrders) {
      if (o.number == openOrderNumber) return o;
    }
    return null;
  }

  void openOrderDetail(String number) {
    openOrderNumber = number;
    notifyListeners();
  }

  void closeOrderDetail() {
    openOrderNumber = null;
    notifyListeners();
  }

  void repeatOrder(Order o) {
    cart
      ..clear()
      ..addEntries(o.lines.map((l) => MapEntry(l.productId, l.qty)));
    drafts.clear();
    openOrderNumber = null;
    screen = AppScreen.cart;
    flash('Позиции заказа ${o.number} перенесены');
  }

  void setComment(String v) {
    comment = v;
    notifyListeners();
  }

  void placeOrder() {
    if (!isRegistered) {
      flash('Чтобы оформить заказ, зарегистрируйте аптеку');
      jumpToRegistration();
      return;
    }
    if (cartTotal < minOrderSum) return;
    for (final entry in cart.entries) {
      final p = MockData.findProduct(entry.key)!;
      if (entry.value > p.stock) {
        flash('Недостаточно товара «${p.name}». Остаток: ${p.stock}');
        return;
      }
    }
    final number = 'Z${_orderSuffix()}';
    final code = loginCode.trim();
    final lines = cart.entries.map((e) {
      final p = MockData.findProduct(e.key)!;
      return OrderLine(productId: e.key, qty: e.value, price: finalPrice(p.basePrice).roundToDouble());
    }).toList();
    final order = Order(
      number: number,
      date: 'сегодня',
      client: regName,
      code: code,
      region: region,
      status: OrderStatus.placed,
      comment: comment,
      dbf: DbfState.queue,
      lines: lines,
    );
    extraOrders.insert(0, order);
    cart.clear();
    drafts.clear();
    comment = '';
    screen = AppScreen.orders;
    flash('Заказ принят');
    _uploadOrder(order);
  }

  /// Fire-and-forget upload to the PriceSync endpoint's order log (an
  /// implementation detail — the client only ever sees "Заказ принят"/an
  /// error toast, never that it's specifically Google Drive on the other
  /// end). Updates the order's [DbfState] badge based on the outcome; a
  /// failure leaves the order visible rather than pretending it went
  /// through, but doesn't expose the underlying error to the client.
  Future<void> _uploadOrder(Order order) async {
    try {
      await _orderSync.submitOrder(order);
      final i = extraOrders.indexWhere((o) => o.number == order.number);
      if (i != -1) {
        extraOrders[i] = extraOrders[i].copyWith(dbf: DbfState.ok);
        notifyListeners();
      }
    } catch (e) {
      flash('Не удалось отправить заказ ${order.number}, попробуйте ещё раз');
    }
  }

  String _orderSuffix() {
    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    return ms.length > 10 ? ms.substring(ms.length - 10) : ms;
  }

  // ───────────────────────── supplier / admin ─────────────────────────

  void openSupplierLock() {
    screen = AppScreen.supplierLock;
    pin = '';
    pinMsg = '';
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void exitSupplier() {
    screen = AppScreen.catalog;
    openOrderNumber = null;
    notifyListeners();
  }

  void pressPinKey(String label) {
    if (label == '⌫') {
      pin = pin.isEmpty ? pin : pin.substring(0, pin.length - 1);
      pinMsg = '';
      notifyListeners();
      return;
    }
    if (label == 'C') {
      pin = '';
      pinMsg = '';
      notifyListeners();
      return;
    }
    var next = pin + label;
    if (next.length > 4) next = next.substring(0, 4);
    if (next.length < 4) {
      pin = next;
      pinMsg = '';
      notifyListeners();
      return;
    }
    if (next == MockData.supplierPassword) {
      pin = '';
      pinMsg = '';
      screen = AppScreen.supplierAdmin;
      adminTab = AdminTab.discounts;
    } else {
      pin = '';
      pinMsg = 'Неверный пароль';
    }
    notifyListeners();
  }

  void setAdminTab(AdminTab t) {
    adminTab = t;
    notifyListeners();
    // Pull the latest ledger the moment the tab is opened rather than
    // waiting for the next background tick — cheap, and it's the screen
    // where a stale balance would actually mislead someone.
    if (t == AdminTab.debts) syncDebts();
  }

  void setAdminRegion(String r) {
    adminRegion = r;
    notifyListeners();
  }

  void setGlobalDiscount(int v) {
    globalDiscount = v.clamp(-100, 100);
    globalDraft = null;
    notifyListeners();
  }

  void incGlobalDiscount() => setGlobalDiscount(globalDiscountValue + 1);
  void decGlobalDiscount() => setGlobalDiscount(globalDiscountValue - 1);

  void typeGlobalDiscount(String raw) {
    globalDraft = raw.replaceAll(RegExp(r'[^0-9-]'), '');
    notifyListeners();
  }

  void commitGlobalDiscount() {
    final n = int.tryParse(globalDraft ?? '');
    setGlobalDiscount(n ?? globalDiscountValue);
  }

  void setClientDiscount(String code, int v) {
    clientDiscs[code] = v.clamp(-100, 100);
    clientDiscDrafts.remove(code);
    notifyListeners();
  }

  void incClientDiscount(String code) => setClientDiscount(code, clientDisc(code) + 1);
  void decClientDiscount(String code) => setClientDiscount(code, clientDisc(code) - 1);

  void typeClientDiscount(String code, String raw) {
    clientDiscDrafts[code] = raw.replaceAll(RegExp(r'[^0-9-]'), '');
    notifyListeners();
  }

  void commitClientDiscount(String code) {
    final n = int.tryParse(clientDiscDrafts[code] ?? '');
    setClientDiscount(code, n ?? clientDisc(code));
  }

  String clientDiscountText(String code) {
    final draft = clientDiscDrafts[code];
    return draft ?? '${clientDisc(code)}';
  }

  // ───────────────────────── supplier / admin — debts ─────────────────────────

  /// Current outstanding balance — the running balance left by the last
  /// operation, or 0 if the client has none on record.
  double debtBalance(String code) {
    final ops = debtOps[code];
    return (ops == null || ops.isEmpty) ? 0 : ops.last.balanceAfter;
  }

  bool hasDebt(String code) => debtBalance(code) > 0.005;

  /// Full history for the admin card / SMS text, newest first.
  List<DebtOperation> debtHistory(String code) => (debtOps[code] ?? const <DebtOperation>[]).reversed.toList();

  String debtChargeText(String code) => debtChargeDrafts[code] ?? '';
  String debtPaymentText(String code) => debtPaymentDrafts[code] ?? '';
  String debtCommentText(String code) => debtComments[code] ?? '';

  void typeDebtCharge(String code, String raw) {
    debtChargeDrafts[code] = raw.replaceAll(RegExp(r'[^0-9]'), '');
    notifyListeners();
  }

  void typeDebtPayment(String code, String raw) {
    debtPaymentDrafts[code] = raw.replaceAll(RegExp(r'[^0-9]'), '');
    notifyListeners();
  }

  void setDebtComment(String code, String v) {
    debtComments[code] = v;
    notifyListeners();
  }

  /// Charges a debt onto the client — a shipment handed over on credit.
  void addDebtCharge(String code) {
    final amount = double.tryParse(debtChargeDrafts[code] ?? '');
    if (amount == null || amount <= 0) {
      flash('Введите сумму долга');
      return;
    }
    debtChargeDrafts.remove(code);
    _appendDebtOp(code, DebtOpKind.charge, amount);
    flash('Долг добавлен · ${money(amount)}');
  }

  /// Registers a payment from the client — partial or, if it covers the
  /// whole balance, full. Clamped to the outstanding balance so the ledger
  /// never goes negative on a mistyped amount.
  void payDebt(String code) {
    final amount = double.tryParse(debtPaymentDrafts[code] ?? '');
    if (amount == null || amount <= 0) {
      flash('Введите сумму оплаты');
      return;
    }
    debtPaymentDrafts.remove(code);
    _registerPayment(code, amount);
  }

  /// Shortcut for "погасить полностью" — pays exactly the current balance.
  void payDebtInFull(String code) {
    final balance = debtBalance(code);
    if (balance <= 0.005) {
      flash('Долга нет — платить нечего');
      return;
    }
    debtPaymentDrafts.remove(code);
    _registerPayment(code, balance);
  }

  void _registerPayment(String code, double amount) {
    final balance = debtBalance(code);
    final applied = amount > balance ? balance : amount;
    if (applied <= 0) {
      flash('Долга нет — платить нечего');
      return;
    }
    _appendDebtOp(code, DebtOpKind.payment, applied);
    final left = debtBalance(code);
    if (amount > balance + 0.005) {
      flash('Списано ${money(applied)} — на остальное долга не было');
    } else {
      flash(left <= 0.005 ? 'Долг погашен полностью' : 'Оплата принята · остаток ${money(left)}');
    }
  }

  void _appendDebtOp(String code, DebtOpKind kind, double amount) {
    final ops = debtOps.putIfAbsent(code, () => []);
    final prevBalance = ops.isEmpty ? 0.0 : ops.last.balanceAfter;
    final balanceAfter = kind == DebtOpKind.charge ? prevBalance + amount : prevBalance - amount;
    final comment = (debtComments[code] ?? '').trim();
    final op = DebtOperation(kind: kind, amount: amount, date: 'сегодня', balanceAfter: balanceAfter, comment: comment);

    ops.add(op);
    debtComments.remove(code);
    notifyListeners();
    _uploadDebtOp(code, op);
  }

  /// Fire-and-forget upload to the debt journal — same shape as
  /// [_uploadOrder]: the operation is already applied locally, this just
  /// keeps the shared ledger (and every other admin device) in sync.
  Future<void> _uploadDebtOp(String code, DebtOperation op) async {
    try {
      await _debtSync.submitOperation(
        code: code,
        client: MockData.findClient(code)?.name ?? code,
        kind: op.kind,
        amount: op.amount,
        balanceAfter: op.balanceAfter,
        date: op.date,
        comment: op.comment,
      );
    } catch (e) {
      flash('Не удалось синхронизировать операцию по долгу, попробуйте ещё раз');
    }
  }

  /// Pulls the shared debt ledger from the Apps Script endpoint. Silent by
  /// design (called on launch, on tab switch and on the background timer,
  /// never as a direct user action) — a failure just leaves whatever ledger
  /// this device already has (seed data or its own local operations).
  Future<void> syncDebts() async {
    try {
      final remote = await _debtSync.fetchLedger();
      if (remote.isNotEmpty) {
        debtOps
          ..clear()
          ..addAll(remote);
        notifyListeners();
      }
    } catch (e) {
      // Keep whatever debt ledger we already have.
    }
  }

  /// Text quoted in the debt-history SMS — current balance plus the most
  /// recent operations, newest first.
  String debtSmsText(String code) {
    final name = MockData.findClient(code)?.name ?? code;
    final buf = StringBuffer('${MockData.companyName}. $name.\n');
    buf.write('Текущий долг: ${money(debtBalance(code))}.\n');
    buf.write('История операций:');
    for (final op in debtHistory(code).take(10)) {
      buf.write('\n${op.date} — ${op.kind.label} ${money(op.amount)}, остаток ${money(op.balanceAfter)}');
    }
    return buf.toString();
  }

  /// Sends the client's debt history by SMS, via the Apps Script endpoint's
  /// SMS gateway (see PriceSync.gs) — the client's own phone, from
  /// [Client.phone].
  Future<void> sendDebtSms(String code) async {
    final client = MockData.findClient(code);
    final phone = client?.phone.trim() ?? '';
    if (phone.isEmpty) {
      flash('У клиента не указан телефон');
      return;
    }
    flash('Отправляю СМС…');
    try {
      await _debtSync.sendSms(phone: phone, text: debtSmsText(code));
      flash('СМС отправлена · ${client?.name ?? code}');
    } catch (e) {
      flash('Не удалось отправить СМС: $e');
    }
  }

  // ───────────────────────── tab navigation ─────────────────────────

  void goCatalog() {
    screen = AppScreen.catalog;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void goCart() {
    screen = AppScreen.cart;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void goOrders() {
    screen = AppScreen.orders;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void goProfile() {
    screen = AppScreen.profile;
    sheetId = null;
    openOrderNumber = null;
    notifyListeners();
  }

  void openProductSheet(String id) {
    sheetId = id;
    notifyListeners();
  }

  void closeProductSheet() {
    sheetId = null;
    notifyListeners();
  }
}
