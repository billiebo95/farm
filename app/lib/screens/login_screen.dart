import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_field.dart';
import '../widgets/primary_button.dart';

/// Delivery-code sign-in — the app's entry screen.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 26),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ООО «Шах»',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                const Text('Вход для аптеки', style: AppText.title),
                const SizedBox(height: 8),
                const Text(
                  'Код доставки есть в накладной. По нему подтянутся аптека, ваша скидка и история заказов.',
                  style: AppText.body,
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Код доставки',
                  value: app.loginCode,
                  onChanged: app.setLoginCode,
                  height: 56,
                  mono: true,
                  hint: 'напр. 190172-04',
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Войти', onPressed: app.doLogin),
                const SizedBox(height: 8),
                TextOnlyButton(label: 'Моей аптеки ещё нет — зарегистрировать', onPressed: app.jumpToRegistration),
              ],
            ),
          ),
          TextOnlyButton(label: 'Вход для поставщика', onPressed: app.openSupplierLock, color: AppColors.textTertiary, fontSize: 14),
        ],
      ),
    );
  }
}
