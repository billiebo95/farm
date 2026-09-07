import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icons.dart';
import '../widgets/labeled_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/qty_stepper.dart';

/// The current order draft: line items, delivery/payment summary, comment
/// and the "place order" checkout action.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lines = app.cart.entries.map((e) => (MockData.findProduct(e.key)!, e.value)).toList();
    final hasItems = app.cartHasItems;
    final enough = app.cartMinMet;
    final registered = app.isRegistered;
    final total = app.cartTotal;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.borderCard))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Заказ', style: AppText.display),
                    const SizedBox(height: 3),
                    Text(
                      hasItems ? '${lines.length} позиций · ${app.cartPacks} пачек' : 'Ни одной позиции',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (hasItems)
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: app.clearCart,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4D3C7)),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.dangerFg,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Очистить', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: !hasItems
              ? _EmptyCart(app: app)
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final (p, qty) in lines) _CartLine(product: p, qty: qty),
                    _DeliveryCard(app: app),
                  ],
                ),
        ),
        if (hasItems)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderCard))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('Итого без НДС', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(app.money(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textPrimary, letterSpacing: -0.4)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('Выгода по скидке', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    Text(app.money((app.cartBaseTotal - total).clamp(0, double.infinity)),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.accent)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    !registered
                        ? 'Аптека не зарегистрирована — заказ отправить нельзя'
                        : enough
                            ? 'Минимальная сумма заказа выполнена'
                            : 'Добавьте ещё на ${app.money(AppState.minOrderSum - total)} — минимум ${app.money(AppState.minOrderSum)}',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: (!registered || !enough) ? AppColors.warnFg : AppColors.accent),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: !registered ? app.jumpToRegistration : (enough ? app.placeOrder : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.disabledBg,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(registered ? 'Отправить заказ' : 'Зарегистрировать аптеку', style: AppText.button),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Заказ пуст', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Количество можно набрать вручную или стрелками — от 1 пачки.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'В прайс', onPressed: app.goCatalog, fullWidth: false, height: 48),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final price = app.finalPrice(product.basePrice);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
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
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${app.money(price)} за пачку · остаток ${product.stock}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => app.removeFromCart(product),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(9)),
                  child: const Center(child: AppIcon.trash(color: AppColors.dangerFg)),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderHairline))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                QtyStepper(
                  text: app.qtyText(product),
                  onChanged: (v) => app.typeQty(product, v),
                  onCommit: () => app.commitQty(product),
                  onInc: () => app.bump(product, 1),
                  onDec: () => app.bump(product, -1),
                  pillBg: AppColors.chipBg,
                  filledInc: false,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextOnlyButton(label: '+ уп. ${product.minOrder}', onPressed: () => app.bump(product, product.minOrder), fontSize: 11),
                    Text(app.money(qty * price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Доставка и оплата', style: AppText.label),
          const SizedBox(height: 11),
          _SummaryRow('Код доставки', app.loginCode.trim(), mono: true),
          _SummaryRow('Регион', app.region),
          _SummaryRow('Адрес', app.regAddr, alignRight: true),
          _SummaryRow('Оплата', 'Отсрочка 14 дней', last: true),
          const SizedBox(height: 12),
          const Text('Комментарий к заказу', style: AppText.label),
          const SizedBox(height: 7),
          LabeledField.raw(
            value: app.comment,
            onChanged: app.setComment,
            hint: 'Напр.: привезти до 12:00, звонить Ирине',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.mono = false, this.alignRight = false, this.last = false});
  final String label;
  final String value;
  final bool mono;
  final bool alignRight;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontFamily: mono ? 'monospace' : null, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
