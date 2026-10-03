import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_services.dart';
import '../services/auth_errors.dart';
import '../widgets/ui.dart';
import 'main.dart';
import 'complete_profile_screen.dart';

class LaunchFlow extends StatefulWidget {
  const LaunchFlow({super.key});
  @override
  State<LaunchFlow> createState() => _LaunchFlowState();
}

class _LaunchFlowState extends State<LaunchFlow> {
  bool splash = true;
  bool onboardingSeenThisLaunch = false;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return const SplashScreen();
    }
    if (!onboardingSeenThisLaunch) {
      return OnboardingScreen(
        onDone: () => setState(() => onboardingSeenThisLaunch = true),
      );
    }
    if (AppServices.instance.startupError != null) {
      return _ConnectionError(
        onRetry: () async {
          await AppServices.instance.initialize();
          if (mounted) setState(() {});
        },
      );
    }
    if (AppServices.instance.needsProfile) {
      return CompleteProfileScreen(onDone: () => setState(() {}));
    }
    if (!AppServices.instance.isSignedIn) {
      return AuthScreen(onDone: () => setState(() {}));
    }
    return MainShell(onSignedOut: () => setState(() {}));
  }
}

class _ConnectionError extends StatefulWidget {
  const _ConnectionError({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  State<_ConnectionError> createState() => _ConnectionErrorState();
}

class _ConnectionErrorState extends State<_ConnectionError> {
  bool loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppColors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                AppServices.instance.startupError ?? 'Қосылым қатесі',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Қайта қосылу',
                loading: loading,
                onTap: () async {
                  setState(() => loading = true);
                  await widget.onRetry();
                  if (mounted) setState(() => loading = false);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Image.asset(
        'assets/images/app_icon.png',
        width: MediaQuery.sizeOf(context).width.clamp(0, 220) * .82,
        height: MediaQuery.sizeOf(context).width.clamp(0, 220) * .82,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const pages = [
    (
      'Химияны жаңа\nқырынан түсініңіз.',
      'AI көмегімен теңдеулерді қадамдап тексеріп, атомдардың балансын бірден көріңіз.',
    ),
    (
      'Сынып әрдайым\nбайланыста.',
      'Мұғалім тапсырма береді, оқушы жауабын жібереді және жеке кері байланыс алады.',
    ),
    (
      'Әр рөлге —\nөз кеңістігі.',
      'Оқушыға AI есеп шығарушы, мұғалімге сынып пен бағалау панелі. Барлығы түсінікті әрі жылдам.',
    ),
  ];
  void finish() => widget.onDone();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 680;
    final portraitSpace = (size.height * (context.isTablet ? .40 : .35) + 22)
        .clamp(175.0, context.isTablet ? 430.0 : 330.0)
        .toDouble();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: .78,
            child: Image.asset(
              'assets/images/teacher_onboarding.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xB3162033),
                  Color(0xE6162033),
                ],
                stops: [0.0, .38, .56, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.pagePadding,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const BrandMark(size: 38),
                          const SizedBox(width: 10),
                          const Text(
                            'AtomIQ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: finish,
                            child: const Text(
                              'Өткізу',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: pages.length,
                        onPageChanged: (i) => setState(() => page = i),
                        itemBuilder: (_, i) => SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            context.pagePadding,
                            compact ? 4 : 14,
                            context.pagePadding,
                            16,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: portraitSpace),
                              Column(
                                children: [
                                  Text(
                                    pages[i].$1,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: context.isCompact ? 23 : 27,
                                          height: 1.18,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 38,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    pages[i].$2,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: const Color(0xF2FFFFFF),
                                          fontSize: context.isCompact ? 13 : 14,
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.pagePadding,
                        8,
                        context.pagePadding,
                        18,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (i) => Container(
                                width: page == i ? 18 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: page == i
                                      ? Colors.white
                                      : const Color(0x80FFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          PrimaryButton(
                            label: page == 2 ? 'Бастау' : 'Келесі',
                            icon: Icons.arrow_forward_rounded,
                            onTap: () {
                              if (page == 2) {
                                finish();
                              } else {
                                controller.jumpToPage(page + 1);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController(),
      school = TextEditingController();
  bool register = false, loading = false, hide = true;
  AccountRole role = AccountRole.student;
  String? error;
  @override
  void dispose() {
    for (final c in [name, email, password, code, school]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (register) {
        await AppServices.instance.register(
          name.text,
          email.text,
          password.text,
          role: role,
          teacherCode: code.text,
          school: school.text,
        );
      } else {
        await AppServices.instance.signIn(email.text, password.text);
      }
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => error = _authError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> googleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final signedIn = await AppServices.instance.signInWithGoogle();
      if (mounted && signedIn) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _authError(Object e) {
    return authErrorMessage(e);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.pagePadding),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BrandMark(size: 42),
                      SizedBox(width: 12),
                      Text(
                        'AtomIQ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  Text(
                    register ? 'Білімге бір\nқадам жақын.' : 'Қош\nкелдіңіз!',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    register
                        ? 'Өзіңізге лайық кеңістікті таңдаңыз.'
                        : 'Жеке зертханаңызға кіріңіз.',
                  ),
                  const SizedBox(height: 26),
                  if (AppServices.instance.firebaseReady) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : googleSignIn,
                        icon: Image.asset(
                          'assets/images/google_g.png',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text(
                          'Google арқылы жалғастыру',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F1F1F),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1F1F1F),
                          side: const BorderSide(color: Color(0xFF747775)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'немесе email арқылы',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                  ],
                  if (register) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _RoleTile(
                            label: 'Оқушы',
                            icon: Icons.school_outlined,
                            selected: role == AccountRole.student,
                            onTap: loading
                                ? null
                                : () => setState(
                                    () => role = AccountRole.student,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleTile(
                            label: 'Мұғалім',
                            icon: Icons.co_present_outlined,
                            selected: role == AccountRole.teacher,
                            onTap: loading
                                ? null
                                : () => setState(
                                    () => role = AccountRole.teacher,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: name,
                      enabled: !loading,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Аты-жөніңіз',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Аты-жөніңізді енгізіңіз'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: school,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Мектеп / оқу орны',
                        hintText: 'Міндетті емес',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: email,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email, size: 20),
                    ),
                    validator: (v) =>
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v?.trim() ?? '')
                        ? 'Email дұрыс жазылмаған'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    enabled: !loading,
                    obscureText: hide,
                    decoration: InputDecoration(
                      labelText: 'Құпиясөз',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hide = !hide),
                        tooltip: 'Құпиясөзді көрсету',
                        icon: Icon(
                          hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) < (register ? 8 : 6)
                        ? 'Кемінде ${register ? 8 : 6} таңба енгізіңіз'
                        : null,
                  ),
                  if (register && role == AccountRole.teacher) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: code,
                      enabled: !loading,
                      obscureText: true,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Мұғалімнің арнайы коды',
                        prefixIcon: Icon(Icons.key_outlined, size: 20),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Әкімші берген кодты енгізіңіз'
                          : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Арнайы кодты жоба әкімшісінен алыңыз.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                  if (!register && AppServices.instance.firebaseReady)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () async {
                                try {
                                  await AppServices.instance.resetPassword(
                                    email.text,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Қалпына келтіру хаты email-ге жіберілді.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => error = _authError(e));
                                  }
                                }
                              },
                        child: const Text(
                          'Құпиясөзді ұмыттыңыз ба?',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: register ? 'Аккаунт ашу' : 'Кіру',
                    icon: Icons.arrow_forward,
                    loading: loading,
                    onTap: submit,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                              register = !register;
                              error = null;
                              form.currentState?.reset();
                            }),
                      child: Text(
                        register ? 'Аккаунтым бар · Кіру' : 'Жаңа аккаунт ашу',
                      ),
                    ),
                  ),
                  if (!AppServices.instance.firebaseReady)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Сынақ режимі: аккаунт пен нәтижелер осы құрылғыда сақталады.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  const SizedBox(height: 26),
                  const Center(child: AuthorPill()),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.soft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.blue : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.blue : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.blue : AppColors.ink,
                    fontSize: 12,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, size: 16, color: AppColors.blue),
            ],
          ),
        ),
      ),
    ),
  );
}
