import 'package:chem_balance_ai/services/equation_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EquationChecker', () {
    test('recognizes a balanced equation', () {
      final result = EquationChecker.check('2H2 + O2 -> 2H2O');
      expect(result.valid, isTrue);
      expect(result.balanced, isTrue);
      expect(result.left, {'H': 4, 'O': 2});
    });

    test('recognizes an unbalanced equation', () {
      final result = EquationChecker.check('H2 + O2 -> H2O');
      expect(result.valid, isTrue);
      expect(result.balanced, isFalse);
    });

    test('supports parenthesized groups', () {
      final result = EquationChecker.check('Ca(OH)2 + 2HCl -> CaCl2 + 2H2O');
      expect(result.balanced, isTrue);
    });
  });
}
