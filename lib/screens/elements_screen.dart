import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/chemical_element.dart';
import '../widgets/ui.dart';

class ElementHomePreview extends StatelessWidget {
  const ElementHomePreview({super.key});

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Химиялық элементтер',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '118 элемент · біреуін басып, танысыңыз',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ElementsScreen()),
              ),
              child: const Text('Барлығы'),
            ),
          ],
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 216,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: ChemicalElement.all.length,
            itemBuilder: (_, index) {
              final element = ChemicalElement.all[index];
              return ElementTile(
                element: element,
                onTap: () => showElementDetails(context, element),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        const Row(
          children: [
            Icon(Icons.swipe_rounded, size: 16, color: AppColors.muted),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                'Қалған элементтер үшін жанға сырғытыңыз',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ElementsScreen extends StatefulWidget {
  const ElementsScreen({super.key});

  @override
  State<ElementsScreen> createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen> {
  final search = TextEditingController();
  String family = 'Барлығы';

  static const families = [
    'Барлығы',
    'Бейметалл',
    'Металл',
    'Сілтілік металл',
    'Сілтілік жер металы',
    'Жартылай металл',
    'Ауыспалы металл',
    'Галоген',
    'Инертті газ',
    'Лантаноид',
    'Актиноид',
    'Жасанды аса ауыр элемент',
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final items = ChemicalElement.all.where((element) {
      final matchesFamily = family == 'Барлығы' || element.family == family;
      final matchesQuery =
          query.isEmpty ||
          '${element.name} ${element.englishName} ${element.symbol} ${element.number}'
              .toLowerCase()
              .contains(query);
      return matchesFamily && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Химиялық элементтер'),
        bottom: const AuthorAppBarLine(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.pagePadding,
                    18,
                    context.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '118 элемент',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const Icon(
                            Icons.science_rounded,
                            color: AppColors.cyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Элементті таңдасаңыз, оның қасиеттері ашылады.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Атауы, таңбасы немесе нөмірі',
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
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: families.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 7),
                          itemBuilder: (_, index) {
                            final value = families[index];
                            return ChoiceChip(
                              label: Text(value),
                              selected: family == value,
                              onSelected: (_) => setState(() => family = value),
                              showCheckmark: false,
                              selectedColor: AppColors.blue,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: family == value
                                    ? Colors.white
                                    : AppColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              side: BorderSide(
                                color: family == value
                                    ? AppColors.blue
                                    : AppColors.line,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        '${items.length} элемент көрсетілді',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Элемент табылмады.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final count = constraints.maxWidth < 360
                                ? 3
                                : constraints.maxWidth < 650
                                ? 4
                                : constraints.maxWidth < 800
                                ? 6
                                : 8;
                            return GridView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                context.pagePadding,
                                0,
                                context.pagePadding,
                                24,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: count,
                                    crossAxisSpacing: 9,
                                    mainAxisSpacing: 9,
                                    childAspectRatio: .92,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (_, index) => ElementTile(
                                element: items[index],
                                onTap: () =>
                                    showElementDetails(context, items[index]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _elementColor(ChemicalElement element) => switch (element.family) {
  'Бейметалл' => AppColors.mint,
  'Галоген' => AppColors.coral,
  'Инертті газ' => AppColors.violet,
  'Сілтілік металл' => AppColors.accentDeep,
  'Сілтілік жер металы' => AppColors.cyan,
  'Лантаноид' || 'Актиноид' => AppColors.violet,
  _ => AppColors.blue,
};

class ElementTile extends StatelessWidget {
  const ElementTile({super.key, required this.element, required this.onTap});

  final ChemicalElement element;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _elementColor(element);
    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: .32)),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${element.number}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    element.symbol,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: context.isCompact ? 23 : 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Text(
                element.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showElementDetails(BuildContext context, ChemicalElement element) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Жабу',
    barrierColor: Colors.black.withValues(alpha: .20),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: .94, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (dialogContext, _, _) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight:
                    MediaQuery.sizeOf(dialogContext).height *
                    (MediaQuery.sizeOf(dialogContext).height < 700 ? .92 : .86),
              ),
              child: _ElementDetails(element: element),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ElementDetails extends StatelessWidget {
  const _ElementDetails({required this.element});

  final ChemicalElement element;

  @override
  Widget build(BuildContext context) {
    final color = _elementColor(element);
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(22, 10, 22, compact ? 14 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: .85), color],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ЭЛЕМЕНТ №${element.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Жабу',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: Container(
                            width: compact ? 72 : 100,
                            height: compact ? 72 : 100,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .7),
                              ),
                            ),
                            child: Text(
                              element.symbol,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 37 : 47,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 14),
                        Center(
                          child: Text(
                            element.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 20 : 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Center(
                          child: Text(
                            element.englishName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: 'Тобы', value: element.family),
                        _DetailRow(label: 'Период', value: '${element.period}'),
                        _DetailRow(
                          label: 'Топ нөмірі',
                          value: element.group == null
                              ? 'f-блок'
                              : '${element.group}',
                        ),
                        _DetailRow(
                          label: 'Бөлме температурасында',
                          value: element.stateAtRoomTemperature,
                        ),
                        _DetailRow(
                          label: element.hasStandardAtomicWeight
                              ? 'Атомдық масса'
                              : 'Изотоптың массалық саны',
                          value: element.displayedWeight,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.soft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Бейтарап атомда ${element.number} протон және ${element.number} электрон бар.',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 9 : 14),
                        Text(
                          'Қызықты дерек',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          element.fact,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PrimaryButton(
              label: 'Таңбаны көшіру',
              icon: Icons.copy_rounded,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: element.symbol));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${element.symbol} таңбасы көшірілді'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.sizeOf(context).height < 700 ? 8 : 12,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
