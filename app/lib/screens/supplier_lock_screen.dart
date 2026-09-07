import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// 4-digit PIN pad guarding the supplier/admin panel.
class SupplierLockScreen extends StatelessWidget {
  const SupplierLockScreen({super.key});

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: AppColors.adminBg,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 4, 20, 26),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: app.goCatalog,
              style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.6)),
              child: const Text('Закрыть', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('АДМИНИСТРИРОВАНИЕ', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.adminAccent, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                const Text('Пароль поставщика', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white)),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (i) {
                    final filled = i < app.pin.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.5),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: filled ? AppColors.adminAccent : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 20,
                  child: Text(
                    app.pinMsg.isNotEmpty ? app.pinMsg : (app.pin.isNotEmpty ? 'введено ${app.pin.length} из 4' : ''),
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: app.pinMsg.isNotEmpty ? AppColors.adminPinMsg : Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 72 * 3 + 12 * 2,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 72 / 60,
                    children: [
                      for (final k in _keys)
                        InkWell(
                          onTap: () => app.pressPinKey(k),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.center,
                            child: Text(k, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
