import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/chip_button.dart';
import '../widgets/product_card.dart';

/// The price list: search, filters, stale-price banner, and the dense
/// product list itself.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.filteredProducts;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 4, 14, 10),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.borderCard))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${app.displayName} · ${app.region}', style: AppText.label.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        const Text('Прайс', style: AppText.display),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.accentSoftBg, borderRadius: BorderRadius.circular(9)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(app.pct(app.totalDisc), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent)),
                        Text('прайс ${app.pct(app.globalDiscountValue)} · вам ${app.pct(app.myDisc)}',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: AppColors.accentSoftFg)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const AppIcon.search(color: AppColors.textTertiary),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        onChanged: app.setQuery,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Название, производитель, штрихкод, код',
                          hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    InkWell(onTap: app.scan, child: const Padding(padding: EdgeInsets.all(4), child: AppIcon.scan(color: AppColors.accent))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: MockData.catalogFilters
                    .map((f) => ChipButton(label: f, selected: app.filter == f, onTap: () => app.setFilter(f)))
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 14),
            children: [
              if (!app.isRegistered) _RegistrationBanner(app: app),
              if (app.priceStale) _StaleBanner(app: app),
              for (final p in items) ProductCard(product: p),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 44, horizontal: 20),
                  child: Column(
                    children: [
                      Text('Ничего не найдено', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.textPrimary)),
                      SizedBox(height: 6),
                      Text(
                        'Поиск идёт по наименованию, производителю, штрихкоду и коду товара.',
                        style: AppText.body,
                        textAlign: TextAlign.center,
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

class _RegistrationBanner extends StatelessWidget {
  const _RegistrationBanner({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF0D8C6)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Прайс открыт для просмотра. Чтобы оформлять заказы, зарегистрируйте аптеку.',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, height: 1.45, color: AppColors.dangerFg),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: TextButton(
              onPressed: app.jumpToRegistration,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.warnFg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              child: const Text('Зарегистрироваться', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF0D8C6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Прайс обновлён ${app.priceUpdatedAt}. Проверить обновления?',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, height: 1.45, color: AppColors.dangerFg),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: TextButton(
              onPressed: app.syncing ? null : app.syncPrice,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.warnFg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              child: Text(app.syncing ? '…' : 'Обновить', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
