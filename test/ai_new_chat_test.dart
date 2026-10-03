import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/screens/ai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new chat clears the draft immediately', (tester) async {
    final key = GlobalKey<AiScreenState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AiScreen(key: key, onSaved: () {}),
        ),
      ),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
      isNull,
    );
    await tester.tap(find.text('Теңдеуді теңестіру'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'H2 + O2 → H2O',
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
      isNotNull,
    );
    await tester.enterText(find.byType(TextField), 'H2 + O2 → H2O');
    expect(find.text('H2 + O2 → H2O'), findsWidgets);
    key.currentState!.newChat();
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
