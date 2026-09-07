import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/client.dart';
import '../models/debt.dart';
import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/chip_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/primary_button.dart';

/// Supplier-only panel: price-list discounts, the Google-Drive price/DBF
/// pipeline, and every client's orders — gated by [SupplierLockScreen].
class SupplierAdminScreen extends StatelessWidget {
  const SupplierAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: AppColors.screenBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
            color: AppColors.adminBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('АДМИНИСТРИРОВАНИЕ', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.adminAccent, letterSpacing: 0.7)),
                          const SizedBox(height: 3),
                          Text(MockData.companyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, height: 1.15, color: Colors.white, letterSpacing: -0.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: app.exitSupplier,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Выйти', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: kAdminTabs
                      .map((t) => ChipButton(
                            label: t.$2,
                            selected: app.adminTab == t.$1,
                            onTap: () => app.setAdminTab(t.$1),
                            height: 36,
                            idleBg: Colors.white.withValues(alpha: 0.12),
                            idleBorder: Colors.transparent,
                            idleFg: Colors.white,
                            flex: true,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (app.adminTab) {
              AdminTab.discounts => _DiscountsTab(app: app),
              AdminTab.price => _PriceTab(app: app),
              AdminTab.orders => _OrdersTab(app: app),
              AdminTab.debts => _DebtsTab(app: app),
            },
          ),
        ],
      ),
    );
  }
}

class _DiscountsTab extends StatelessWidget {
  const _DiscountsTab({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Скидка на весь прайс', style: AppText.label),
              const SizedBox(height: 11),
              Row(
                children: [
                  _StepBox(onTap: app.decGlobalDiscount, glyph: '−'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _DiscountField(
                          value: app.globalDraft ?? '${app.globalDiscountValue}',
                          onChanged: app.typeGlobalDiscount,
                          onCommit: app.commitGlobalDiscount,
                        ),
                        const SizedBox(height: 4),
                        const Text('процент · минус = скидка', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepBox(onTap: app.incGlobalDiscount, glyph: '+'),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderCard), borderRadius: BorderRadius.circular(15)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Индивидуально по коду доставки', style: AppText.label),
                    const SizedBox(height: 5),
                    const Text('Складывается со скидкой на прайс. Ниже — итог для клиента.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              for (final c in MockData.clients)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3)),
                                const SizedBox(height: 3),
                                Text('${c.code} · ${c.region}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          StatusChip(label: 'итог ${app.pct(app.globalDiscountValue + app.clientDisc(c.code))}', fg: AppColors.accent, bg: AppColors.accentSoftBg, fontSize: 12),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _StepBox(onTap: () => app.decClientDiscount(c.code), glyph: '−', size: 42, height: 40),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DiscountField(
                              value: app.clientDiscountText(c.code),
                              onChanged: (v) => app.typeClientDiscount(c.code, v),
                              onCommit: () => app.commitClientDiscount(c.code),
                              height: 40,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StepBox(onTap: () => app.incClientDiscount(c.code), glyph: '+', size: 42, height: 40),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBox extends StatelessWidget {
  const _StepBox({required this.onTap, required this.glyph, this.size = 48, this.height = 46});
  final VoidCallback onTap;
  final String glyph;
  final double size;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
        child: Text(glyph, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.accent)),
      ),
    );
  }
}

class _DiscountField extends StatefulWidget {
  const _DiscountField({required this.value, required this.onChanged, required this.onCommit, this.height = 46, this.fontSize = 22});
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
  final double height;
  final double fontSize;

  @override
  State<_DiscountField> createState() => _DiscountFieldState();
}

class _DiscountFieldState extends State<_DiscountField> {
  late final FocusNode _focus = FocusNode();
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onCommit();
    });
  }

  @override
  void didUpdateWidget(covariant _DiscountField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length), composing: TextRange.empty);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 1.5)),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onCommit(),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: widget.fontSize, color: AppColors.textPrimary),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
      ),
    );
  }
}

class _PriceTab extends StatelessWidget {
  const _PriceTab({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Прайс из Google Диска', style: AppText.label),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFC3CDCA), width: 1.5)),
                child: Column(
                  children: [
                    const Text('прайс_шах_сентябрь.xlsx', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 5),
                    const Text(
                      'Файл берётся из папки поставщика. Колонки: наименование, производитель, срок, цена, остаток, кратность, штрихкод, код.',
                      style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: app.syncing ? null : app.syncPrice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: Text(app.syncing ? 'Читаю файл…' : 'Обновить прайс', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              _KeyValueRow('Последнее обновление', app.priceUpdatedAt),
              const SizedBox(height: 5),
              _KeyValueRow('Позиций в прайсе', '${MockData.priceList.length} позиций'),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Выгрузка заказов', style: AppText.label),
              const SizedBox(height: 10),
              _KVDivided('Формат', 'DBF', mono: true),
              _KVDivided('Папка', 'Google Диск / Заказы'),
              _KVDivided('В очереди', '${app.extraOrders.where((o) => o.dbf == DbfState.queue).length} файлов', valueColor: AppColors.accent, last: true),
              const SizedBox(height: 11),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(11)),
                child: const Text(
                  'Структура столбцов — заглушка. Ждём вашу: подставим имена и типы полей один в один.',
                  style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim)),
      ],
    );
  }
}

class _KVDivided extends StatelessWidget {
  const _KVDivided(this.label, this.value, {this.mono = false, this.valueColor, this.last = false});
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: TextStyle(fontFamily: mono ? 'monospace' : null, fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final orders = app.adminOrders;
    final total = orders.fold<double>(0, (s, o) => s + o.total);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Заказов всего', value: '${orders.length}')),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Сумма', value: app.money(total))),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: ['Все', ...MockData.regions]
              .map((r) => ChipButton(label: r, selected: app.adminRegion == r, onTap: () => app.setAdminRegion(r)))
              .toList(),
        ),
        const SizedBox(height: 10),
        for (final o in orders) _AdminOrderCard(order: o, app: app),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderCard), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        ],
      ),
    );
  }
}

/// Per-client debt ledger: add a charge, register a payment (partial or, via
/// the shortcut, in full), and send the client an SMS with their operation
/// history — see [AppState]'s "supplier / admin — debts" section.
class _DebtsTab extends StatelessWidget {
  const _DebtsTab({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final totalDebt = MockData.clients.fold<double>(0, (s, c) => s + app.debtBalance(c.code));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Долг клиентов всего', style: AppText.label),
              Text(app.money(totalDebt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.dangerFg)),
            ],
          ),
        ),
        for (final c in MockData.clients) _ClientDebtCard(client: c, app: app),
      ],
    );
  }
}

class _ClientDebtCard extends StatelessWidget {
  const _ClientDebtCard({required this.client, required this.app});
  final Client client;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final code = client.code;
    final balance = app.debtBalance(code);
    final inDebt = app.hasDebt(code);
    final history = app.debtHistory(code);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3)),
                    const SizedBox(height: 3),
                    Text('${client.code} · ${client.region}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: client.phone.trim().isEmpty ? null : () => app.sendDebtSms(code),
                icon: const Icon(Icons.sms_outlined),
                color: AppColors.accent,
                disabledColor: AppColors.textTertiary,
                tooltip: client.phone.trim().isEmpty ? 'У клиента не указан телефон' : 'Отправить СМС с историей операций',
              ),
            ],
          ),
          const SizedBox(height: 4),
          StatusChip(
            label: inDebt ? 'Долг ${app.money(balance)}' : 'Долгов нет',
            fg: inDebt ? AppColors.dangerFg : AppColors.accent,
            bg: inDebt ? AppColors.dangerBg : AppColors.accentSoftBg,
            fontSize: 12,
          ),
          const SizedBox(height: 11),
          LabeledField.raw(
            value: app.debtCommentText(code),
            onChanged: (v) => app.setDebtComment(code, v),
            hint: 'Комментарий к операции (необязательно)',
            height: 40,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: LabeledField.raw(
                  value: app.debtChargeText(code),
                  onChanged: (v) => app.typeDebtCharge(code, v),
                  hint: 'Сумма долга, ₽',
                  height: 42,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              _DebtActionButton(label: 'Добавить долг', color: AppColors.dangerFg, onTap: () => app.addDebtCharge(code)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LabeledField.raw(
                  value: app.debtPaymentText(code),
                  onChanged: (v) => app.typeDebtPayment(code, v),
                  hint: 'Сумма оплаты, ₽',
                  height: 42,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              _DebtActionButton(label: 'Погасить', color: AppColors.accent, onTap: () => app.payDebt(code)),
            ],
          ),
          if (inDebt) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextOnlyButton(
                label: 'Погасить полностью · ${app.money(balance)}',
                onPressed: () => app.payDebtInFull(code),
                fontSize: 13,
              ),
            ),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 9),
            const Divider(height: 1, color: AppColors.borderHairline),
            const SizedBox(height: 9),
            const Text('История операций', style: AppText.label),
            const SizedBox(height: 6),
            for (final op in history.take(6)) _DebtOpRow(op: op, app: app),
          ],
        ],
      ),
    );
  }
}

class _DebtActionButton extends StatelessWidget {
  const _DebtActionButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

class _DebtOpRow extends StatelessWidget {
  const _DebtOpRow({required this.op, required this.app});
  final DebtOperation op;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final isCharge = op.kind == DebtOpKind.charge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${op.date} · ${op.kind.label}${op.comment.isEmpty ? '' : ' — ${op.comment}'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCharge ? '+' : '−'}${app.money(op.amount)}',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12, color: isCharge ? AppColors.dangerFg : AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.app});
  final Order order;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 9),
      onTap: () => app.openOrderDetail(order.number),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.number, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13)),
              StatusChip(label: order.status.label, fg: order.status.fg, bg: order.status.bg, fontSize: 11),
            ],
          ),
          const SizedBox(height: 7),
          Text(order.client, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 3),
          Text('${order.code} · ${order.region} · ${order.date}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textTertiary)),
          Container(
            margin: const EdgeInsets.only(top: 9),
            padding: const EdgeInsets.only(top: 9),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderHairline))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                StatusChip(label: order.dbf.label, fg: order.dbf.fg, bg: order.dbf.bg, mono: true),
                Text(app.money(order.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
