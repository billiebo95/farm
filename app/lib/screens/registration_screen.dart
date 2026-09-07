import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/labeled_field.dart';
import '../widgets/primary_button.dart';

/// 3-step pharmacy registration: license details → delivery address →
/// pending-review confirmation.
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProgressSegment(active: true),
              const SizedBox(width: 6),
              _ProgressSegment(active: app.regStep >= 1),
              const SizedBox(width: 6),
              _ProgressSegment(active: app.regStep >= 2),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: switch (app.regStep) {
              0 => _StepLicense(app: app),
              1 => _StepAddress(app: app),
              _ => _StepPending(app: app),
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.borderCard,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _StepLicense extends StatelessWidget {
  const _StepLicense({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Данные аптеки', style: AppText.h2),
        const SizedBox(height: 6),
        const Text('Как в лицензии — эти данные уйдут в накладную.', style: AppText.body),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(label: 'Название', value: app.regName, onChanged: (v) => app.setRegField(name: v)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Телефон',
                        value: app.regPhone,
                        onChanged: (v) => app.setRegField(phone: v),
                        mono: true,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabeledField(
                        label: 'ИНН',
                        value: app.regInn,
                        onChanged: (v) => app.setRegField(inn: v),
                        mono: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Регион', style: AppText.label),
                const SizedBox(height: 6),
                Row(
                  children: MockData.regions
                      .map((r) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: r == MockData.regions.first ? 7 : 0),
                              child: _RegionButton(label: r, selected: app.region == r, onTap: () => app.pickRegion(r)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Лицензия (фото или PDF)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.textMuted)),
                      Text('Прикрепить', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Далее — адрес', onPressed: app.regNext),
      ],
    );
  }
}

class _RegionButton extends StatelessWidget {
  const _RegionButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoftBg : AppColors.inputBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? AppColors.accent : AppColors.borderLight, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: selected ? AppColors.accent : AppColors.textDim)),
      ),
    );
  }
}

class _StepAddress extends StatelessWidget {
  const _StepAddress({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Адрес аптеки', style: AppText.h2),
        const SizedBox(height: 6),
        const Text('Точка на карте нужна для маршрута машины.', style: AppText.body),
        const SizedBox(height: 14),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            color: const Color(0xFFEDF1EF),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 3))],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
                  child: const Text('карта · перетащите точку', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(label: 'Адрес доставки', value: app.regAddr, onChanged: (v) => app.setRegField(addr: v)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(13)),
          child: const Text('Приёмка 9:00–18:00 · водитель позвонит за 30 минут', style: AppText.bodyDark),
        ),
        const Spacer(),
        PrimaryButton(label: 'Отправить на проверку', onPressed: app.regNext),
      ],
    );
  }
}

class _StepPending extends StatelessWidget {
  const _StepPending({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(color: AppColors.accentSoftBg, shape: BoxShape.circle),
          child: const Center(child: AppIcon.check(color: AppColors.accent, size: 36)),
        ),
        const SizedBox(height: 20),
        const Text('Аптека на проверке', style: AppText.h2, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const SizedBox(
          width: 300,
          child: Text(
            'Менеджер сверит лицензию и присвоит код клиента и код доставки — они появятся в кабинете.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Перейти в прайс', onPressed: app.finishRegistration, fullWidth: false, height: 54),
      ],
    );
  }
}
