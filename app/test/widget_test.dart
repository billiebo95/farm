// Smoke tests covering the main navigation flows: login → catalog → cart
// checkout, and the supplier PIN lock.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apteka_opt/main.dart';

void main() {
  testWidgets('login screen renders and logs in with a delivery code', (tester) async {
    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();

    expect(find.text('Вход для аптеки'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '190455-01');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    // A registered seeded delivery code logs straight into the catalog.
    expect(find.text('Прайс'), findsWidgets);
    expect(find.text('Вход для аптеки'), findsNothing);
  });

  testWidgets('adding a product updates the cart tab badge', (tester) async {
    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '190455-01');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить'), findsWidgets);
    await tester.tap(find.text('Добавить').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Заказ'));
    await tester.pumpAndSettle();
    expect(find.text('Заказ пуст'), findsNothing);
  });

  testWidgets('unregistered code can browse but ordering redirects to registration', (tester) async {
    // The extra registration banner pushes catalog rows further down than
    // the default 600px test surface — use a taller one so "Добавить" for
    // the first row is actually reachable, not just laid out off-screen.
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();

    // A code that doesn't match any registered pharmacy still gets in...
    await tester.enterText(find.byType(TextField).first, '000000-00');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Прайс'), findsWidgets);
    expect(find.textContaining('зарегистрируйте аптеку'), findsWidgets);

    // ...but trying to check out bounces to registration instead of placing
    // an order. The registration banner pushes the list down, so scroll the
    // button into view first.
    await tester.ensureVisible(find.text('Добавить').first);
    await tester.tap(find.text('Добавить').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заказ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Зарегистрировать аптеку'));
    await tester.pumpAndSettle();

    expect(find.text('Данные аптеки'), findsOneWidget);
  });

  testWidgets('wrong supplier PIN shows an error and does not unlock', (tester) async {
    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Вход для поставщика'));
    await tester.pumpAndSettle();
    expect(find.text('Пароль поставщика'), findsOneWidget);

    for (final digit in ['1', '1', '1', '1']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Неверный пароль'), findsOneWidget);
  });
}
