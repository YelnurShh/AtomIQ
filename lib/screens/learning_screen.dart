import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/learning.dart';
import '../models/lesson_curriculum.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';
import 'elements_screen.dart';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

class RoleDashboard extends StatelessWidget {
  const RoleDashboard({
    super.key,
    required this.onOpenLearning,
    required this.onOpenAi,
    required this.onOpenLessons,
  });
  final VoidCallback onOpenLearning, onOpenAi, onOpenLessons;

  @override
  Widget build(BuildContext context) {
    final app = AppServices.instance;
    final classes = app.isTeacher ? null : app.loadStudentClasses();
    return RefreshIndicator(
      onRefresh: () async => (context as Element).markNeedsBuild(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сәлем, ${app.displayName.split(' ').first}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  app.isTeacher
                      ? 'Сыныптарыңыз бен оқушы жауаптарын бір жерден басқарыңыз.'
                      : 'Тапсырмаларды орындап, мұғалімнің кері байланысын алыңыз.',
                ),
                const SizedBox(height: 22),
                if (app.isTeacher)
                  GradientCard(
                    gradient: AppColors.primaryGradient,
                    onTap: onOpenLearning,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Сабақ кеңістігі',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Сынып ашыңыз, тапсырма беріңіз және бағалаңыз.',
                                style: TextStyle(
                                  color: Color(0xE6FFFFFF),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ашу',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.co_present_rounded,
                          color: Colors.white,
                          size: context.isCompact ? 54 : 72,
                        ),
                      ],
                    ),
                  ),
                if (app.isTeacher) const SizedBox(height: 16),
                const ElementHomePreview(),
                const SizedBox(height: 22),
                if (app.isTeacher)
                  FutureBuilder<ProfileOverview>(
                    future: app.loadProfileOverview(),
                    builder: (context, snap) {
                      final data = snap.data;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.groups_2_outlined,
                                  value: data == null
                                      ? '—'
                                      : '${data.classesCount}',
                                  label: 'Сынып',
                                  color: AppColors.violet,
                                  onTap: onOpenLearning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.school_outlined,
                                  value: data == null
                                      ? '—'
                                      : '${data.studentsCount}',
                                  label: 'Оқушы',
                                  color: AppColors.mint,
                                  onTap: onOpenLearning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.assignment_outlined,
                                  value: data == null
                                      ? '—'
                                      : '${data.assignmentsCount}',
                                  label: 'Берілген тапсырма',
                                  color: AppColors.blue,
                                  onTap: onOpenLearning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.pending_actions_outlined,
                                  value: data == null
                                      ? '—'
                                      : '${data.pendingSubmissionsCount}',
                                  label: 'Тексеруді күтуде',
                                  color: AppColors.coral,
                                  onTap: onOpenLearning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  )
                else
                  FutureBuilder<List<Classroom>>(
                    future: classes,
                    builder: (context, snap) {
                      final count = snap.data?.length;
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.groups_2_outlined,
                              value: count == null ? '—' : '$count',
                              label: 'Қосылған сынып',
                              color: AppColors.violet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FutureBuilder<Set<String>>(
                              future: app.loadLessonProgress(),
                              builder: (context, progress) => _StatCard(
                                icon: Icons.menu_book_outlined,
                                value: progress.hasData
                                    ? '${CurriculumCatalog.theory.where((lesson) => progress.data!.contains(lesson.id)).length}/${CurriculumCatalog.theory.length}'
                                    : '—',
                                label: 'Өтілген сабақ',
                                color: AppColors.mint,
                                onTap: onOpenLessons,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Text(
                  app.isTeacher ? 'Жылдам әрекеттер' : 'Оқуды жалғастыру',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: app.isTeacher
                      ? Icons.add_task_rounded
                      : Icons.task_alt_rounded,
                  color: AppColors.cyan,
                  title: app.isTeacher
                      ? 'Сынып пен тапсырмаларды басқару'
                      : 'Берілген тапсырмаларды көру',
                  subtitle: app.isTeacher
                      ? 'Жаңа жұмыс беріп, жауаптарды тексеріңіз'
                      : 'Жауап жіберіп, пікірді оқыңыз',
                  onTap: onOpenLearning,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.violet,
                  title: 'AI химия көмекшісі',
                  subtitle: app.isTeacher
                      ? 'Тапсырма мен түсіндірме дайындаңыз'
                      : 'Қиын есепті қадамдап түсініңіз',
                  onTap: onOpenAi,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String value, label;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SoftCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SoftCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    ),
  );
}

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});
  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  int version = 0;
  Future<List<Classroom>> get future => AppServices.instance.isTeacher
      ? AppServices.instance.loadTeacherClasses()
      : AppServices.instance.loadStudentClasses();

  Future<void> _createClass() async {
    final name = await _textSheet(
      context,
      title: 'Жаңа сынып',
      label: 'Сынып атауы',
      hint: 'Мысалы: 9A · Химия',
      action: 'Сынып ашу',
    );
    if (name == null || !mounted) return;
    try {
      final classroom = await AppServices.instance.createClassroom(name);
      if (!mounted) return;
      setState(() => version++);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Сынып дайын'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Оқушыларға осы кодты жіберіңіз:'),
              const SizedBox(height: 16),
              SelectableText(
                classroom.code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: classroom.code)),
              child: const Text('Көшіру'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Дайын'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _error(context, e);
    }
  }

  Future<void> _joinClass() async {
    final code = await _textSheet(
      context,
      title: 'Сыныпқа қосылу',
      label: '6 таңбалы код',
      hint: 'ABC234',
      action: 'Қосылу',
      capitalization: TextCapitalization.characters,
    );
    if (code == null || !mounted) return;
    try {
      await AppServices.instance.joinClassroom(code);
      if (mounted) setState(() => version++);
    } catch (e) {
      if (mounted) _error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = AppServices.instance.isTeacher;
    return FutureBuilder<List<Classroom>>(
      key: ValueKey(version),
      future: future,
      builder: (context, snap) => RefreshIndicator(
        onRefresh: () async => setState(() => version++),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientCard(
                    gradient: teacher
                        ? AppColors.warmGradient
                        : AppColors.aquaGradient,
                    onTap: teacher ? _createClass : _joinClass,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher
                                    ? 'Жаңа сынып ашыңыз'
                                    : 'Сыныпқа қосылыңыз',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                teacher
                                    ? 'Кодты оқушыларға жіберіп, жұмысты бастаңыз.'
                                    : 'Мұғалім берген кодты енгізіңіз.',
                                style: const TextStyle(
                                  color: Color(0xE6FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          teacher ? Icons.add_rounded : Icons.login_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    teacher ? 'Менің сыныптарым' : 'Менің сыныптарым',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Сыныптар жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if ((snap.data ?? []).isEmpty)
                    _EmptyState(
                      icon: teacher
                          ? Icons.groups_2_outlined
                          : Icons.key_rounded,
                      title: teacher
                          ? 'Әзірге сынып жоқ'
                          : 'Сыныпқа әлі қосылмадыңыз',
                      subtitle: teacher
                          ? 'Алғашқы сыныбыңызды ашыңыз.'
                          : 'Мұғалімнен шақыру кодын алыңыз.',
                    )
                  else
                    ...snap.data!.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ClassroomDetailScreen(
                                classroom: c,
                                teacher: teacher,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: teacher
                                      ? AppColors.primaryGradient
                                      : AppColors.aquaGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  teacher
                                      ? Icons.groups_2_rounded
                                      : Icons.school_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      teacher
                                          ? 'Код: ${c.code}'
                                          : '${c.teacherName} · ${c.code}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassroomDetailScreen extends StatefulWidget {
  const ClassroomDetailScreen({
    super.key,
    required this.classroom,
    required this.teacher,
  });
  final Classroom classroom;
  final bool teacher;
  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late Future<List<ClassPost>> postsFuture;
  late Future<List<LearningAssignment>> assignmentsFuture;
  late Future<List<ClassMember>> membersFuture;
  bool publishing = false;
  String publishingLabel = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this)..addListener(_tabChanged);
    postsFuture = AppServices.instance.loadClassPosts(widget.classroom.id);
    assignmentsFuture = AppServices.instance.loadAssignments(
      widget.classroom.id,
    );
    membersFuture = AppServices.instance.loadClassMembers(widget.classroom.id);
  }

  Future<void> _refreshPosts() async {
    final next = AppServices.instance.loadClassPosts(widget.classroom.id);
    setState(() {
      postsFuture = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error and keeps retry available.
    }
  }

  Future<void> _refreshAssignments() async {
    final next = AppServices.instance.loadAssignments(widget.classroom.id);
    setState(() {
      assignmentsFuture = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error and keeps retry available.
    }
  }

  Future<void> _refreshMembers() async {
    final next = AppServices.instance.loadClassMembers(widget.classroom.id);
    setState(() {
      membersFuture = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error and keeps retry available.
    }
  }

  void _tabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    tabs.removeListener(_tabChanged);
    tabs.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final form = GlobalKey<FormState>();
    var title = '';
    var body = '';
    final post = await showModalBottomSheet<({String title, String body})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _Sheet(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Жаңа пост',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Сынып оқушыларына хабарлама жариялаңыз.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              TextFormField(
                maxLength: 100,
                onChanged: (value) => title = value,
                decoration: const InputDecoration(labelText: 'Пост тақырыбы'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Тақырыпты жазыңыз'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                onChanged: (value) => body = value,
                decoration: const InputDecoration(
                  labelText: 'Хабарлама мәтіні',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Хабарлама мәтінін жазыңыз'
                    : null,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Постты жариялау',
                icon: Icons.send_rounded,
                onTap: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(sheetContext, (
                      title: title.trim(),
                      body: body.trim(),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (post == null || !mounted || publishing) return;
    setState(() {
      publishing = true;
      publishingLabel = 'Пост жариялануда...';
    });
    try {
      await AppServices.instance.createClassPost(
        widget.classroom.id,
        title: post.title,
        body: post.body,
      );
      if (mounted) await _refreshPosts();
    } catch (error) {
      if (mounted) _error(context, error);
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Future<void> _createAssignment() async {
    var title = '';
    var equation = '';
    var instructions = '';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _Sheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Жаңа тапсырма',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextFormField(
              onChanged: (value) => title = value,
              decoration: const InputDecoration(labelText: 'Тақырып'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => equation = value,
              style: formulaStyle(),
              decoration: const InputDecoration(
                labelText: 'Теңдеу',
                hintText: 'H2 + O2 → H2O',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => instructions = value,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Нұсқаулық',
                hintText: 'Қадамдарын түсіндіріңіз',
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Тапсырманы жариялау',
              icon: Icons.send_rounded,
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted && !publishing) {
      setState(() {
        publishing = true;
        publishingLabel = 'Тапсырма жариялануда...';
      });
      try {
        await AppServices.instance.createAssignment(
          widget.classroom.id,
          title: title,
          equation: equation,
          instructions: instructions,
          dueAt: DateTime.now().add(const Duration(days: 7)),
        );
        if (mounted) await _refreshAssignments();
      } catch (e) {
        if (mounted) _error(context, e);
      } finally {
        if (mounted) setState(() => publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Column(
          children: [
            const AuthorAppBarLine(),
            TabBar(
              controller: tabs,
              isScrollable: false,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.cyan,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Посттар'),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Үй тапсырмасы'),
                  ),
                ),
                Tab(text: 'Оқушылар'),
              ],
            ),
          ],
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.classroom.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(
            widget.teacher
                ? 'Код: ${widget.classroom.code}'
                : widget.classroom.teacherName,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
      actions: const [SizedBox(width: 12)],
    ),
    floatingActionButton: widget.teacher && tabs.index != 2
        ? SizedBox(
            width: context.isCompact ? 165 : 190,
            child: PrimaryButton(
              onTap: publishing
                  ? null
                  : tabs.index == 0
                  ? _createPost
                  : _createAssignment,
              loading: publishing,
              label: publishing
                  ? publishingLabel
                  : tabs.index == 0
                  ? 'Пост жазу'
                  : 'Тапсырма қосу',
              icon: tabs.index == 0
                  ? Icons.edit_outlined
                  : Icons.add_task_rounded,
            ),
          )
        : null,
    body: Stack(
      children: [
        TabBarView(
          controller: tabs,
          children: [_postsTab(), _assignmentsTab(), _membersTab()],
        ),
        if (publishing) ...[
          const ModalBarrier(dismissible: false, color: Color(0x99FFFFFF)),
          Center(
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(publishingLabel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _postsTab() => FutureBuilder<List<ClassPost>>(
    future: postsFuture,
    builder: (context, snap) {
      final posts = snap.data ?? [];
      return RefreshIndicator(
        onRefresh: _refreshPosts,
        child: ListView(
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сынып лентасы',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.teacher
                        ? 'Хабарламалар барлық тіркелген оқушыға көрінеді.'
                        : 'Мұғалімнің хабарламаларын оқып, пікір қалдырыңыз.',
                  ),
                  const SizedBox(height: 18),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Посттар жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if (posts.isEmpty)
                    _EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'Әзірге пост жоқ',
                      subtitle: widget.teacher
                          ? '«Пост жазу» арқылы алғашқы хабарламаны жариялаңыз.'
                          : 'Мұғалім пост жариялағанда осы жерден көресіз.',
                    )
                  else
                    ...posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ClassPostCard(
                          post: post,
                          onComments: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PostDetailScreen(post: post),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _assignmentsTab() => FutureBuilder<List<LearningAssignment>>(
    future: assignmentsFuture,
    builder: (context, snap) {
      final items = snap.data ?? [];
      return RefreshIndicator(
        onRefresh: _refreshAssignments,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacher
                        ? 'Берілген тапсырмалар'
                        : 'Орындайтын тапсырмалар',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Тапсырмалар жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if (items.isEmpty)
                    _EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'Тапсырма жоқ',
                      subtitle: widget.teacher
                          ? '«Тапсырма қосу» арқылы үй жұмысын жариялаңыз.'
                          : 'Мұғалім тапсырма бергенде осында шығады.',
                    )
                  else
                    ...items.map(
                      (assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => widget.teacher
                                  ? TeacherAssignmentScreen(
                                      assignment: assignment,
                                    )
                                  : StudentAssignmentScreen(
                                      assignment: assignment,
                                    ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      assignment.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(
                                    assignment.overdue
                                        ? 'Мерзімі өтті'
                                        : '${_shortDate(assignment.dueAt)} дейін',
                                    color: assignment.overdue
                                        ? AppColors.coral
                                        : AppColors.mint,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                assignment.equation,
                                style: formulaStyle(
                                  fontSize: 16,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              if (assignment.instructions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(assignment.instructions),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 72),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _membersTab() => FutureBuilder<List<ClassMember>>(
    future: membersFuture,
    builder: (context, snap) {
      final members = snap.data ?? [];
      return RefreshIndicator(
        onRefresh: _refreshMembers,
        child: ListView(
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тіркелген оқушылар',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    snap.hasData ? '${members.length} оқушы' : 'Сынып мүшелері',
                  ),
                  const SizedBox(height: 18),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Оқушылар жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if (members.isEmpty)
                    const _EmptyState(
                      icon: Icons.group_outlined,
                      title: 'Әзірге оқушы жоқ',
                      subtitle: 'Сынып кодын оқушыларға жіберіңіз.',
                    )
                  else
                    ...members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SoftCard(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.soft,
                                child: Text(
                                  member.name.isEmpty
                                      ? '?'
                                      : member.name.characters.first
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_shortDate(member.joinedAt)} қосылды',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ClassPostCard extends StatelessWidget {
  const _ClassPostCard({required this.post, this.onComments});
  final ClassPost post;
  final VoidCallback? onComments;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 17, 17, 13),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.soft,
                child: Text(
                  post.authorName.isEmpty
                      ? '?'
                      : post.authorName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _shortDate(post.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.campaign_outlined, color: AppColors.cyan),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                post.body,
                style: const TextStyle(color: AppColors.ink, height: 1.5),
              ),
            ],
          ),
        ),
        if (onComments != null) ...[
          const Divider(height: 1),
          InkWell(
            onTap: onComments,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Пікірлер · Жауап беру',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final ClassPost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final input = TextEditingController();
  late Future<List<PostComment>> commentsFuture;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    commentsFuture = AppServices.instance.loadPostComments(widget.post);
  }

  Future<void> _refreshComments() async {
    final next = AppServices.instance.loadPostComments(widget.post);
    setState(() {
      commentsFuture = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error and keeps retry available.
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (sending || input.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await AppServices.instance.addPostComment(widget.post, input.text);
      if (mounted) {
        input.clear();
        FocusScope.of(context).unfocus();
        await _refreshComments();
      }
    } catch (error) {
      if (mounted) _error(context, error);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Пост және пікірлер'),
      bottom: const AuthorAppBarLine(),
    ),
    body: FutureBuilder<List<PostComment>>(
      future: commentsFuture,
      builder: (context, snap) => RefreshIndicator(
        onRefresh: _refreshComments,
        child: ListView(
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClassPostCard(post: widget.post),
                  const SizedBox(height: 20),
                  Text(
                    'Пікірлер',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Пікірлер жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if ((snap.data ?? []).isEmpty)
                    const _EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Пікір жоқ',
                      subtitle: 'Алғашқы пікірді жазыңыз.',
                    )
                  else
                    ...snap.data!.map(
                      (comment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SoftCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.soft,
                                child: Text(
                                  comment.authorName.isEmpty
                                      ? '?'
                                      : comment.authorName.characters.first
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            comment.authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _shortDate(comment.createdAt),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      comment.body,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Пікір жазыңыз…',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Пікір жіберу',
                onPressed: sending ? null : _send,
                icon: sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StudentAssignmentScreen extends StatefulWidget {
  const StudentAssignmentScreen({super.key, required this.assignment});
  final LearningAssignment assignment;
  @override
  State<StudentAssignmentScreen> createState() =>
      _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final answer = TextEditingController();
  int version = 0;
  bool sending = false;
  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => sending = true);
    try {
      await AppServices.instance.submitAssignment(
        widget.assignment,
        answer.text,
      );
      if (mounted) {
        setState(() => version++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Жауап мұғалімге жіберілді')),
        );
      }
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Үй тапсырмасы'),
      bottom: const AuthorAppBarLine(),
    ),
    body: FutureBuilder<StudentSubmission?>(
      key: ValueKey(version),
      future: AppServices.instance.mySubmission(widget.assignment),
      builder: (context, snap) => ListView(
        padding: EdgeInsets.zero,
        children: [
          AdaptivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AssignmentHeader(widget.assignment),
                const SizedBox(height: 14),
                _AssignmentInstructions(widget.assignment),
                const SizedBox(height: 25),
                if (snap.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snap.hasError)
                  _EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Жауап күйі жүктелмеді',
                    subtitle: '${snap.error}',
                  )
                else if (snap.data == null) ...[
                  Text(
                    'Жауабыңызды дайындаңыз',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Теңдеуді теңестіріп, қысқаша түсіндіріңіз.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SoftCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.cyan,
                              size: 21,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Менің шешімім',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: answer,
                          minLines: 5,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            hintText:
                                'Мысалы: 2H₂ + O₂ → 2H₂O\nH: 4 = 4, O: 2 = 2',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Мұғалімге жіберу',
                    icon: Icons.send_rounded,
                    loading: sending,
                    onTap: submit,
                  ),
                ] else ...[
                  SoftCard(
                    color: snap.data!.reviewed
                        ? const Color(0xFFEAF8ED)
                        : const Color(0xFFEFF0FA),
                    child: Row(
                      children: [
                        Icon(
                          snap.data!.reviewed
                              ? Icons.verified_rounded
                              : Icons.schedule_send_rounded,
                          color: snap.data!.reviewed
                              ? AppColors.mint
                              : AppColors.violet,
                          size: 28,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snap.data!.reviewed
                                    ? 'Жауап тексерілді'
                                    : 'Жауап мұғалімге жіберілді',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                snap.data!.reviewed
                                    ? 'Мұғалімнің пікірін төменнен оқыңыз.'
                                    : 'Мұғалімнің тексеруін күтіңіз.',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              color: AppColors.cyan,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Менің жауабым',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          snap.data!.answer,
                          style: const TextStyle(
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (snap.data!.reviewed) ...[
                    const SizedBox(height: 14),
                    SoftCard(
                      color: AppColors.soft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.forum_outlined,
                                color: AppColors.cyan,
                                size: 21,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Мұғалімнің кері байланысы',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (snap.data!.score != null)
                                Text(
                                  '${snap.data!.score}/100',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            snap.data!.feedback,
                            style: const TextStyle(
                              color: AppColors.ink,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class TeacherAssignmentScreen extends StatefulWidget {
  const TeacherAssignmentScreen({super.key, required this.assignment});
  final LearningAssignment assignment;
  @override
  State<TeacherAssignmentScreen> createState() =>
      _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<TeacherAssignmentScreen> {
  int version = 0;
  Future<void> review(StudentSubmission submission) async {
    var feedback = submission.feedback;
    var score = submission.score?.toString() ?? '';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _Sheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Жауапты тексеру',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              submission.studentName,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 17),
            SoftCard(
              color: AppColors.soft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОҚУШЫ ЖАУАБЫ',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SelectableText(
                    submission.answer,
                    style: const TextStyle(color: AppColors.ink, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              initialValue: feedback,
              onChanged: (value) => feedback = value,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Оқушыға кері байланыс',
                hintText: 'Нені дұрыс орындады, нені түзету керек?',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: score,
              onChanged: (value) => score = value,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Баға (0–100) · міндетті емес',
                prefixIcon: Icon(Icons.grade_outlined),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Бағалау және жіберу',
              icon: Icons.done_rounded,
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final value = int.tryParse(score);
        if (value != null && (value < 0 || value > 100)) {
          throw Exception('Баға 0 мен 100 арасында болуы керек.');
        }
        await AppServices.instance.reviewSubmission(
          widget.assignment,
          submission,
          feedback: feedback,
          score: value,
        );
        if (mounted) setState(() => version++);
      } catch (e) {
        if (mounted) _error(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Жауаптарды тексеру'),
      bottom: const AuthorAppBarLine(),
    ),
    body: FutureBuilder<List<StudentSubmission>>(
      key: ValueKey(version),
      future: AppServices.instance.loadSubmissions(widget.assignment),
      builder: (context, snap) {
        final items = snap.data ?? [];
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            AdaptivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AssignmentHeader(widget.assignment),
                  const SizedBox(height: 14),
                  _AssignmentInstructions(widget.assignment),
                  const SizedBox(height: 25),
                  Text(
                    'Жауаптар · ${items.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${items.where((item) => item.reviewed).length} тексерілді · ${items.where((item) => !item.reviewed).length} күтуде',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snap.hasError)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Жауаптар жүктелмеді',
                      subtitle: '${snap.error}',
                    )
                  else if (items.isEmpty)
                    const _EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Жауап келмеді',
                      subtitle:
                          'Оқушылар жіберген жауаптар осында пайда болады.',
                    )
                  else
                    ...items.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () => review(s),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.soft,
                                    child: Text(
                                      s.studentName.isEmpty
                                          ? '?'
                                          : s.studentName.characters.first
                                                .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.cyan,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.studentName,
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Жіберілді · ${_shortDate(s.submittedAt)}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusChip(
                                    s.reviewed ? 'Тексерілді' : 'Жаңа',
                                    color: s.reviewed
                                        ? AppColors.mint
                                        : AppColors.coral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 13),
                              const Divider(height: 1),
                              const SizedBox(height: 11),
                              Text(
                                s.answer,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  height: 1.45,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    s.reviewed
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.rate_review_outlined,
                                    color: AppColors.cyan,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      s.reviewed
                                          ? 'Пікірді қайта қарау'
                                          : 'Жауапты тексеру',
                                      style: const TextStyle(
                                        color: AppColors.cyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.cyan,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AssignmentHeader extends StatelessWidget {
  const _AssignmentHeader(this.assignment);
  final LearningAssignment assignment;
  @override
  Widget build(BuildContext context) => GradientCard(
    padding: EdgeInsets.all(context.isCompact ? 18 : 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.science_outlined, color: Colors.white),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Text(
                'ҮЙ ТАПСЫРМАСЫ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            Icon(
              assignment.overdue
                  ? Icons.event_busy_outlined
                  : Icons.event_available_outlined,
              size: 21,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          assignment.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ТЕҢДЕУ',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  assignment.equation,
                  style: formulaStyle(
                    fontSize: 19,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                assignment.overdue
                    ? 'Мерзімі өтті · ${_shortDate(assignment.dueAt)}'
                    : 'Тапсыру мерзімі · ${_shortDate(assignment.dueAt)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AssignmentInstructions extends StatelessWidget {
  const _AssignmentInstructions(this.assignment);
  final LearningAssignment assignment;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.format_list_bulleted_rounded,
            color: AppColors.cyan,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Мұғалімнің нұсқаулығы',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                assignment.instructions.isEmpty
                    ? 'Теңдеуді теңестіріп, шешу қадамдарын көрсетіңіз.'
                    : assignment.instructions,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, {required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => SoftCard(
    color: Colors.white.withValues(alpha: .75),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppColors.violet),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: AdaptivePage(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            12,
            context.pagePadding,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

Future<String?> _textSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String action,
  TextCapitalization capitalization = TextCapitalization.sentences,
}) async {
  var value = '';
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          TextFormField(
            onChanged: (next) => value = next,
            textCapitalization: capitalization,
            decoration: InputDecoration(labelText: label, hintText: hint),
            autofocus: true,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: action,
            icon: Icons.arrow_forward_rounded,
            onTap: () => Navigator.pop(context, value.trim()),
          ),
        ],
      ),
    ),
  );
}

void _error(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
