import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../widgets/ui.dart';

class FormulasScreen extends StatefulWidget {
  const FormulasScreen({super.key});

  @override
  State<FormulasScreen> createState() => _FormulasScreenState();
}

class _FormulasScreenState extends State<FormulasScreen> {
  final search = TextEditingController();
  String category = 'Барлығы';

  static const categories = [
    'Барлығы',
    'Есептеу',
    'Жай заттар және оксидтер',
    'Қышқылдар',
    'Негіздер мен тұздар',
    'Органикалық заттар',
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = _formulas.where((item) {
      final matchesCategory =
          category == 'Барлығы' || item.category == category;
      final matchesQuery =
          query.isEmpty ||
          '${item.title} ${item.formula} ${item.description} ${item.category}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Формулалар'),
        bottom: const AuthorAppBarLine(),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientCard(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Химия формулалары',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Керек формуланы тауып, мағынасын оқыңыз',
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.functions_rounded,
                        size: context.isCompact ? 36 : 48,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Атауы немесе формуласы бойынша іздеу',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Іздеуді тазарту',
                            onPressed: () {
                              search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final value in categories) ...[
                        ChoiceChip(
                          label: Text(value),
                          selected: category == value,
                          onSelected: (_) => setState(() => category = value),
                          selectedColor: AppColors.blue,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: category == value
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: category == value
                                ? AppColors.blue
                                : AppColors.line,
                          ),
                          showCheckmark: false,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${visible.length} формула',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const SoftCard(
                    child: Center(
                      child: Text(
                        'Бұл іздеу бойынша формула табылмады.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final item in visible) ...[
                    _FormulaCard(item: item),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.item});

  final _Formula item;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '${item.title} формуласын көшіру',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: item.formula));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.formula} көшірілді')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, color: AppColors.cyan),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(
            item.formula,
            style: formulaStyle(
              fontSize: context.isCompact ? 18 : 21,
              weight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _Formula {
  const _Formula(this.category, this.title, this.formula, this.description);
  final String category, title, formula, description;
}

const _formulas = <_Formula>[
  _Formula(
    'Есептеу',
    'Зат мөлшері',
    'n = m / M',
    'n — моль, m — масса (г), M — молярлық масса (г/моль).',
  ),
  _Formula(
    'Есептеу',
    'Масса',
    'm = n · M',
    'Зат мөлшері мен молярлық масса арқылы массаны табу.',
  ),
  _Formula(
    'Есептеу',
    'Бөлшектер саны',
    'N = n · Nₐ',
    'Nₐ ≈ 6,02 · 10²³ моль⁻¹ — Авогадро тұрақтысы.',
  ),
  _Formula(
    'Есептеу',
    'Газ көлемі',
    'V = n · Vₘ',
    'Қалыпты жағдайда Vₘ ≈ 22,4 л/моль.',
  ),
  _Formula('Есептеу', 'Тығыздық', 'ρ = m / V', 'Массаның көлемге қатынасы.'),
  _Formula(
    'Есептеу',
    'Ерітіндідегі массалық үлес',
    'w = m(еріген зат) / m(ерітінді) · 100%',
    'Еріген зат массасының бүкіл ерітінді массасына қатынасы.',
  ),
  _Formula(
    'Есептеу',
    'Молярлық концентрация',
    'C = n / V',
    'V литрмен алынса, C өлшемі моль/л болады.',
  ),
  _Formula(
    'Есептеу',
    'Реакция шығымы',
    'η = m(нақты) / m(теориялық) · 100%',
    'Нақты алынған өнімнің теориялық мөлшерге қатынасы.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Сутек',
    'H₂',
    'Екі сутек атомынан тұратын молекула.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Оттек',
    'O₂',
    'Екі оттек атомынан тұратын молекула.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Азот',
    'N₂',
    'Ауаның негізгі құрамдастарының бірі.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Хлор',
    'Cl₂',
    'Екі хлор атомынан тұратын молекула.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Су',
    'H₂O',
    'Екі сутек және бір оттек атомынан тұрады.',
  ),
  _Formula(
    'Жай заттар және оксидтер',
    'Көмірқышқыл газы',
    'CO₂',
    'Көміртек диоксиді.',
  ),
  _Formula('Қышқылдар', 'Тұз қышқылы', 'HCl', 'Судағы хлорсутек ерітіндісі.'),
  _Formula('Қышқылдар', 'Күкірт қышқылы', 'H₂SO₄', 'Екі негізді күшті қышқыл.'),
  _Formula('Қышқылдар', 'Азот қышқылы', 'HNO₃', 'Бір негізді күшті қышқыл.'),
  _Formula('Қышқылдар', 'Фосфор қышқылы', 'H₃PO₄', 'Үш негізді қышқыл.'),
  _Formula(
    'Негіздер мен тұздар',
    'Натрий гидроксиді',
    'NaOH',
    'Суда еритін күшті негіз.',
  ),
  _Formula(
    'Негіздер мен тұздар',
    'Кальций гидроксиді',
    'Ca(OH)₂',
    'Кальцийдің негізі.',
  ),
  _Formula('Негіздер мен тұздар', 'Ас тұзы', 'NaCl', 'Натрий хлориді.'),
  _Formula(
    'Негіздер мен тұздар',
    'Кальций карбонаты',
    'CaCO₃',
    'Бор мен әктастың негізгі құрамдасы.',
  ),
  _Formula(
    'Негіздер мен тұздар',
    'Натрий карбонаты',
    'Na₂CO₃',
    'Сода деп аталатын тұз.',
  ),
  _Formula('Органикалық заттар', 'Метан', 'CH₄', 'Ең қарапайым алкан.'),
  _Formula('Органикалық заттар', 'Этан', 'C₂H₆', 'Екі көміртекті алкан.'),
  _Formula('Органикалық заттар', 'Этен', 'C₂H₄', 'Екі көміртекті алкен.'),
  _Formula('Органикалық заттар', 'Этанол', 'C₂H₅OH', 'Бір атомды спирт.'),
  _Formula('Органикалық заттар', 'Сірке қышқылы', 'CH₃COOH', 'Карбон қышқылы.'),
  _Formula('Органикалық заттар', 'Глюкоза', 'C₆H₁₂O₆', 'Қарапайым көмірсу.'),
];
