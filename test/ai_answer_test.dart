import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/widgets/ai_answer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> render(WidgetTester tester, String text) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AiAnswer(text),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Markdown with all four math delimiters and multiline display', (
    tester,
  ) async {
    await render(tester, r'''### Теңестіру
**Су** молекуласы: $\mathrm{H}_{2}\mathrm{O}$ және \(x^2\).

$$
2\mathrm{H}_{2} + \mathrm{O}_{2}
\rightarrow 2\mathrm{H}_{2}\mathrm{O}
$$

\[\frac{1}{2}\]

- Атомдар саны **тең**.
''');
    expect(find.byType(Math), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('code, escaped dollars and unmatched delimiters stay literal', (
    tester,
  ) async {
    await render(tester, r'''`$x^2$`

```latex
$$x^2$$
```

Бағасы \$5. Аяқталмаған $x.

$$
Жауап жалғасады.
''');
    expect(find.byType(Math), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long and unsupported formulas do not break compact layouts', (
    tester,
  ) async {
    await render(tester, r'''$$a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p=q$$

$\unsupportedcommand{H2O}$
''');
    expect(find.byType(Math), findsNWidgets(2));
    expect(find.text(r'\unsupportedcommand{H2O}'), findsNothing);
    expect(find.text('unsupportedcommandH2O'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
      findsWidgets,
    );
  });

  testWidgets('aligned chemistry calculations display without raw LaTeX', (
    tester,
  ) async {
    await render(tester, r'''$$
\begin{aligned}
M(\mathrm{CaCO_{3}}) &= M(\mathrm{Ca}) + M(\mathrm{C}) + 3M(\mathrm{O}) \\
&= 100.09\ \text{г·моль}^{-1}
\end{aligned}
$$
''');
    expect(find.textContaining(r'\begin'), findsNothing);
    expect(find.byType(Math), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('unrenderable chemistry notation remains readable', () {
    expect(
      readableMath(r'M(\mathrm{CaCO_{3}}) = 100.09\ \text{г·моль}^{-1}'),
      'M(CaCO₃) = 100.09 г·моль⁻¹',
    );
  });
}
