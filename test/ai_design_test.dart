import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/screens/ai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI answer stays readable on a compact phone', (tester) async {
    for (final (family, asset) in [
      ('Montserrat', 'assets/fonts/Montserrat.ttf'),
      ('JBMono', 'assets/fonts/JetBrainsMono-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var responderCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('AI көмекші')),
          body: AiScreen(
            onSaved: () {},
            responder: (prompt, history) async {
              responderCalled = true;
              return '**Судың түзілуі**\n\nСутек пен оттек әрекеттескенде су түзіледі.\n\n'
                  '**2H₂ + O₂ → 2H₂O**';
            },
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/app_icon.png'),
        tester.element(find.byType(AiScreen)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Су қалай түзіледі?');
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();
    expect(responderCalled, isTrue);
    expect(find.text('Көшіру'), findsOneWidget);
    expect(find.text('Су қалай түзіледі?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AiScreen),
      matchesGoldenFile('previews/ai_answer.png'),
    );
  });
}
