import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/practice.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int index = 0;
  int attempts = 0;
  int? selected;
  bool showHint = false;
  bool saving = false;
  bool saveFailed = false;
  Set<String> completed = {};

  PracticeTask get task => PracticeCatalog.tasks[index];
  bool get answeredCorrectly => selected != null && task.isCorrect(selected!);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final result = await AppServices.instance.loadPracticeProgress();
      final currentIds = PracticeCatalog.tasks.map((item) => item.id).toSet();
      if (mounted) setState(() => completed = result.intersection(currentIds));
    } catch (_) {
      // Practice remains usable without a connection; saving can be retried.
    }
  }

  void _choose(int value) {
    if (saving || answeredCorrectly) return;
    setState(() {
      selected = value;
      attempts++;
      showHint = false;
    });
    if (task.isCorrect(value) && !completed.contains(task.id)) {
      _saveCompletion();
    }
  }

  Future<void> _saveCompletion() async {
    final id = task.id;
    setState(() {
      saving = true;
      saveFailed = false;
    });
    try {
      await AppServices.instance.savePracticeCompletion(id, attempts);
      if (mounted) setState(() => completed.add(id));
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _next() {
    setState(() {
      index = index + 1 < PracticeCatalog.tasks.length ? index + 1 : 0;
      attempts = 0;
      selected = null;
      showHint = false;
      saveFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = task;
    final correct = answeredCorrectly;
    final total = PracticeCatalog.tasks.length;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коэффициент жаттығуы'),
        bottom: const AuthorAppBarLine(),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressHero(
                  current: index + 1,
                  total: total,
                  completed: completed.length,
                ),
                const SizedBox(height: 14),
                const _HowToCard(),
                const SizedBox(height: 18),
                Text(
                  'Тапсырма ${index + 1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TagLabel(current.title),
                      const SizedBox(height: 17),
                      const Text(
                        'Қай сан жетіспейді?',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            _equation(current, selected),
                            maxLines: 1,
                            style: formulaStyle(
                              fontSize: 18,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Жауапты таңдаңыз',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (final option in current.options) ...[
                      if (option != current.options.first)
                        const SizedBox(width: 10),
                      Expanded(
                        child: _AnswerOption(
                          value: option,
                          selected: selected == option,
                          correct: correct,
                          disabled: correct || saving,
                          onTap: () => _choose(option),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: selected == null
                      ? _HelpCard(
                          key: const ValueKey('help'),
                          hint: current.hint,
                          expanded: showHint,
                          onTap: () => setState(() => showHint = !showHint),
                        )
                      : _FeedbackCard(
                          key: ValueKey('answer_${current.id}_$selected'),
                          correct: correct,
                          task: current,
                        ),
                ),
                if (saveFailed && correct) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: saving ? null : _saveCompletion,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Прогресті қайта сақтау'),
                  ),
                ],
                const SizedBox(height: 16),
                if (correct)
                  PrimaryButton(
                    label: index == total - 1
                        ? 'Қайта бастау'
                        : 'Келесі тапсырма',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _next,
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _next,
                      child: const Text('Әзірге өткізу  →'),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _equation(PracticeTask current, int? value) {
    String side(List<String> formulas, int offset) => [
      for (var i = 0; i < formulas.length; i++)
        '${offset + i == current.blankIndex ? (value ?? '?') : (current.coefficients[offset + i] == 1 ? '' : current.coefficients[offset + i])}${_subscript(formulas[i])}',
    ].join(' + ');
    return '${side(current.reagents, 0)}  →  ${side(current.products, current.reagents.length)}';
  }

  String _subscript(String formula) => formula.replaceAllMapped(
    RegExp(r'\d'),
    (match) => '₀₁₂₃₄₅₆₇₈₉'[int.parse(match.group(0)!)],
  );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.current,
    required this.total,
    required this.completed,
  });
  final int current;
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) => GradientCard(
    gradient: AppColors.aquaGradient,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Бос санды табайық',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.science_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$current / $total тапсырма  ·  $completed аяқталды',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: completed / total,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: .28),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _HowToCard extends StatelessWidget {
  const _HowToCard();

  @override
  Widget build(BuildContext context) => SoftCard(
    color: const Color(0xFFEAF8EC),
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.mint, size: 21),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Формула алдындағы сан молекула санын көрсетеді. Мысалы, 2H₂O — екі су молекуласы.',
            style: TextStyle(color: AppColors.ink, fontSize: 12, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.value,
    required this.selected,
    required this.correct,
    required this.disabled,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final bool correct;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? correct
              ? AppColors.mint
              : AppColors.coral
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: '$value коэффициенті',
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 140),
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: selected ? color : AppColors.line,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$value',
            style: formulaStyle(
              fontSize: 24,
              weight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    super.key,
    required this.hint,
    required this.expanded,
    required this.onTap,
  });
  final String hint;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoftCard(
    color: const Color(0xFFFFF8E9),
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lightbulb_outline_rounded,
          color: AppColors.accentDeep,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            expanded ? hint : 'Көмек керек пе? Кеңесті ашыңыз.',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
        Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: AppColors.accentDeep,
          size: 20,
        ),
      ],
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({super.key, required this.correct, required this.task});
  final bool correct;
  final PracticeTask task;

  @override
  Widget build(BuildContext context) {
    final counts = task.check(task.answer);
    return Semantics(
      liveRegion: true,
      child: SoftCard(
        color: correct ? const Color(0xFFEAF8EC) : const Color(0xFFFFF0F3),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
              color: correct ? AppColors.mint : AppColors.coral,
              size: 23,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Дұрыс! Жарайсың.' : 'Тағы бір рет байқап көр.',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    correct ? task.explanation : task.hint,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (correct) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${task.focusElement}: сол жақта ${counts.left[task.focusElement]}, оң жақта ${counts.right[task.focusElement]}',
                      style: formulaStyle(
                        color: AppColors.mint,
                        fontSize: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
