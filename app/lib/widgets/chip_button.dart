import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A pill-shaped toggle button — used for catalog filters, region pickers,
/// admin tabs and the admin region filter. All of those differ only in
/// color/size, so this one widget covers them.
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 33,
    this.selectedBg = AppColors.accent,
    this.selectedFg = Colors.white,
    this.idleBg = Colors.white,
    this.idleFg = AppColors.textDim,
    this.idleBorder = AppColors.borderLight,
    this.flex = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final Color selectedBg;
  final Color selectedFg;
  final Color idleBg;
  final Color idleFg;
  final Color idleBorder;
  final bool flex;

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : idleBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? selectedBg : idleBorder),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: selected ? selectedFg : idleFg),
        ),
      ),
    );
    return flex ? Expanded(child: child) : child;
  }
}

/// Small status/info badge, e.g. stock label, "ЧЗ" marking, DBF status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.fg, required this.bg, this.mono = false, this.fontSize = 10});

  final String label;
  final Color fg;
  final Color bg;
  final bool mono;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        label,
        style: TextStyle(fontFamily: mono ? 'monospace' : null, fontWeight: FontWeight.w700, fontSize: fontSize, color: fg),
      ),
    );
  }
}
