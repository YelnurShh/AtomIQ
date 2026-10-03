import '../services/equation_checker.dart';

/// One missing coefficient per exercise keeps the first practice experience
/// focused. The complete equation is still checked independently for balance.
class PracticeTask {
  const PracticeTask({
    required this.id,
    required this.title,
    required this.reagents,
    required this.products,
    required this.coefficients,
    required this.blankIndex,
    required this.focusElement,
    required this.hint,
    required this.explanation,
  });

  final String id;
  final String title;
  final List<String> reagents;
  final List<String> products;
  final List<int> coefficients;
  final int blankIndex;
  final String focusElement;
  final String hint;
  final String explanation;

  int get answer => coefficients[blankIndex];
  List<int> get options => const [1, 2, 3];

  EquationCheck check(int choice) {
    final values = [...coefficients]..[blankIndex] = choice;
    String side(List<String> formulas, int offset) => [
      for (var i = 0; i < formulas.length; i++)
        '${values[offset + i]}${formulas[i]}',
    ].join(' + ');
    return EquationChecker.check(
      '${side(reagents, 0)} → ${side(products, reagents.length)}',
    );
  }

  bool isCorrect(int choice) => choice == answer && check(choice).balanced;
}

abstract final class PracticeCatalog {
  static const tasks = <PracticeTask>[
    PracticeTask(
      id: 'water',
      title: 'Судың түзілуі',
      reagents: ['H2', 'O2'],
      products: ['H2O'],
      coefficients: [2, 1, 2],
      blankIndex: 2,
      focusElement: 'H',
      hint: 'Сол жақта 4 сутек атомы бар. Оң жаққа қанша су молекуласы керек?',
      explanation:
          '2H₂O құрамында 4 сутек атомы бар. Екі жақта да сутек саны 4 болады.',
    ),
    PracticeTask(
      id: 'magnesium',
      title: 'Магний оксиді',
      reagents: ['Mg', 'O2'],
      products: ['MgO'],
      coefficients: [2, 1, 2],
      blankIndex: 0,
      focusElement: 'Mg',
      hint: 'Оң жақта 2 магний атомы бар. Сол жаққа қанша магний керек?',
      explanation:
          '2MgO құрамында 2 магний атомы бар. Сондықтан сол жаққа 2Mg қажет.',
    ),
    PracticeTask(
      id: 'salt',
      title: 'Ас тұзының түзілуі',
      reagents: ['Na', 'Cl2'],
      products: ['NaCl'],
      coefficients: [2, 1, 2],
      blankIndex: 2,
      focusElement: 'Cl',
      hint: 'Сол жақтағы Cl₂ құрамында 2 хлор атомы бар.',
      explanation:
          '2NaCl құрамында 2 хлор атомы бар. Ол сол жақтағы Cl₂-мен тең.',
    ),
    PracticeTask(
      id: 'ammonia',
      title: 'Аммиактың түзілуі',
      reagents: ['N2', 'H2'],
      products: ['NH3'],
      coefficients: [1, 3, 2],
      blankIndex: 2,
      focusElement: 'N',
      hint: 'Сол жақта N₂, яғни 2 азот атомы бар.',
      explanation:
          '2NH₃ құрамында 2 азот атомы бар. Сутек те екі жақта 6-дан болады.',
    ),
    PracticeTask(
      id: 'iron_oxide',
      title: 'Темір оксиді',
      reagents: ['Fe', 'O2'],
      products: ['Fe2O3'],
      coefficients: [4, 3, 2],
      blankIndex: 1,
      focusElement: 'O',
      hint: 'Оң жақтағы 2Fe₂O₃ құрамында 6 оттек атомы бар.',
      explanation:
          '3O₂ құрамында 6 оттек атомы бар. Сондықтан бос орынға 3 қойылады.',
    ),
    PracticeTask(
      id: 'potassium_chlorate',
      title: 'Оттекті алу',
      reagents: ['KClO3'],
      products: ['KCl', 'O2'],
      coefficients: [2, 2, 3],
      blankIndex: 2,
      focusElement: 'O',
      hint: 'Сол жақтағы 2KClO₃ құрамында 6 оттек атомы бар.',
      explanation:
          '3O₂ құрамында 6 оттек атомы бар. Екі жақтағы оттек саны тең.',
    ),
  ];
}
