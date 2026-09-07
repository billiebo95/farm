import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Dark floating snackbar-style toast, anchored above the bottom nav —
/// mirrors the `{{ toast }}` overlay in the prototype.
class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final toast = context.watch<AppState>().toast;
    return Positioned(
      left: 14,
      right: 14,
      bottom: 100,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: toast == null
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(toast),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.adminBg,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 30, offset: Offset(0, 10))],
                  ),
                  child: Text(
                    toast,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                  ),
                ),
        ),
      ),
    );
  }
}
