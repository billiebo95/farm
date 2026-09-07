import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../data/price_sync_service.dart';
import '../models/order.dart';
import '../models/product.dart';

enum AppScreen { login, registration, catalog, cart, orders, profile, supplierLock, supplierAdmin }

enum AdminTab { discounts, price, orders }

const List<(AdminTab, String)> kAdminTabs = [
  (AdminTab.discounts, 'Скидки'),
  (AdminTab.price, 'Прайс и DBF'),
  (AdminTab.orders, 'Заказы клиентов'),
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

  AppState({PriceSyncService? priceSync}) : _priceSync = priceSync ?? const PriceSyncService() {
    // Live price on launch, then keep it fresh in the background — the
    // Google Apps Script endpoint itself re-checks Google Drive every 10
    // minutes, so polling any faster wouldn't see anything new.
    syncPrice(silent: true);
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) => syncPrice(silent: true));
  }

  final PriceSyncService _priceSync;
  Timer? _autoSyncTimer;

  // ---- navigation ----
  AppScreen screen = AppScreen.login;
  int regStep = 0;
  String? sheetId; // product id shown in the detail bottom sheet
  String? openOrderNumber; // order shown in the full-screen detail view

  // ---- login / session ----
  String loginCode = '190172-04';

  // ---- registration draft ----
  String regName = 'Аптека «Вита-Плюс»';
  String regPhone = '+7 922 418-06-31';
  String regInn = '7712045890';
  String regAddr = 'Грозный, ул. А. Шерипова, 14';
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
    if (!silent) flash('Читаю прайс с Google Диска…');
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
      if (!silent) flash('Не удалось обновить прайс: $e');
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
    if (c != null) {
      regName = c.name;
      region = c.region;
    }
    screen = AppScreen.catalog;
    flash('${c?.name ?? 'Аптека'} · скидка ${pct(globalDiscountValue + clientDisc(loginCode.trim()))}');
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

  void finishRegistration() {
    screen = AppScreen.catalog;
    notifyListeners();
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
    final code = loginCode.trim().isEmpty ? '190172-04' : loginCode.trim();
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
    if (cartTotal < minOrderSum) return;
    for (final entry in cart.entries) {
      final p = MockData.findProduct(entry.key)!;
      if (entry.value > p.stock) {
        flash('Недостаточно товара «${p.name}». Остаток: ${p.stock}');
        return;
      }
    }
    final number = 'Z${_orderSuffix()}';
    final code = loginCode.trim().isEmpty ? '190172-04' : loginCode.trim();
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
    flash('Заказ $number отправлен · DBF выгружается на Google Диск');
    Future.delayed(const Duration(seconds: 2), () {
      final i = extraOrders.indexWhere((o) => o.number == number);
      if (i != -1) {
        extraOrders[i] = extraOrders[i].copyWith(dbf: DbfState.ok);
        notifyListeners();
      }
    });
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
