import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';
import 'qty_stepper.dart';

/// Full price breakdown + quantity entry for one product, opened by
/// tapping a catalog row.
class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final qty = app.cart[product.id] ?? 0;
    final price = app.finalPrice(product.basePrice);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFD8DEDC), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Text(product.name, style: AppText.h3),
            const SizedBox(height: 3),
            Text(product.producer, style: AppText.body.copyWith(fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.9,
              children: [
                _Fact(label: 'Остаток', value: '${product.stock} пачек'),
                _Fact(label: 'Кратность упаковки', value: '${product.minOrder} шт'),
                _Fact(label: 'Срок годности', value: 'до ${product.period}'),
                _Fact(label: 'Маркировка', value: product.requiresMarking ? 'ЧЗ, обязательна' : 'не требуется'),
                _Fact(label: 'Штрихкод', value: product.barcode, mono: true),
                _Fact(label: 'Код товара', value: product.id, mono: true),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.borderCard), borderRadius: BorderRadius.circular(13)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: AppColors.screenBg,
                    child: const Text('Как считается ваша цена', style: AppText.label),
                  ),
                  _PriceRow('Базовая цена прайса', app.money(product.basePrice)),
                  _PriceRow('Скидка на прайс', app.pct(app.globalDiscountValue)),
                  _PriceRow('Персональная по коду', app.pct(app.myDisc), valueColor: AppColors.accent),
                  _PriceRow('Цена для вас', app.money(price), bold: true, bg: const Color(0xFFF8FAF9)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: QtyStepper(
                    text: app.qtyText(product),
                    onChanged: (v) => app.typeQty(product, v),
                    onCommit: () => app.commitQty(product),
                    onInc: () => app.bump(product, 1),
                    onDec: () => app.bump(product, -1),
                    height: 46,
                    buttonSize: 44,
                    pillBg: AppColors.chipBg,
                    filledInc: false,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 10),
                PrimaryButton(
                  label: '+ уп. ${product.minOrder}',
                  onPressed: () => app.bump(product, product.minOrder),
                  fullWidth: false,
                  height: 52,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${app.money(price)} за пачку', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                Text(app.money(qty * price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontFamily: mono ? 'monospace' : null, fontWeight: FontWeight.w600, fontSize: mono ? 13 : 14, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.bold = false, this.bg, this.valueColor});
  final String label;
  final String value;
  final bool bold;
  final Color? bg;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: bg,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderHairline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 13 : 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: AppColors.textMuted)),
          Text(value, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
