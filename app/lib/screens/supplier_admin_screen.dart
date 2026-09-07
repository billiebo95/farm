import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/order.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/chip_button.dart';

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
