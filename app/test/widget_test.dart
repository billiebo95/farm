// Smoke tests covering the main navigation flows: login → catalog → cart
// checkout, and the supplier PIN lock.

import 'package:flutter_test/flutter_test.dart';

import 'package:apteka_opt/main.dart';

void main() {
  testWidgets('login screen renders and logs in with a delivery code', (tester) async {
    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();

    expect(find.text('Вход для аптеки'), findsOneWidget);

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    // A valid seeded delivery code logs straight into the catalog.
    expect(find.text('Прайс'), findsWidgets);
    expect(find.text('Вход для аптеки'), findsNothing);
  });

  testWidgets('adding a product updates the cart tab badge', (tester) async {
    await tester.pumpWidget(const AptekaOptApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить'), findsWidgets);
    await tester.tap(find.text('Добавить').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Заказ'));
    await tester.pumpAndSettle();
    expect(find.text('Заказ пуст'), findsNothing);
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
