import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/models/chemical_element.dart';
import 'package:chem_balance_ai/screens/elements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog contains all 118 elements in atomic-number order', () {
    expect(ChemicalElement.all, hasLength(118));
    for (var i = 0; i < ChemicalElement.all.length; i++) {
      expect(ChemicalElement.all[i].number, i + 1);
    }
    expect(ChemicalElement.all.first.symbol, 'H');
    expect(ChemicalElement.all.last.symbol, 'Og');
    expect(ChemicalElement.all[25].name, 'Темір');
    expect(ChemicalElement.all[25].displayedWeight, '55.845');
    expect(ChemicalElement.all.last.hasStandardAtomicWeight, isFalse);
    expect(ChemicalElement.all.last.displayedWeight, '294');
  });

  testWidgets('element search opens a blurred detail card', (tester) async {
    String? copiedSymbol;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedSymbol = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    for (final (family, asset) in [
      ('Montserrat', 'assets/fonts/Montserrat.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ElementsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('118 элемент көрсетілді'), findsOneWidget);
    await expectLater(
      find.byType(ElementsScreen),
      matchesGoldenFile('previews/elements.png'),
    );
    await tester.enterText(find.byType(TextField), '118');
    await tester.pumpAndSettle();
    expect(find.text('1 элемент көрсетілді'), findsOneWidget);
    await tester.tap(find.byType(ElementTile));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Изотоптың массалық саны'), findsOneWidget);
    expect(find.text('294'), findsOneWidget);
    expect(find.text('Таңбаны көшіру'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/element_detail.png'),
    );
    await tester.tap(find.text('Таңбаны көшіру'));
    await tester.pump();
    expect(copiedSymbol, 'Og');
    expect(tester.takeException(), isNull);
  });
}
