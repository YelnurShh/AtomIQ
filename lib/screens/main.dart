import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_services.dart';
import '../widgets/ui.dart';
import 'ai_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'guide_profile_screen.dart';
import 'learning_screen.dart';
import 'lessons_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.onSignedOut});
  final VoidCallback onSignedOut;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0, historyVersion = 0;
  bool profileAppBarVisible = true;
  final aiKey = GlobalKey<AiScreenState>();

  void setProfileAppBarVisible(bool visible) {
    if (profileAppBarVisible == visible) return;
    setState(() => profileAppBarVisible = visible);
  }

  void openAi([String? equation]) {
    setState(() => index = 2);
    if (equation != null) aiKey.currentState?.prefill(equation);
  }

  void openGuide() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const GuideScreen()));
  @override
  Widget build(BuildContext context) {
    final teacher = AppServices.instance.isTeacher;
    final isProfile = index == 4;
    final hideProfileAppBar = isProfile && !profileAppBarVisible;
    final appBarAnimationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final titles = teacher
        ? ['Мұғалім панелі', 'Сыныптар', 'AI көмекші', 'Сабақтар', 'Профиль']
        : ['Оқу панелі', 'Тапсырмалар', 'AI көмекші', 'Сабақтар', 'Профиль'];
    final subtitles = teacher
        ? [
            'Сабақты басқару',
            'Тапсырма және кері байланыс',
            'Сабаққа көмекші',
            'Қадамдап үйрену',
            'Жеке кеңістік',
          ]
        : [
            'Бүгінгі жоспар',
            'Орындау және нәтиже',
            'Химияны түсіну',
            'Қадамдап үйрену',
            'Жеке кеңістік',
          ];
    return Scaffold(
      extendBodyBehindAppBar: isProfile,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isProfile ? 88 : 124),
        child: IgnorePointer(
          ignoring: hideProfileAppBar,
          child: AnimatedSlide(
            offset: hideProfileAppBar ? const Offset(0, -1.15) : Offset.zero,
            duration: appBarAnimationDuration,
            curve: const Cubic(.22, 1, .36, 1),
            child: AnimatedOpacity(
              opacity: hideProfileAppBar ? 0 : 1,
              duration: appBarAnimationDuration,
              curve: Curves.easeOut,
              child: AppBar(
                toolbarHeight: 88,
                bottom: isProfile
                    ? null
                    : const AuthorAppBarLine(onBrand: true),
                titleSpacing: context.pagePadding,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(isProfile ? 0 : 28),
                  ),
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: isProfile ? null : AppColors.primaryGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(isProfile ? 0 : 28),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    const BrandMark(size: 40, onBrand: true),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[index],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitles[index],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index == 2)
                      IconButton.filledTonal(
                        onPressed: () => aiKey.currentState?.newChat(),
                        tooltip: 'Жаңа чат',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_comment_outlined, size: 20),
                      ),
                    if (index == 0) ...[
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                HistoryScreen(key: ValueKey(historyVersion)),
                          ),
                        ),
                        tooltip: 'AI нәтижелері',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.history_rounded, size: 21),
                      ),
                      InkWell(
                        onTap: () => setState(() {
                          index = 4;
                          profileAppBarVisible = true;
                        }),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(
                              alpha: .18,
                            ),
                            child: Text(
                              AppServices.instance.displayName.characters.first
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: GridBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isTablet ? 900 : double.infinity,
            ),
            child: IndexedStack(
              index: index,
              children:
                  [
                        RoleDashboard(
                          key: ValueKey('dashboard_$historyVersion'),
                          onOpenLearning: () => setState(() => index = 1),
                          onOpenAi: openAi,
                          onOpenLessons: () => setState(() => index = 3),
                        ),
                        const LearningHubScreen(),
                        AiScreen(
                          key: aiKey,
                          onSaved: () => setState(() => historyVersion++),
                        ),
                        const LessonsScreen(),
                        if (index == 4)
                          ProfileScreen(
                            onSignedOut: widget.onSignedOut,
                            onUpdated: () => setState(() {}),
                            onOpenGuide: openGuide,
                            onAppBarVisibilityChanged: setProfileAppBarVisible,
                          )
                        else
                          const SizedBox.shrink(),
                      ]
                      .asMap()
                      .entries
                      .map(
                        (entry) => TickerMode(
                          enabled: entry.key == index,
                          child: entry.value,
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ),
      // Always visible: this bar must stay docked above the keyboard in the AI
      // chat screen rather than disappearing while the person is typing.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .06),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: List.generate(5, (i) {
                final icons = teacher
                    ? [
                        Icons.space_dashboard_rounded,
                        Icons.groups_2_outlined,
                        Icons.auto_awesome_outlined,
                        Icons.menu_book_outlined,
                        Icons.person_outline_rounded,
                      ]
                    : [
                        Icons.space_dashboard_rounded,
                        Icons.assignment_outlined,
                        Icons.auto_awesome_outlined,
                        Icons.menu_book_outlined,
                        Icons.person_outline_rounded,
                      ];
                final labels = teacher
                    ? ['Шолу', 'Сыныптар', 'AI көмекші', 'Сабақтар', 'Профиль']
                    : [
                        'Шолу',
                        'Тапсырмалар',
                        'AI көмекші',
                        'Сабақтар',
                        'Профиль',
                      ];
                final visibleLabels = teacher
                    ? ['Шолу', 'Сынып', 'AI', 'Сабақ', 'Профиль']
                    : ['Шолу', 'Тапсырма', 'AI', 'Сабақ', 'Профиль'];
                return Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: labels[i],
                    child: InkWell(
                      onTap: () => setState(() {
                        index = i;
                        if (i == 4) profileAppBarVisible = true;
                      }),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: Duration(
                                milliseconds:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? 0
                                    : 160,
                              ),
                              curve: const Cubic(.23, 1, .32, 1),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.isCompact ? 12 : 18,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: i == index
                                    ? AppColors.blue
                                    : i == 2
                                    ? AppColors.soft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icons[i],
                                size: 21,
                                color: i == index
                                    ? Colors.white
                                    : i == 2
                                    ? AppColors.cyan
                                    : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              visibleLabels[i],
                              style: TextStyle(
                                fontSize: context.isCompact ? 9 : 11,
                                fontWeight: i == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == index
                                    ? AppColors.cyan
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
