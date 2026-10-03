import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/check_result.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';
import 'elements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenAi,
    required this.onOpenGuide,
    required this.onOpenHistory,
  });
  final void Function([String? equation]) onOpenAi;
  final VoidCallback onOpenGuide, onOpenHistory;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final history = AppServices.instance.loadHistory();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return 'Қайырлы түн';
    if (h < 12) return 'Қайырлы таң';
    if (h < 18) return 'Қайырлы күн';
    return 'Қайырлы кеш';
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'дәл қазір';
    if (d.inMinutes < 60) return '${d.inMinutes} мин бұрын';
    if (d.inHours < 24) return '${d.inHours} сағ бұрын';
    if (d.inDays < 2) return 'кеше';
    return '${d.inDays} күн бұрын';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppServices.instance;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        18,
        context.pagePadding,
        24,
      ),
      children: [
        Reveal(
          child: TagLabel(
            app.isTeacher ? 'Мұғалім кеңістігі' : 'Оқушы кеңістігі',
          ),
        ),
        const SizedBox(height: 13),
        Reveal(
          child: Text(
            '$_greeting, ${app.displayName.split(' ').first}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 6),
        Reveal(
          child: Text(
            app.isTeacher
                ? 'Бүгінгі сабаққа бірге дайындалайық.'
                : 'Бүгін бір жаңалық ашайық.',
          ),
        ),
        const SizedBox(height: 22),
        const Reveal(
          delay: Duration(milliseconds: 60),
          child: ElementHomePreview(),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: const Duration(milliseconds: 110),
          child: FutureBuilder<List<CheckResult>>(
            future: history,
            builder: (_, snap) {
              if (snap.hasError) return const SizedBox.shrink();
              final items = snap.data ?? [];
              final balanced = items.where((e) => e.isBalanced).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          value: snap.hasData ? '${items.length}' : '—',
                          label: 'Тексерілген теңдеу',
                          icon: Icons.science_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          value: snap.hasData ? '$balanced' : '—',
                          label: 'Дұрыс теңестірілген',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AccuracyBar(balanced: balanced, total: items.length),
                  ],
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _LatestCheckCard(
                      item: items.first,
                      relative: _relative(items.first.createdAt),
                      onTap: widget.onOpenHistory,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Reveal(
          delay: const Duration(milliseconds: 150),
          child: SectionHeading(
            'Бірге тексерейік',
            action: 'Тарих',
            onTap: widget.onOpenHistory,
          ),
        ),
        const SizedBox(height: 14),
        Reveal(
          delay: const Duration(milliseconds: 180),
          child: Column(
            children:
                [
                      (
                        Icons.water_drop_outlined,
                        'Судың түзілуі',
                        'H2 + O2 → H2O',
                        'Жану',
                        AppColors.mint,
                      ),
                      (
                        Icons.local_fire_department_outlined,
                        'Темірдің тотығуы',
                        'Fe + O2 → Fe2O3',
                        'Тотығу',
                        AppColors.coral,
                      ),
                      (
                        Icons.science_outlined,
                        'Бейтараптану',
                        'HCl + NaOH → NaCl + H2O',
                        'Реакция',
                        AppColors.blue,
                      ),
                    ]
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SoftCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          onTap: () => widget.onOpenAi(e.$3),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.soft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  e.$1,
                                  size: 18,
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          e.$2,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: e.$5.withValues(alpha: .12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            e.$4,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: e.$5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.$3,
                                      style: formulaStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.north_east,
                                size: 17,
                                color: AppColors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Reveal(
          delay: const Duration(milliseconds: 210),
          child: SoftCard(
            color: AppColors.soft,
            onTap: widget.onOpenGuide,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.blue,
                  size: 26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.isTeacher
                            ? 'Мұғалімнің әдістемесі'
                            : 'Өзіңді тексерудің 5 қадамы',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI жауабын қалай бағалаймыз?',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              value,
              style: formulaStyle(fontSize: 27, weight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(icon, color: AppColors.blue, size: 20),
          ],
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

/// A slim proportional bar showing balanced-vs-total across all saved
/// checks — turns the two metric cards above into one readable ratio
/// instead of two disconnected numbers.
class _AccuracyBar extends StatelessWidget {
  const _AccuracyBar({required this.balanced, required this.total});
  final int balanced, total;
  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : balanced / total;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Тепе-теңдік дәлдігі',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: formulaStyle(fontSize: 13, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio * 1000).round().clamp(0, 1000),
                    child: const ColoredBox(color: AppColors.mint),
                  ),
                  Expanded(
                    flex: 1000 - (ratio * 1000).round().clamp(0, 1000),
                    child: const ColoredBox(color: AppColors.soft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The most recent saved check, surfaced right on the home page so returning
/// is useful, not just decorative.
class _LatestCheckCard extends StatelessWidget {
  const _LatestCheckCard({
    required this.item,
    required this.relative,
    required this.onTap,
  });
  final CheckResult item;
  final String relative;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.isBalanced ? AppColors.mint : AppColors.coral,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.equation,
                overflow: TextOverflow.ellipsis,
                style: formulaStyle(fontSize: 13, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Соңғы тексеру · $relative',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
      ],
    ),
  );
}
