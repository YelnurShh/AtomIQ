class ChemicalElement {
  const ChemicalElement(
    this.number,
    this.symbol,
    this.name,
    this.englishName,
    this.atomicWeight,
  );

  final int number;
  final String symbol;
  final String name;
  final String englishName;
  final String atomicWeight;

  int get period {
    if (number <= 2) return 1;
    if (number <= 10) return 2;
    if (number <= 18) return 3;
    if (number <= 36) return 4;
    if (number <= 54) return 5;
    if (number <= 86) return 6;
    return 7;
  }

  int? get group {
    if (number == 1) return 1;
    if (number == 2) return 18;
    if (number <= 18) {
      final offset = number <= 10 ? number - 3 : number - 11;
      return offset < 2 ? offset + 1 : offset + 11;
    }
    if (number <= 54) return (number - (number <= 36 ? 19 : 37)) + 1;
    if (number == 55 || number == 87) return 1;
    if (number == 56 || number == 88) return 2;
    if ((number >= 57 && number <= 71) || (number >= 89 && number <= 103)) {
      return null;
    }
    return number <= 86 ? number - 68 : number - 100;
  }

  String get family {
    if (number >= 104) return 'Жасанды аса ауыр элемент';
    if (number >= 89 && number <= 103) return 'Актиноид';
    if (number >= 57 && number <= 71) return 'Лантаноид';
    if (const [2, 10, 18, 36, 54, 86].contains(number)) return 'Инертті газ';
    if (const [9, 17, 35, 53, 85].contains(number)) return 'Галоген';
    if (const [3, 11, 19, 37, 55, 87].contains(number)) {
      return 'Сілтілік металл';
    }
    if (const [4, 12, 20, 38, 56, 88].contains(number)) {
      return 'Сілтілік жер металы';
    }
    if (const [1, 6, 7, 8, 15, 16, 34].contains(number)) return 'Бейметалл';
    if (const [5, 14, 32, 33, 51, 52].contains(number)) {
      return 'Жартылай металл';
    }
    if ((number >= 21 && number <= 30) ||
        (number >= 39 && number <= 48) ||
        (number >= 72 && number <= 80)) {
      return 'Ауыспалы металл';
    }
    return 'Металл';
  }

  bool get hasStandardAtomicWeight => !atomicWeight.startsWith('[');
  String get displayedWeight => hasStandardAtomicWeight
      ? atomicWeight
      : atomicWeight.substring(1, atomicWeight.length - 1);

  String get stateAtRoomTemperature {
    if (number >= 104) return 'Белгісіз';
    if (number == 35 || number == 80) return 'Сұйық';
    if (const [1, 2, 7, 8, 9, 10, 17, 18, 36, 54, 86].contains(number)) {
      return 'Газ';
    }
    return 'Қатты';
  }

  String get fact =>
      _facts[number] ??
      switch (family) {
        'Инертті газ' =>
          'Инертті газдар әдетте басқа элементтермен баяу әрекеттеседі.',
        'Галоген' => 'Галогендер көбіне металдармен тұз түзеді.',
        'Сілтілік металл' => 'Сілтілік металдар сумен белсенді әрекеттеседі.',
        'Сілтілік жер металы' =>
          'Бұл топтың элементтері қосылыстарында көбіне +2 зарядқа ие.',
        'Жартылай металл' =>
          'Жартылай металдар металл мен бейметалл қасиеттерін қатар көрсетеді.',
        'Ауыспалы металл' =>
          'Ауыспалы металдар әртүрлі тотығу дәрежесін көрсете алады.',
        'Лантаноид' => 'Лантаноидтар периодтық кестенің f-блогына жатады.',
        'Актиноид' => 'Актиноидтардың барлығы радиоактивті.',
        'Жасанды аса ауыр элемент' =>
          'Бұл аса ауыр элемент зертханада алынады; қасиеттері толық зерттелмеген.',
        _ => 'Элементтің атом нөмірі оның протон санына тең.',
      };

  static const all = <ChemicalElement>[
    ChemicalElement(1, 'H', 'Сутек', 'Hydrogen', '1.0080'),
    ChemicalElement(2, 'He', 'Гелий', 'Helium', '4.002602'),
    ChemicalElement(3, 'Li', 'Литий', 'Lithium', '6.94'),
    ChemicalElement(4, 'Be', 'Бериллий', 'Beryllium', '9.0121831'),
    ChemicalElement(5, 'B', 'Бор', 'Boron', '10.81'),
    ChemicalElement(6, 'C', 'Көміртек', 'Carbon', '12.011'),
    ChemicalElement(7, 'N', 'Азот', 'Nitrogen', '14.007'),
    ChemicalElement(8, 'O', 'Оттек', 'Oxygen', '15.999'),
    ChemicalElement(9, 'F', 'Фтор', 'Fluorine', '18.998403162'),
    ChemicalElement(10, 'Ne', 'Неон', 'Neon', '20.1797'),
    ChemicalElement(11, 'Na', 'Натрий', 'Sodium', '22.98976928'),
    ChemicalElement(12, 'Mg', 'Магний', 'Magnesium', '24.305'),
    ChemicalElement(13, 'Al', 'Алюминий', 'Aluminium', '26.9815384'),
    ChemicalElement(14, 'Si', 'Кремний', 'Silicon', '28.085'),
    ChemicalElement(15, 'P', 'Фосфор', 'Phosphorus', ''),
    ChemicalElement(16, 'S', 'Күкірт', 'Sulfur', '32.06'),
    ChemicalElement(17, 'Cl', 'Хлор', 'Chlorine', '35.45'),
    ChemicalElement(18, 'Ar', 'Аргон', 'Argon', '39.95'),
    ChemicalElement(19, 'K', 'Калий', 'Potassium', '39.0983'),
    ChemicalElement(20, 'Ca', 'Кальций', 'Calcium', '40.078'),
    ChemicalElement(21, 'Sc', 'Скандий', 'Scandium', '44.955907'),
    ChemicalElement(22, 'Ti', 'Титан', 'Titanium', '47.867'),
    ChemicalElement(23, 'V', 'Ванадий', 'Vanadium', '50.9415'),
    ChemicalElement(24, 'Cr', 'Хром', 'Chromium', '51.9961'),
    ChemicalElement(25, 'Mn', 'Марганец', 'Manganese', '54.938043'),
    ChemicalElement(26, 'Fe', 'Темір', 'Iron', '55.845'),
    ChemicalElement(27, 'Co', 'Кобальт', 'Cobalt', '58.933194'),
    ChemicalElement(28, 'Ni', 'Никель', 'Nickel', '58.6934'),
    ChemicalElement(29, 'Cu', 'Мыс', 'Copper', '63.546'),
    ChemicalElement(30, 'Zn', 'Мырыш', 'Zinc', '65.38'),
    ChemicalElement(31, 'Ga', 'Галлий', 'Gallium', '69.723'),
    ChemicalElement(32, 'Ge', 'Германий', 'Germanium', '72.630'),
    ChemicalElement(33, 'As', 'Мышьяк', 'Arsenic', '74.921595'),
    ChemicalElement(34, 'Se', 'Селен', 'Selenium', '78.971'),
    ChemicalElement(35, 'Br', 'Бром', 'Bromine', '79.904'),
    ChemicalElement(36, 'Kr', 'Криптон', 'Krypton', '83.798'),
    ChemicalElement(37, 'Rb', 'Рубидий', 'Rubidium', '85.4678'),
    ChemicalElement(38, 'Sr', 'Стронций', 'Strontium', '87.62'),
    ChemicalElement(39, 'Y', 'Иттрий', 'Yttrium', '88.905838'),
    ChemicalElement(40, 'Zr', 'Цирконий', 'Zirconium', '91.222'),
    ChemicalElement(41, 'Nb', 'Ниобий', 'Niobium', '92.90637'),
    ChemicalElement(42, 'Mo', 'Молибден', 'Molybdenum', '95.95'),
    ChemicalElement(43, 'Tc', 'Технеций', 'Technetium', '[97]'),
    ChemicalElement(44, 'Ru', 'Рутений', 'Ruthenium', '101.07'),
    ChemicalElement(45, 'Rh', 'Родий', 'Rhodium', '102.90549'),
    ChemicalElement(46, 'Pd', 'Палладий', 'Palladium', '106.42'),
    ChemicalElement(47, 'Ag', 'Күміс', 'Silver', '107.8682'),
    ChemicalElement(48, 'Cd', 'Кадмий', 'Cadmium', '112.414'),
    ChemicalElement(49, 'In', 'Индий', 'Indium', '114.818'),
    ChemicalElement(50, 'Sn', 'Қалайы', 'Tin', '118.710'),
    ChemicalElement(51, 'Sb', 'Сурьма', 'Antimony', '121.760'),
    ChemicalElement(52, 'Te', 'Теллур', 'Tellurium', '127.60'),
    ChemicalElement(53, 'I', 'Йод', 'Iodine', '126.90447'),
    ChemicalElement(54, 'Xe', 'Ксенон', 'Xenon', '131.293'),
    ChemicalElement(55, 'Cs', 'Цезий', 'Caesium', '132.90545196'),
    ChemicalElement(56, 'Ba', 'Барий', 'Barium', '137.327'),
    ChemicalElement(57, 'La', 'Лантан', 'Lanthanum', '138.90547'),
    ChemicalElement(58, 'Ce', 'Церий', 'Cerium', '140.116'),
    ChemicalElement(59, 'Pr', 'Празеодим', 'Praseodymium', '140.90766'),
    ChemicalElement(60, 'Nd', 'Неодим', 'Neodymium', '144.242'),
    ChemicalElement(61, 'Pm', 'Прометий', 'Promethium', '[145]'),
    ChemicalElement(62, 'Sm', 'Самарий', 'Samarium', '150.36'),
    ChemicalElement(63, 'Eu', 'Европий', 'Europium', '151.964'),
    ChemicalElement(64, 'Gd', 'Гадолиний', 'Gadolinium', '157.249'),
    ChemicalElement(65, 'Tb', 'Тербий', 'Terbium', '158.925354'),
    ChemicalElement(66, 'Dy', 'Диспрозий', 'Dysprosium', '162.500'),
    ChemicalElement(67, 'Ho', 'Гольмий', 'Holmium', '164.930329'),
    ChemicalElement(68, 'Er', 'Эрбий', 'Erbium', '167.259'),
    ChemicalElement(69, 'Tm', 'Тулий', 'Thulium', '168.934219'),
    ChemicalElement(70, 'Yb', 'Иттербий', 'Ytterbium', '173.045'),
    ChemicalElement(71, 'Lu', 'Лютеций', 'Lutetium', '174.96669'),
    ChemicalElement(72, 'Hf', 'Гафний', 'Hafnium', '178.486'),
    ChemicalElement(73, 'Ta', 'Тантал', 'Tantalum', '180.94788'),
    ChemicalElement(74, 'W', 'Вольфрам', 'Tungsten', '183.84'),
    ChemicalElement(75, 'Re', 'Рений', 'Rhenium', '186.207'),
    ChemicalElement(76, 'Os', 'Осмий', 'Osmium', '190.23'),
    ChemicalElement(77, 'Ir', 'Иридий', 'Iridium', '192.217'),
    ChemicalElement(78, 'Pt', 'Платина', 'Platinum', '195.084'),
    ChemicalElement(79, 'Au', 'Алтын', 'Gold', '196.966570'),
    ChemicalElement(80, 'Hg', 'Сынап', 'Mercury', '200.592'),
    ChemicalElement(81, 'Tl', 'Таллий', 'Thallium', '204.38'),
    ChemicalElement(82, 'Pb', 'Қорғасын', 'Lead', '207.2'),
    ChemicalElement(83, 'Bi', 'Висмут', 'Bismuth', '208.98040'),
    ChemicalElement(84, 'Po', 'Полоний', 'Polonium', '[209]'),
    ChemicalElement(85, 'At', 'Астат', 'Astatine', '[210]'),
    ChemicalElement(86, 'Rn', 'Радон', 'Radon', '[222]'),
    ChemicalElement(87, 'Fr', 'Франций', 'Francium', '[223]'),
    ChemicalElement(88, 'Ra', 'Радий', 'Radium', '[226]'),
    ChemicalElement(89, 'Ac', 'Актиний', 'Actinium', '[227]'),
    ChemicalElement(90, 'Th', 'Торий', 'Thorium', '232.0377'),
    ChemicalElement(91, 'Pa', 'Протактиний', 'Protactinium', '231.03588'),
    ChemicalElement(92, 'U', 'Уран', 'Uranium', '238.02891'),
    ChemicalElement(93, 'Np', 'Нептуний', 'Neptunium', '[237]'),
    ChemicalElement(94, 'Pu', 'Плутоний', 'Plutonium', '[244]'),
    ChemicalElement(95, 'Am', 'Америций', 'Americium', '[243]'),
    ChemicalElement(96, 'Cm', 'Кюрий', 'Curium', '[247]'),
    ChemicalElement(97, 'Bk', 'Берклий', 'Berkelium', '[247]'),
    ChemicalElement(98, 'Cf', 'Калифорний', 'Californium', '[251]'),
    ChemicalElement(99, 'Es', 'Эйнштейний', 'Einsteinium', '[252]'),
    ChemicalElement(100, 'Fm', 'Фермий', 'Fermium', '[257]'),
    ChemicalElement(101, 'Md', 'Менделевий', 'Mendelevium', '[258]'),
    ChemicalElement(102, 'No', 'Нобелий', 'Nobelium', '[259]'),
    ChemicalElement(103, 'Lr', 'Лоуренсий', 'Lawrencium', '[262]'),
    ChemicalElement(104, 'Rf', 'Резерфордий', 'Rutherfordium', '[267]'),
    ChemicalElement(105, 'Db', 'Дубний', 'Dubnium', '[270]'),
    ChemicalElement(106, 'Sg', 'Сиборгий', 'Seaborgium', '[269]'),
    ChemicalElement(107, 'Bh', 'Борий', 'Bohrium', '[270]'),
    ChemicalElement(108, 'Hs', 'Хассий', 'Hassium', '[270]'),
    ChemicalElement(109, 'Mt', 'Мейтнерий', 'Meitnerium', '[278]'),
    ChemicalElement(110, 'Ds', 'Дармштадтий', 'Darmstadtium', '[281]'),
    ChemicalElement(111, 'Rg', 'Рентгений', 'Roentgenium', '[281]'),
    ChemicalElement(112, 'Cn', 'Коперниций', 'Copernicium', '[285]'),
    ChemicalElement(113, 'Nh', 'Нихоний', 'Nihonium', '[286]'),
    ChemicalElement(114, 'Fl', 'Флеровий', 'Flerovium', '[289]'),
    ChemicalElement(115, 'Mc', 'Московий', 'Moscovium', '[289]'),
    ChemicalElement(116, 'Lv', 'Ливерморий', 'Livermorium', '[293]'),
    ChemicalElement(117, 'Ts', 'Теннессин', 'Tennessine', '[293]'),
    ChemicalElement(118, 'Og', 'Оганесон', 'Oganesson', '[294]'),
  ];
}

const _facts = <int, String>{
  1: 'Сутек — ғаламдағы ең кең таралған элемент.',
  6: 'Көміртек органикалық қосылыстардың негізін құрайды.',
  8: 'Оттек тыныс алу үшін қажет және судың құрамына кіреді.',
  11: 'Натрий ас тұзының (NaCl) құрамында кездеседі.',
  13: 'Алюминий жеңіл әрі берік қорытпалар жасауға қолданылады.',
  14: 'Кремний электроникадағы жартылай өткізгіштердің негізі.',
  17: 'Хлор ауыз суды залалсыздандыруда қолданылады.',
  20: 'Кальций сүйек пен тістің құрамында маңызды орын алады.',
  26: 'Темір болат өндірудің негізгі элементі.',
  29: 'Мыс электр тогын жақсы өткізеді.',
  47: 'Күміс электр тогын өте жақсы өткізеді.',
  79: 'Алтын коррозияға төзімді металл.',
  92: 'Уран ядролық отын ретінде қолданылады.',
};
