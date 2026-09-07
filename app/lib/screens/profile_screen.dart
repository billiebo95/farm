import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/labeled_field.dart';
import '../widgets/primary_button.dart';

/// The pharmacy's account tab: editable identity, region, pricing info,
/// price sync and the entry point into the supplier admin panel.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.borderCard))),
          child: const Text('Кабинет', style: AppText.display),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _IdentityCard(app: app),
              AppCard(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Регион обслуживания', style: AppText.label),
                    const SizedBox(height: 10),
                    Row(
                      children: MockData.regions
                          .map((r) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: r == MockData.regions.first ? 8 : 0),
                                  child: _RegionTile(
                                    label: r,
                                    hint: r == 'Чечня' ? 'доставка ежедневно' : 'доставка 2 раза в неделю',
                                    selected: app.region == r,
                                    onTap: () => app.pickRegion(r),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderCard), borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    _InfoRow('Скидка на прайс', app.pct(app.globalDiscountValue)),
                    _InfoRow('Ваша персональная', app.pct(app.myDisc), valueColor: AppColors.accent),
                    _InfoRow('Прайс обновлён', app.priceUpdatedAt),
                    _InfoRow('Менеджер', 'Алексей К.', last: true),
                  ],
                ),
              ),
              SecondaryButton(
                label: app.syncing ? 'Обновляю…' : 'Обновить прайс',
                onPressed: app.syncing ? null : app.syncPrice,
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: app.openSupplierLock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Text('Администрирование', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identity card at the top of the account tab. In view mode it just shows
/// name/address/codes; tapping the pencil switches to editable fields for
/// name, phone and address (the delivery code itself is assigned at
/// registration and isn't user-editable) — changes save live, there's no
/// separate draft to discard.
class _IdentityCard extends StatefulWidget {
  const _IdentityCard({required this.app});
  final AppState app;

  @override
  State<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<_IdentityCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final code = app.loginCode.trim();

    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _editing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabeledField(label: 'Название аптеки', value: app.regName, onChanged: (v) => app.setRegField(name: v)),
                          const SizedBox(height: 10),
                          LabeledField(
                            label: 'Телефон',
                            value: app.regPhone,
                            onChanged: (v) => app.setRegField(phone: v),
                            mono: true,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          LabeledField(label: 'Адрес доставки', value: app.regAddr, onChanged: (v) => app.setRegField(addr: v)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, height: 1.25)),
                          const SizedBox(height: 3),
                          Text(
                            app.regAddr.isEmpty ? 'Адрес не указан' : app.regAddr,
                            style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                          ),
                          if (app.regPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(app.regPhone, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  if (_editing) app.flash('Данные аптеки сохранены');
                  _editing = !_editing;
                }),
                icon: Icon(_editing ? Icons.check_circle : Icons.edit_outlined, color: AppColors.accent),
                tooltip: _editing ? 'Готово' : 'Изменить',
              ),
            ],
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CodeTile(label: 'Код клиента', value: code.split('-').first)),
                const SizedBox(width: 8),
                Expanded(child: _CodeTile(label: 'Код доставки', value: code)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({required this.label, required this.hint, required this.selected, required this.onTap});
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoftBg : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? AppColors.accent : AppColors.borderLight, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: selected ? AppColors.accent : AppColors.textDim)),
            const SizedBox(height: 3),
            Text(hint, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor, this.last = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderHairline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor ?? AppColors.textSecondary)),
        ],
      ),
    );
  }
}
