import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/check_result.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';
import '../widgets/ai_answer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<CheckResult>> future;
  int filter = 0;
  String query = '';
  final Set<String> deleting = {};
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = AppServices.instance.loadHistory();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final next = AppServices.instance.loadHistory();
    setState(() {
      future = next;
    });
    await next;
  }

  Future<bool> _confirmDelete(CheckResult item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нәтижені жою'),
        content: Text('«${item.equation}» тексеруін жою керек пе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бас тарту'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Жою'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> remove(CheckResult item) async {
    if (!await _confirmDelete(item) || !mounted) return;
    setState(() => deleting.add(item.id));
    try {
      await AppServices.instance.deleteHistory(item.id);
      if (mounted) await reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Жою орындалмады. Қайта көріңіз.')),
        );
      }
    } finally {
      if (mounted) setState(() => deleting.remove(item.id));
    }
  }

  String _groupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Бүгін';
    if (diff == 1) return 'Кеше';
    if (diff <= 7) return 'Осы аптада';
    return 'Бұрынғы тексерулер';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      bottom: const AuthorAppBarLine(),
      title: const Text(
        'AI нәтижелері',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    body: FutureBuilder<List<CheckResult>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }
        if (snap.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Жүктелмеді. Қайта көру'),
            ),
          );
        }
        final all = snap.data ?? [];
        final searched = query.trim().isEmpty
            ? all
            : all
                  .where(
                    (e) => e.equation.toLowerCase().contains(
                      query.trim().toLowerCase(),
                    ),
                  )
                  .toList();
        final balancedCount = searched.where((e) => e.isBalanced).length;
        final items = searched
            .where(
              (e) =>
                  filter == 0 || (filter == 1 ? e.isBalanced : !e.isBalanced),
            )
            .toList();

        // Build a flat widget list with a date-group label inserted whenever
        // the group changes, so the history reads like a lab notebook rather
        // than one undifferentiated stack of cards.
        final cards = <Widget>[];
        String? lastGroup;
        for (final item in items) {
          final group = _groupLabel(item.createdAt);
          if (group != lastGroup) {
            cards.add(
              Padding(
                padding: EdgeInsets.only(
                  top: lastGroup == null ? 0 : 10,
                  bottom: 12,
                ),
                child: Text(
                  group,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            );
            lastGroup = group;
          }
          cards.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(
                item: item,
                busy: deleting.contains(item.id),
                onDelete: () => remove(item),
                onTap: () async {
                  final deleted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => ResultDetail(item: item),
                    ),
                  );
                  if (deleted == true && mounted) await reload();
                },
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(context.pagePadding),
            children: [
              Text(
                'Сіздің ізденіс\nкүнделігіңіз.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('${all.length} сақталған тексеру'),
              const SizedBox(height: 18),
              TextField(
                controller: searchCtrl,
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Теңдеуден іздеу…',
                  prefixIcon: const Icon(Icons.search, size: 19),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 17),
                          onPressed: () {
                            searchCtrl.clear();
                            setState(() => query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children:
                    [
                          ('Барлығы', searched.length),
                          ('Тең', balancedCount),
                          ('Тең емес', searched.length - balancedCount),
                        ]
                        .asMap()
                        .entries
                        .map(
                          (e) => ChoiceChip(
                            label: Text(
                              '${e.value.$1} · ${e.value.$2}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: filter == e.key,
                            showCheckmark: false,
                            selectedColor: AppColors.accent,
                            onSelected: (_) => setState(() => filter = e.key),
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 22),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const BalanceScaleArt(size: 92),
                      const SizedBox(height: 18),
                      Text(
                        all.isEmpty
                            ? 'Алғашқы теңдеуден бастайық'
                            : query.isNotEmpty
                            ? 'Іздеу бойынша нәтиже жоқ'
                            : 'Бұл санатта нәтиже жоқ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI бөліміндегі тексерулер\nосы жерде сақталады.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ...cards,
            ],
          ),
        );
      },
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.busy,
    required this.onDelete,
    required this.onTap,
  });
  final CheckResult item;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = item.isBalanced ? AppColors.mint : AppColors.coral;
    return SoftCard(
      padding: const EdgeInsets.all(17),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isBalanced
                          ? Icons.check_circle_outline
                          : Icons.balance,
                      size: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isBalanced ? 'Атомдар саны тең' : 'Теңестіру қажет',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              busy
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: onDelete,
                      tooltip: 'Жою',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 17,
                        color: AppColors.muted,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.equation,
            style: formulaStyle(fontSize: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Text(
                '${item.createdAt.day.toString().padLeft(2, '0')}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.year}',
                style: const TextStyle(fontSize: 10),
              ),
              const Spacer(),
              const Text(
                'Толығырақ',
                style: TextStyle(fontSize: 10, color: AppColors.blue),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 14, color: AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultDetail extends StatefulWidget {
  const ResultDetail({super.key, required this.item});
  final CheckResult item;
  @override
  State<ResultDetail> createState() => _ResultDetailState();
}

class _ResultDetailState extends State<ResultDetail> {
  bool deleting = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.item.equation));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Теңдеу көшірілді')));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нәтижені жою'),
        content: Text('«${widget.item.equation}» тексеруін жою керек пе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Бас тарту'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Жою'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await AppServices.instance.deleteHistory(widget.item.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Жою орындалмады. Қайта көріңіз.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.isBalanced ? AppColors.mint : AppColors.coral;
    return Scaffold(
      appBar: AppBar(
        bottom: const AuthorAppBarLine(),
        title: const Text('Тексеру нәтижесі', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            onPressed: deleting ? null : _delete,
            tooltip: 'Жою',
            icon: deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isBalanced
                          ? Icons.check_circle_outline
                          : Icons.balance,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.isBalanced ? 'Атомдар саны тең' : 'Теңестіру қажет',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${item.createdAt.day.toString().padLeft(2, '0')}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SoftCard(
            color: AppColors.soft,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    item.equation,
                    style: formulaStyle(
                      fontSize: 21,
                      weight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copy,
                  tooltip: 'Теңдеуді көшіру',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const TagLabel('AI түсіндірмесі', color: AppColors.mint),
          const SizedBox(height: 14),
          AiAnswer(item.answer),
        ],
      ),
    );
  }
}
