import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The solid accent-green CTA button used throughout the app
/// ("Войти", "Далее — адрес", "Отправить заказ", …).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
    this.enabled = true,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool enabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.disabledBg,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: AppText.button, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Ghost / outline variant ("Повторить заказ", "Обновить прайс…").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
    this.borderColor = AppColors.accent,
    this.textColor = AppColors.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
      ),
    );
  }
}

/// Plain text button ("Моей аптеки ещё нет — зарегистрировать").
class TextOnlyButton extends StatelessWidget {
  const TextOnlyButton({super.key, required this.label, required this.onPressed, this.color = AppColors.accent, this.fontSize = 15});

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color, padding: EdgeInsets.zero),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize, color: color)),
    );
  }
}
