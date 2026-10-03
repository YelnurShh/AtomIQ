import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/lesson.dart';
import '../models/lesson_curriculum.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';
import 'formulas_screen.dart';
import 'practice_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Set<String> completed = {};
  int? selectedGrade;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final result = await AppServices.instance.loadLessonProgress();
    if (mounted) setState(() => completed = result);
  }

  Future<void> _open(ChemistryLesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonDetailScreen(lesson: lesson),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: AdaptivePage(
                padding: EdgeInsets.fromLTRB(
                  context.pagePadding,
                  10,
                  context.pagePadding,
                  12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.ink,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    indicator: BoxDecoration(
                      gradient: AppColors.aquaGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tabs: const [
                      Tab(text: 'Теория'),
                      Tab(text: 'Практика'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _catalogPage(CurriculumCatalog.theory, false),
                  _catalogPage(CurriculumCatalog.practice, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogPage(List<ChemistryLesson> lessons, bool practice) {
    final count = lessons
        .where((lesson) => completed.contains(lesson.id))
        .length;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (practice) ...[
                  SoftCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FormulasScreen(),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.functions_rounded,
                            color: AppColors.mint,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Формулалар',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Заттар мен есептеу формулаларының анықтамалығы',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GradientCard(
                  gradient: practice
                      ? AppColors.aquaGradient
                      : AppColors.primaryGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        practice
                            ? Icons.science_rounded
                            : Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        practice
                            ? 'Есеп шығарып шыңдал'
                            : 'Химияны қадамдап үйрен',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        practice
                            ? '10 бағыт · әрқайсысында 15 тест және мысал есептер'
                            : '7–11 сынып · әр сабақта түсіндірме және 5 тест',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: lessons.isEmpty ? 0 : count / lessons.length,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: .26),
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$count / ${lessons.length} аяқталды',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (practice) ...[
                  const SizedBox(height: 16),
                  SoftCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PracticeScreen(),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        Icon(Icons.balance_rounded, color: AppColors.cyan),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Коэффициент жаттығуы',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _lessonList(lessons, practice),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonList(List<ChemistryLesson> lessons, bool practice) {
    final visibleLessons = practice || selectedGrade == null
        ? lessons
        : lessons.where((lesson) => lesson.grade == selectedGrade).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route_rounded, color: AppColors.cyan, size: 21),
            const SizedBox(width: 8),
            Text(
              practice ? 'Практикалық бағыттар' : 'Теория сабақтары',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          practice
              ? 'Түсіндірме → мысал → 15 тест'
              : '7-сыныптан 11-сыныпқа дейін',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (!practice) ...[
          Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final grade in <int?>[null, 7, 8, 9, 10, 11]) ...[
                    ChoiceChip(
                      label: Text(grade == null ? 'Барлығы' : '$grade-сынып'),
                      selected: selectedGrade == grade,
                      onSelected: (_) => setState(() => selectedGrade = grade),
                      selectedColor: AppColors.soft,
                      side: BorderSide(
                        color: selectedGrade == grade
                            ? AppColors.cyan
                            : AppColors.line,
                      ),
                      labelStyle: TextStyle(
                        color: selectedGrade == grade
                            ? AppColors.cyan
                            : AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        ...visibleLessons.asMap().entries.map((entry) {
          final lesson = entry.value;
          final done = completed.contains(lesson.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: SoftCard(
              onTap: () => _open(lesson),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.mint.withValues(alpha: .15)
                          : AppColors.soft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, color: AppColors.mint)
                        : Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: AppColors.cyan,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${lesson.grade}-сынып',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson.summary,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          done
                              ? 'Өтілді · Қайта оқу'
                              : 'Оқу · ${lesson.questions.length} тест · Мысал есеп',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

enum _LessonStep { read, quiz, match, done }

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});
  final ChemistryLesson lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  _LessonStep step = _LessonStep.read;
  int questionIndex = 0;
  int? selectedAnswer;
  int? selectedLeft;
  int mistakes = 0;
  bool matchError = false;
  bool saving = false;
  bool saveFailed = false;
  final Set<int> matched = {};
  final Set<int> revealedExamples = {};

  ChemistryLesson get lesson => widget.lesson;

  void _answer(int value) {
    if (selectedAnswer != null) return;
    setState(() {
      selectedAnswer = value;
      if (value != lesson.questions[questionIndex].correctIndex) mistakes++;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (questionIndex + 1 == lesson.questions.length) {
        step = _LessonStep.match;
      } else {
        questionIndex++;
      }
      selectedAnswer = null;
    });
  }

  void _chooseRight(int value) {
    if (selectedLeft == null || matched.contains(value)) return;
    setState(() {
      if (selectedLeft == value) {
        matched.add(value);
        selectedLeft = null;
        matchError = false;
        if (matched.length == lesson.matches.length) {
          step = _LessonStep.done;
          _save();
        }
      } else {
        mistakes++;
        matchError = true;
      }
    });
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() {
      saving = true;
      saveFailed = false;
    });
    try {
      await AppServices.instance.saveLessonCompletion(lesson.id, mistakes);
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = switch (step) {
      _LessonStep.read => 1,
      _LessonStep.quiz => 2,
      _LessonStep.match || _LessonStep.done => 3,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: const AuthorAppBarLine(),
      ),
      body: ListView(
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stage / 3 қадам',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stage / 3,
                    minHeight: 6,
                    backgroundColor: AppColors.soft,
                  ),
                ),
                const SizedBox(height: 22),
                switch (step) {
                  _LessonStep.read => _readContent(),
                  _LessonStep.quiz => _quizContent(),
                  _LessonStep.match => _matchContent(),
                  _LessonStep.done => _doneContent(),
                },
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Түсініп алайық', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(lesson.summary, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 18),
      ...lesson.concepts.asMap().entries.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.soft,
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text('Мысал есептер', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      ...((lesson.workedExamples.isEmpty
              ? [
                  LessonWorkedExample(
                    question: lesson.exampleTitle,
                    answer: lesson.example,
                  ),
                ]
              : lesson.workedExamples)
          .asMap()
          .entries
          .map((entry) {
            final revealed = revealedExamples.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: SoftCard(
                color: const Color(0xFFEAF8ED),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЕСЕП ${entry.key + 1}',
                      style: const TextStyle(
                        color: AppColors.mint,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.value.question,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        if (revealed) {
                          revealedExamples.remove(entry.key);
                        } else {
                          revealedExamples.add(entry.key);
                        }
                      }),
                      icon: Icon(
                        revealed
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      label: Text(revealed ? 'Жауапты жасыру' : 'Жауабын көру'),
                    ),
                    if (revealed) ...[
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.answer,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          })),
      const SizedBox(height: 22),
      PrimaryButton(
        label: 'Тестке өту',
        icon: Icons.arrow_forward_rounded,
        onTap: () => setState(() => step = _LessonStep.quiz),
      ),
    ],
  );

  Widget _quizContent() {
    final question = lesson.questions[questionIndex];
    final correct = selectedAnswer == question.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Өзіңді тексер',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          '${questionIndex + 1} / ${lesson.questions.length} сұрақ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (questionIndex + 1) / lesson.questions.length,
            minHeight: 6,
            backgroundColor: AppColors.soft,
          ),
        ),
        const SizedBox(height: 18),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.text,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 17),
              ...question.options.asMap().entries.map((entry) {
                final chosen = selectedAnswer == entry.key;
                final color = chosen
                    ? (correct ? AppColors.mint : AppColors.coral)
                    : AppColors.line;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: chosen ? color.withValues(alpha: .13) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: selectedAnswer == null
                          ? () => _answer(entry.key)
                          : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: color),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        if (selectedAnswer != null) ...[
          const SizedBox(height: 14),
          _feedback(
            correct
                ? 'Дұрыс! ${question.explanation}'
                : 'Бұл жолы қате. ${question.explanation}',
            correct,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: questionIndex + 1 == lesson.questions.length
                ? 'Сәйкестендіруге өту'
                : 'Келесі сұрақ',
            onTap: _nextQuestion,
          ),
        ],
      ],
    );
  }

  Widget _matchContent() {
    final order = List<int>.generate(
      lesson.matches.length,
      (i) => (i + 1) % lesson.matches.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Жұптарды тап', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text(
          'Алдымен сол жақтан біреуін, кейін оған сәйкес оң жақтан жауабын бас.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: List.generate(
                  lesson.matches.length,
                  (i) => _matchTile(lesson.matches[i].left, i, true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: order
                    .map((i) => _matchTile(lesson.matches[i].right, i, false))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _feedback(
          matchError
              ? 'Әзірге сәйкес келмеді. Басқа жауапты таңда.'
              : '${matched.length} / ${lesson.matches.length} жұп табылды',
          !matchError,
        ),
      ],
    );
  }

  Widget _matchTile(String label, int pair, bool left) {
    final done = matched.contains(pair);
    final active = left && selectedLeft == pair;
    final color = done
        ? AppColors.mint
        : active
        ? AppColors.cyan
        : AppColors.line;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: active,
        child: Material(
          color: done
              ? AppColors.mint.withValues(alpha: .12)
              : active
              ? AppColors.soft
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: done
                ? null
                : left
                ? () => setState(() {
                    selectedLeft = pair;
                    matchError = false;
                  })
                : () => _chooseRight(pair),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: active ? 2 : 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: done ? AppColors.mint : AppColors.ink,
                  fontSize: context.isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.verified_rounded, color: AppColors.mint, size: 58),
      const SizedBox(height: 16),
      Text(
        'Сабақ аяқталды!',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        '${lesson.questions.length} тест сұрағына жауап беріп, ${lesson.matches.length} жұпты таптың.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 14),
      SoftCard(
        child: Row(
          children: [
            const Icon(Icons.insights_rounded, color: AppColors.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mistakes == 0
                    ? 'Тамаша! Барлығын қатесіз орындадың.'
                    : '$mistakes қате жібердің. Сабақты қайта оқып, тағы байқап көре аласың.',
                style: const TextStyle(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
      if (saveFailed) ...[
        const SizedBox(height: 12),
        _feedback('Нәтиже құрылғыда сақталды. Бұлтпен синхрондалмады.', false),
        TextButton(
          onPressed: saving ? null : _save,
          child: const Text('Қайта синхрондау'),
        ),
      ],
      const SizedBox(height: 22),
      PrimaryButton(
        label: 'Сабақтарға оралу',
        loading: saving,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _feedback(String message, bool positive) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: (positive ? AppColors.mint : AppColors.coral).withValues(
        alpha: .13,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: positive ? const Color(0xFF287D33) : const Color(0xFFAA4264),
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    ),
  );
}
