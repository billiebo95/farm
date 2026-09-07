import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_data.dart';
import 'screens/cart_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/supplier_admin_screen.dart';
import 'screens/supplier_lock_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/product_detail_sheet.dart';
import 'widgets/toast_overlay.dart';

const _kTabScreens = {AppScreen.catalog, AppScreen.cart, AppScreen.orders, AppScreen.profile};

/// Top-level frame: swaps in the current screen, plus the overlays that
/// float above it (order detail, product sheet, toast) and the bottom tab
/// bar — mirrors the single-canvas structure of the prototype, minus its
/// device-frame chrome (a real device already supplies that).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final showTabs = _kTabScreens.contains(app.screen) && app.openOrder == null;

    return PopScope(
      canPop: _canPop(app),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(app);
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _screenFor(app.screen)),
                if (showTabs) const AppBottomNav(),
              ],
            ),
            if (app.openOrder != null) Positioned.fill(child: OrderDetailScreen(order: app.openOrder!)),
            if (app.sheetId != null) _ProductSheetOverlay(productId: app.sheetId!),
            const ToastOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(AppScreen screen) => switch (screen) {
        AppScreen.login => const LoginScreen(),
        AppScreen.registration => const RegistrationScreen(),
        AppScreen.catalog => const CatalogScreen(),
        AppScreen.cart => const CartScreen(),
        AppScreen.orders => const OrdersScreen(),
        AppScreen.profile => const ProfileScreen(),
        AppScreen.supplierLock => const SupplierLockScreen(),
        AppScreen.supplierAdmin => const SupplierAdminScreen(),
      };

  bool _canPop(AppState app) {
    if (app.sheetId != null || app.openOrder != null) return false;
    switch (app.screen) {
      case AppScreen.login:
      case AppScreen.catalog:
        return true;
      default:
        return false;
    }
  }

  void _handleBack(AppState app) {
    if (app.sheetId != null) return app.closeProductSheet();
    if (app.openOrder != null) return app.closeOrderDetail();
    switch (app.screen) {
      case AppScreen.supplierAdmin:
        app.exitSupplier();
      case AppScreen.supplierLock:
        app.goCatalog();
      case AppScreen.registration:
        app.regBack();
      case AppScreen.cart:
      case AppScreen.orders:
      case AppScreen.profile:
        app.goCatalog();
      case AppScreen.login:
      case AppScreen.catalog:
        break;
    }
  }
}

class _ProductSheetOverlay extends StatelessWidget {
  const _ProductSheetOverlay({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final product = MockData.findProduct(productId);
    if (product == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: app.closeProductSheet,
            child: Container(color: const Color(0x6B0A100E)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, -12))],
                ),
                child: SingleChildScrollView(child: ProductDetailSheet(product: product)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
