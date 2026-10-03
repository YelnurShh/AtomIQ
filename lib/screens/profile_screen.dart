import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/lesson_curriculum.dart';
import '../models/practice.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onSignedOut,
    required this.onUpdated,
    required this.onOpenGuide,
    required this.onAppBarVisibilityChanged,
  });

  final VoidCallback onSignedOut, onUpdated, onOpenGuide;
  final ValueChanged<bool> onAppBarVisibilityChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileOverview> overview;

  @override
  void initState() {
    super.initState();
    overview = AppServices.instance.loadProfileOverview();
  }

  Future<void> _refresh() async {
    final next = AppServices.instance.loadProfileOverview();
    setState(() {
      overview = next;
    });
    try {
      await next;
    } catch (_) {
      // The retry card shows the error without turning a pull gesture into a crash.
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (updated == true && mounted) {
      await _refresh();
      if (mounted) widget.onUpdated();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Аккаунттан шығу'),
        content: const Text('Сақталған нәтижелеріңіз аккаунтта қалады.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Қалу'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Шығу'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppServices.instance.signOut();
      if (mounted) widget.onSignedOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Шығу орындалмады. Қайта көріңіз.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          if (notification.direction == ScrollDirection.reverse) {
            widget.onAppBarVisibilityChanged(false);
          } else if (notification.direction == ScrollDirection.forward) {
            widget.onAppBarVisibilityChanged(true);
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<ProfileOverview>(
            future: overview,
            builder: (context, snapshot) {
              final cached = AppServices.instance;
              final data = snapshot.data;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileHero(
                    name: data?.name ?? cached.displayName,
                    email: data?.email ?? cached.email,
                    school: data?.school ?? cached.school,
                    role: data?.roleLabel ?? cached.roleLabel,
                    isTeacher: data?.isTeacher ?? cached.isTeacher,
                    onEdit: _edit,
                  ),
                  AdaptivePage(
                    padding: EdgeInsets.fromLTRB(
                      context.pagePadding,
                      24,
                      context.pagePadding,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (snapshot.hasError)
                          _LoadError(onRetry: _refresh)
                        else if (data == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 54),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          Text(
                            'Менің көрсеткіштерім',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: data.isTeacher
                                      ? Icons.groups_2_outlined
                                      : Icons.menu_book_outlined,
                                  value: data.isTeacher
                                      ? '${data.classesCount}'
                                      : '${data.theoryCompleted}',
                                  label: data.isTeacher ? 'Сынып' : 'Сабақ',
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: _StatTile(
                                  icon: data.isTeacher
                                      ? Icons.menu_book_outlined
                                      : Icons.science_outlined,
                                  value: data.isTeacher
                                      ? '${data.theoryCompleted}'
                                      : '${data.practiceCompleted}',
                                  label: data.isTeacher ? 'Сабақ' : 'Практика',
                                  color: AppColors.mint,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: _StatTile(
                                  icon: data.isTeacher
                                      ? Icons.fact_check_outlined
                                      : Icons.groups_2_outlined,
                                  value: data.isTeacher
                                      ? '${data.checksCount}'
                                      : '${data.classesCount}',
                                  label: data.isTeacher ? 'Тексеру' : 'Сынып',
                                  color: AppColors.violet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _LearningProgress(overview: data),
                          const SizedBox(height: 24),
                          Text(
                            'Аккаунт',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _AccountCard(overview: data),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Баптаулар',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _ActionRow(
                          icon: Icons.edit_outlined,
                          title: 'Профильді өңдеу',
                          subtitle: 'Аты-жөні мен оқу орнын өзгерту',
                          onTap: _edit,
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.menu_book_outlined,
                          title: data?.isTeacher ?? cached.isTeacher
                              ? 'Мұғалімге арналған әдістеме'
                              : 'Өзін-өзі тексеру әдістемесі',
                          subtitle: 'Қосымшаны қолдану нұсқаулығы',
                          onTap: widget.onOpenGuide,
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          title: 'Аккаунттан шығу',
                          subtitle: 'Нәтижелеріңіз сақталады',
                          onTap: _logout,
                          destructive: true,
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'AtomIQ · 1.1',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
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
        ),
      ),
    ),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.school,
    required this.role,
    required this.isTeacher,
    required this.onEdit,
  });

  final String name, email, school, role;
  final bool isTeacher;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        safeTop + 24,
        context.pagePadding,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.contentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: context.isCompact ? 68 : 76,
                    height: context.isCompact ? 68 : 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: .12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: context.isCompact ? 30 : 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: context.isCompact ? 18 : 21,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .82),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Профильді өңдеу',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    icon: isTeacher
                        ? Icons.co_present_rounded
                        : Icons.school_rounded,
                    text: role,
                  ),
                  if (school.trim().isNotEmpty)
                    _HeroPill(icon: Icons.location_city_outlined, text: school),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxWidth: context.screenSize.width - 2 * context.pagePadding,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: Column(
      children: [
        Icon(icon, size: 21, color: color),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: context.isCompact ? 17 : 19,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _LearningProgress extends StatelessWidget {
  const _LearningProgress({required this.overview});
  final ProfileOverview overview;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.cyan,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Оқу барысы',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ProgressLine(
          label: 'Теория',
          value: overview.theoryCompleted,
          total: CurriculumCatalog.theory.length,
          color: AppColors.blue,
        ),
        const SizedBox(height: 17),
        _ProgressLine(
          label: 'Практика',
          value: overview.practiceCompleted,
          total: CurriculumCatalog.practice.length,
          color: AppColors.mint,
        ),
        const SizedBox(height: 17),
        _ProgressLine(
          label: 'Коэффициент жаттығуы',
          value: overview.formulasCompleted,
          total: PracticeCatalog.tasks.length,
          color: AppColors.violet,
        ),
      ],
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
  final String label;
  final int value, total;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '$value / $total',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : (value / total).clamp(0.0, 1.0),
          minHeight: 7,
          backgroundColor: AppColors.soft,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.overview});
  final ProfileOverview overview;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        _AccountLine(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: overview.email,
        ),
        const Divider(height: 1),
        _AccountLine(
          icon: Icons.badge_outlined,
          label: 'Рөл',
          value: overview.roleLabel,
        ),
        if (overview.school.trim().isNotEmpty) ...[
          const Divider(height: 1),
          _AccountLine(
            icon: Icons.apartment_rounded,
            label: 'Оқу орны',
            value: overview.school,
          ),
        ],
      ],
    ),
  );
}

class _AccountLine extends StatelessWidget {
  const _AccountLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 18),
        const SizedBox(width: 11),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.coral : AppColors.cyan;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: destructive ? color : AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SoftCard(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 30),
        const SizedBox(height: 10),
        const Text(
          'Профиль жүктелмеді',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Firestore қосылымын тексеріп, қайта көріңіз.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Қайта жүктеу'),
        ),
      ],
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final name = TextEditingController(text: AppServices.instance.displayName);
  final school = TextEditingController(text: AppServices.instance.school);
  bool saving = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    school.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await AppServices.instance.updateProfile(name.text, school.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Профильді өңдеу', style: TextStyle(fontSize: 17)),
    ),
    body: ListView(
      children: [
        AdaptivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Деректеріңізді жаңартыңыз',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Өзгерістер аккаунтыңызда сақталады.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Жеке ақпарат',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Аты-жөніңіз',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: school,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Мектеп / оқу орны',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Рөліңіз: ${AppServices.instance.roleLabel}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (error != null) ...[
                const SizedBox(height: 15),
                SoftCard(
                  color: AppColors.coral.withValues(alpha: .08),
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.coral),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Өзгерістерді сақтау',
                loading: saving,
                onTap: save,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
