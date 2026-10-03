class LessonQuestion {
  const LessonQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class LessonMatch {
  const LessonMatch(this.left, this.right);
  final String left;
  final String right;
}

class LessonWorkedExample {
  const LessonWorkedExample({required this.question, required this.answer});
  final String question;
  final String answer;
}

class ChemistryLesson {
  const ChemistryLesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.concepts,
    required this.exampleTitle,
    required this.example,
    required this.questions,
    required this.matches,
    this.grade = 7,
    this.practice = false,
    this.workedExamples = const [],
  });

  final String id;
  final String title;
  final String summary;
  final List<String> concepts;
  final String exampleTitle;
  final String example;
  final List<LessonQuestion> questions;
  final List<LessonMatch> matches;
  final int grade;
  final bool practice;
  final List<LessonWorkedExample> workedExamples;

  ChemistryLesson copyWith({
    int? grade,
    bool? practice,
    List<String>? concepts,
    List<LessonQuestion>? questions,
    List<LessonWorkedExample>? workedExamples,
  }) => ChemistryLesson(
    id: id,
    title: title,
    summary: summary,
    concepts: concepts ?? this.concepts,
    exampleTitle: exampleTitle,
    example: example,
    questions: questions ?? this.questions,
    matches: matches,
    grade: grade ?? this.grade,
    practice: practice ?? this.practice,
    workedExamples: workedExamples ?? this.workedExamples,
  );
}

abstract final class LessonCatalog {
  static const lessons = <ChemistryLesson>[
    ChemistryLesson(
      id: 'atoms_molecules',
      title: 'Атом және молекула',
      summary: 'Зат неден тұратынын қарапайым мысалмен түсінеміз.',
      concepts: [
        'Атом — химиялық элементтің өте ұсақ бөлшегі. H — сутек, O — оттек атомының таңбасы.',
        'Молекула екі немесе одан көп атомнан құралуы мүмкін. Мысалы, O₂ — екі оттек атомынан тұратын молекула.',
      ],
      exampleTitle: 'Кішкентай мысал',
      example:
          'H₂O молекуласында 2 сутек және 1 оттек атомы бар. Барлығы — 3 атом.',
      questions: [
        LessonQuestion(
          text: 'H₂O молекуласында барлығы неше атом бар?',
          options: ['2', '3', '4'],
          correctIndex: 1,
          explanation: '2 сутек + 1 оттек = 3 атом.',
        ),
        LessonQuestion(
          text: 'O₂ нені көрсетеді?',
          options: [
            'Екі оттек атомын',
            'Екі сутек атомын',
            'Бір су молекуласын',
          ],
          correctIndex: 0,
          explanation:
              'O — оттек, ал төменгі ₂ оның екі атомы барын көрсетеді.',
        ),
      ],
      matches: [
        LessonMatch('H', 'Сутек'),
        LessonMatch('O', 'Оттек'),
        LessonMatch('C', 'Көміртек'),
      ],
    ),
    ChemistryLesson(
      id: 'chemical_formulas',
      title: 'Химиялық формула',
      summary: 'Таңбалар мен төменгі индекстерді оқуды үйренеміз.',
      concepts: [
        'Формула заттың құрамындағы элементтерді көрсетеді. Әріп — элементтің таңбасы.',
        'Таңбадан кейінгі төменгі сан сол элемент атомдарының санын көрсетеді. Сан жазылмаса, ол 1 деп есептеледі.',
      ],
      exampleTitle: 'Формуланы оқиық',
      example: 'CO₂ формуласында 1 көміртек және 2 оттек атомы бар.',
      questions: [
        LessonQuestion(
          text: 'CO₂ құрамында неше оттек атомы бар?',
          options: ['1', '2', '3'],
          correctIndex: 1,
          explanation: 'O таңбасынан кейінгі ₂ — екі оттек атомы.',
        ),
        LessonQuestion(
          text: 'NaCl формуласында неше Na атомы бар?',
          options: ['1', '2', '0'],
          correctIndex: 0,
          explanation: 'Na таңбасынан кейін сан жоқ, демек бір атом.',
        ),
      ],
      matches: [
        LessonMatch('H₂O', 'Су'),
        LessonMatch('CO₂', 'Көмірқышқыл газы'),
        LessonMatch('NaCl', 'Ас тұзы'),
      ],
    ),
    ChemistryLesson(
      id: 'count_atoms',
      title: 'Атомдарды санау',
      summary: 'Индекс пен коэффициенттің айырмасын есеппен көреміз.',
      concepts: [
        'Төменгі индекс тек өз алдындағы элементке әсер етеді: H₂O құрамында H — 2, O — 1.',
        'Формула алдындағы коэффициент бүкіл молекула санын көбейтеді: 2H₂O құрамында H — 4, O — 2.',
      ],
      exampleTitle: 'Бірге есептейік',
      example:
          '2H₂O: екі су молекуласы × әрқайсысында 2 H және 1 O = 4 H, 2 O.',
      questions: [
        LessonQuestion(
          text: '2H₂O құрамында барлығы неше H атомы бар?',
          options: ['2', '4', '6'],
          correctIndex: 1,
          explanation: '2 молекула × әр молекуладағы 2 H = 4 H атомы.',
        ),
        LessonQuestion(
          text: '3O₂ құрамында неше O атомы бар?',
          options: ['3', '5', '6'],
          correctIndex: 2,
          explanation: '3 молекула × 2 оттек атомы = 6 атом.',
        ),
      ],
      matches: [
        LessonMatch('H₂O', '2 H, 1 O'),
        LessonMatch('2H₂O', '4 H, 2 O'),
        LessonMatch('3O₂', '6 O'),
      ],
    ),
    ChemistryLesson(
      id: 'balance_equations',
      title: 'Теңдеуді теңестіру',
      summary: 'Екі жақтағы атом санын тең етуді үйренеміз.',
      concepts: [
        'Реакция теңдеуінде жебенің сол жағында бастапқы заттар, оң жағында түзілген заттар жазылады.',
        'Теңестіру кезінде формула ішіндегі төменгі индексті өзгертпейміз. Тек формула алдындағы коэффициенттерді қоямыз.',
      ],
      exampleTitle: 'Судың түзілуі',
      example:
          '2H₂ + O₂ → 2H₂O. Сол жақта да, оң жақта да 4 H және 2 O атомы бар.',
      questions: [
        LessonQuestion(
          text: 'Теңестіруде қай санды өзгертуге болады?',
          options: ['Төменгі индексті', 'Коэффициентті', 'Элемент таңбасын'],
          correctIndex: 1,
          explanation:
              'Формуланы сақтап, оның алдындағы коэффициентті өзгертеміз.',
        ),
        LessonQuestion(
          text: '2H₂ + O₂ → 2H₂O теңдеуінде O атомдары тең бе?',
          options: ['Иә, 2 және 2', 'Жоқ, 1 және 2', 'Жоқ, 2 және 4'],
          correctIndex: 0,
          explanation: 'O₂-де 2 O бар, ал 2H₂O-да 2 × 1 = 2 O бар.',
        ),
      ],
      matches: [
        LessonMatch('H₂ + O₂', 'Бастапқы заттар'),
        LessonMatch('H₂O', 'Түзілген зат'),
        LessonMatch('2H₂O', 'Коэффициенті 2'),
      ],
    ),
    ChemistryLesson(
      id: 'reaction_types',
      title: 'Реакция түрлері',
      summary: 'Қосылу, айырылу және орынбасу реакцияларын ажыратамыз.',
      concepts: [
        'Қосылуда бірнеше заттан бір өнім түзіледі: A + B → AB.',
        'Айырылуда бір зат бірнеше өнімге бөлінеді: AB → A + B. Орынбасуда элемент қосылыстағы басқа элементтің орнын басады.',
      ],
      exampleTitle: 'Мысалмен көрейік',
      example: '2Mg + O₂ → 2MgO — қосылу; CaCO₃ → CaO + CO₂ — айырылу.',
      questions: [
        LessonQuestion(
          text: 'A + B → AB қай реакцияға жатады?',
          options: ['Қосылу', 'Айырылу', 'Орынбасу'],
          correctIndex: 0,
          explanation: 'Екі бастапқы заттан бір өнім пайда болды.',
        ),
        LessonQuestion(
          text: 'CaCO₃ → CaO + CO₂ реакциясы қандай?',
          options: ['Қосылу', 'Айырылу', 'Бейтараптану'],
          correctIndex: 1,
          explanation: 'Бір зат екі өнімге бөлінді.',
        ),
      ],
      matches: [
        LessonMatch('A + B → AB', 'Қосылу'),
        LessonMatch('AB → A + B', 'Айырылу'),
        LessonMatch('A + BC → AC + B', 'Орынбасу'),
      ],
    ),
    ChemistryLesson(
      id: 'combustion',
      title: 'Жану реакциясы',
      summary: 'Оттек қатысатын жануды қарапайым теңдеумен танимыз.',
      concepts: [
        'Жану — заттың оттекпен әрекеттесуі. Көбіне жылу мен жарық бөлінеді.',
        'Көміртек оттекте жанғанда көмірқышқыл газы түзіледі: C + O₂ → CO₂.',
      ],
      exampleTitle: 'Көміртектің жануы',
      example:
          'C + O₂ → CO₂: 1 көміртек пен 2 оттек атомы екі жақта да сақталады.',
      questions: [
        LessonQuestion(
          text: 'Жану кезінде қандай газ қатысады?',
          options: ['Азот', 'Оттек', 'Сутек'],
          correctIndex: 1,
          explanation: 'Жану реакциясына оттек қатысады.',
        ),
        LessonQuestion(
          text: 'C + O₂ → ? теңдеуіндегі өнім қандай?',
          options: ['CO₂', 'H₂O', 'O₃'],
          correctIndex: 0,
          explanation: 'Көміртек жанғанда CO₂ түзіледі.',
        ),
      ],
      matches: [
        LessonMatch('C', 'Көміртек'),
        LessonMatch('O₂', 'Оттек'),
        LessonMatch('CO₂', 'Көмірқышқыл газы'),
      ],
    ),
    ChemistryLesson(
      id: 'acids_bases',
      title: 'Қышқылдар мен сілтілер',
      summary: 'Қышқыл, сілті және бейтараптануды түсінеміз.',
      concepts: [
        'HCl — тұз қышқылы, ал NaOH — натрий гидроксиді (сілті).',
        'Бұл қышқыл мен сілті әрекеттескенде тұз және су түзіледі. Мұны бейтараптану деп атайды.',
      ],
      exampleTitle: 'Бейтараптану мысалы',
      example:
          'HCl + NaOH → NaCl + H₂O: тұз қышқылы + натрий гидроксиді → ас тұзы + су.',
      questions: [
        LessonQuestion(
          text: 'HCl қандай зат?',
          options: ['Қышқыл', 'Сілті', 'Тұз'],
          correctIndex: 0,
          explanation: 'HCl — тұз қышқылы.',
        ),
        LessonQuestion(
          text: 'HCl мен NaOH әрекеттескенде не түзіледі?',
          options: ['Тұз және су', 'Тек оттек', 'Тек сутек'],
          correctIndex: 0,
          explanation: 'NaCl тұзы мен H₂O суы пайда болады.',
        ),
      ],
      matches: [
        LessonMatch('HCl', 'Қышқыл'),
        LessonMatch('NaOH', 'Сілті'),
        LessonMatch('NaCl', 'Тұз'),
      ],
    ),
    ChemistryLesson(
      id: 'mass_conservation',
      title: 'Массаның сақталуы',
      summary: 'Реакцияға дейінгі және кейінгі массаны салыстырамыз.',
      concepts: [
        'Жабық жүйеде реакцияға түскен заттардың жалпы массасы өнімдердің жалпы массасына тең.',
        'Атомдар жоғалмайды және пайда болмайды, тек басқа ретпен байланысады. Сондықтан теңдеу екі жақтан теңестіріледі.',
      ],
      exampleTitle: 'Массаны есептейік',
      example: '12 г C + 32 г O₂ → 44 г CO₂. Екі жақтың да жалпы массасы 44 г.',
      questions: [
        LessonQuestion(
          text:
              '12 г зат пен 32 г зат толық әрекеттессе, өнімнің жалпы массасы қандай?',
          options: ['20 г', '44 г', '32 г'],
          correctIndex: 1,
          explanation: 'Жабық жүйеде 12 + 32 = 44 г сақталады.',
        ),
        LessonQuestion(
          text: 'Реакция кезінде атомдарға не болады?',
          options: ['Жоғалады', 'Саны сақталады', 'Өздігінен көбейеді'],
          correctIndex: 1,
          explanation: 'Атомдар қайта байланысады, бірақ саны сақталады.',
        ),
      ],
      matches: [
        LessonMatch('Бастапқы заттар', 'Реакцияға дейін'),
        LessonMatch('Өнімдер', 'Реакциядан кейін'),
        LessonMatch('Жалпы масса', 'Екі жақта тең'),
      ],
    ),
    ChemistryLesson(
      id: 'molar_mass',
      title: 'Молярлық масса',
      summary: 'Формула бойынша заттың молярлық массасын табамыз.',
      concepts: [
        'Молярлық масса — бір моль заттың массасы. Өлшем бірлігі г/моль.',
        'Формуладағы атомдардың жуық молярлық массаларын қосамыз: H = 1, C = 12, O = 16 г/моль.',
      ],
      exampleTitle: 'Судың молярлық массасы',
      example: 'M(H₂O) = 2 × 1 + 16 = 18 г/моль.',
      questions: [
        LessonQuestion(
          text: 'H₂O молярлық массасы қандай?',
          options: ['16 г/моль', '18 г/моль', '20 г/моль'],
          correctIndex: 1,
          explanation: 'Екі H және бір O: 2 × 1 + 16 = 18 г/моль.',
        ),
        LessonQuestion(
          text: 'CO₂ молярлық массасы қандай?',
          options: ['28 г/моль', '32 г/моль', '44 г/моль'],
          correctIndex: 2,
          explanation: '12 + 2 × 16 = 44 г/моль.',
        ),
      ],
      matches: [
        LessonMatch('H₂O', '18 г/моль'),
        LessonMatch('O₂', '32 г/моль'),
        LessonMatch('CO₂', '44 г/моль'),
      ],
    ),
    ChemistryLesson(
      id: 'moles',
      title: 'Зат мөлшері — моль',
      summary: 'Мольді молярлық массамен байланыстырамыз.',
      concepts: [
        'Моль — зат мөлшерінің бірлігі. 1 мольде шамамен 6,02 × 10²³ бөлшек болады.',
        'Массаны табу үшін зат мөлшерін молярлық массаға көбейтеміз: m = n × M.',
      ],
      exampleTitle: 'Екі моль су',
      example: 'M(H₂O) = 18 г/моль. 2 моль судың массасы: 2 × 18 = 36 г.',
      questions: [
        LessonQuestion(
          text: '2 моль судың массасы неше грамм?',
          options: ['18 г', '36 г', '20 г'],
          correctIndex: 1,
          explanation: 'm = n × M = 2 × 18 = 36 г.',
        ),
        LessonQuestion(
          text: 'Моль қандай шаманы өлшейді?',
          options: ['Зат мөлшерін', 'Температураны', 'Көлемді'],
          correctIndex: 0,
          explanation: 'Моль — зат мөлшерінің бірлігі.',
        ),
      ],
      matches: [
        LessonMatch('n', 'Зат мөлшері'),
        LessonMatch('M', 'Молярлық масса'),
        LessonMatch('m', 'Масса'),
      ],
    ),
  ];
}
