import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// The 4-tab bottom bar: Прайс / Заказ (with a count badge) / Заказы / Кабинет.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      padding: EdgeInsets.only(top: 7, bottom: 7 + MediaQuery.of(context).padding.bottom, left: 8, right: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderCard)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: (c) => AppIcon.grid(color: c),
            label: 'Прайс',
            active: app.screen == AppScreen.catalog,
            onTap: app.goCatalog,
          ),
          _NavItem(
            icon: (c) => AppIcon.cart(color: c),
            label: 'Заказ',
            active: app.screen == AppScreen.cart,
            badge: app.cartHasItems ? app.cart.length : null,
            onTap: app.goCart,
          ),
          _NavItem(
            icon: (c) => AppIcon.orders(color: c),
            label: 'Заказы',
            active: app.screen == AppScreen.orders,
            onTap: app.goOrders,
          ),
          _NavItem(
            icon: (c) => AppIcon.person(color: c),
            label: 'Кабинет',
            active: app.screen == AppScreen.profile,
            onTap: app.goProfile,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap, this.badge});

  final Widget Function(Color) icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.idleIcon;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon(color),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: color)),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 1,
                  right: 24,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.warnFg, borderRadius: BorderRadius.circular(10)),
                    child: Text('$badge', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
