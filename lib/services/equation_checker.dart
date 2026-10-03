class EquationCheck {
  const EquationCheck({
    required this.valid,
    required this.balanced,
    required this.left,
    required this.right,
    this.error,
  });
  final bool valid, balanced;
  final Map<String, int> left, right;
  final String? error;
}

abstract final class EquationChecker {
  static EquationCheck check(String input) {
    try {
      final normalized = input
          .replaceAll('⇌', '→')
          .replaceAll('<=>', '→')
          .replaceAll('=>', '→')
          .replaceAll('->', '→')
          .replaceAll('=', '→')
          .replaceAll(' ', '');
      final sides = normalized.split('→');
      if (sides.length != 2 || sides.any((e) => e.isEmpty)) {
        throw const FormatException('Реакция жебесін дұрыс қойыңыз');
      }
      final left = _side(sides[0]);
      final right = _side(sides[1]);
      if (left.isEmpty || right.isEmpty) {
        throw const FormatException('Формула табылмады');
      }
      final elements = {...left.keys, ...right.keys};
      return EquationCheck(
        valid: true,
        balanced: elements.every((e) => left[e] == right[e]),
        left: left,
        right: right,
      );
    } catch (e) {
      return EquationCheck(
        valid: false,
        balanced: false,
        left: const {},
        right: const {},
        error: e is FormatException
            ? e.message.toString()
            : 'Теңдеу пішімін тексеріңіз',
      );
    }
  }

  static Map<String, int> _side(String source) {
    final result = <String, int>{};
    for (final raw in source.split('+')) {
      if (raw.isEmpty) {
        continue;
      }
      final coefficientMatch = RegExp(r'^([0-9]+)').firstMatch(raw);
      final coefficient = coefficientMatch == null
          ? 1
          : int.parse(coefficientMatch.group(1)!);
      var formula = raw.substring(coefficientMatch?.end ?? 0);
      formula = formula.replaceAll(
        RegExp(r'\((aq|s|l|g)\)$', caseSensitive: false),
        '',
      );
      final counts = _formula(formula);
      for (final entry in counts.entries) {
        result.update(
          entry.key,
          (v) => v + entry.value * coefficient,
          ifAbsent: () => entry.value * coefficient,
        );
      }
    }
    return result;
  }

  static Map<String, int> _formula(String source) {
    final stack = <Map<String, int>>[{}];
    var i = 0;
    while (i < source.length) {
      final char = source[i];
      if (char == '(' || char == '[') {
        stack.add({});
        i++;
        continue;
      }
      if (char == ')' || char == ']') {
        if (stack.length == 1) {
          throw const FormatException('Жақша дұрыс жабылмаған');
        }
        final group = stack.removeLast();
        i++;
        final number = _number(source, i);
        i = number.$2;
        for (final entry in group.entries) {
          stack.last.update(
            entry.key,
            (v) => v + entry.value * number.$1,
            ifAbsent: () => entry.value * number.$1,
          );
        }
        continue;
      }
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        var element = char;
        i++;
        while (i < source.length && RegExp(r'[a-z]').hasMatch(source[i])) {
          element += source[i];
          i++;
        }
        final number = _number(source, i);
        i = number.$2;
        stack.last.update(
          element,
          (v) => v + number.$1,
          ifAbsent: () => number.$1,
        );
        continue;
      }
      if ('₂₃₄₅₆₇₈₉₀'.contains(char)) {
        throw const FormatException(
          'Төменгі индекс орнына кәдімгі сан қолданыңыз (H2O)',
        );
      }
      if (char == '·' || char == '.') {
        i++;
        continue;
      }
      throw FormatException('Түсініксіз таңба: $char');
    }
    if (stack.length != 1) throw const FormatException('Жақша жабылмаған');
    return stack.single;
  }

  static (int, int) _number(String source, int start) {
    var i = start;
    while (i < source.length && RegExp(r'[0-9]').hasMatch(source[i])) {
      i++;
    }
    return (i == start ? 1 : int.parse(source.substring(start, i)), i);
  }
}
