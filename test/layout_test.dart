import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/screens/launch_flow.dart';
import 'package:chem_balance_ai/screens/main.dart';
import 'package:chem_balance_ai/screens/history_screen.dart';
import 'package:chem_balance_ai/screens/learning_screen.dart';
import 'package:chem_balance_ai/screens/elements_screen.dart';
import 'package:chem_balance_ai/models/learning.dart';
import 'package:chem_balance_ai/models/lesson_curriculum.dart';
import 'package:chem_balance_ai/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppServices.instance.prefs = await SharedPreferences.getInstance();
    AppServices.instance.firebaseReady = false;
    AppServices.instance.allowLocalDemo = true;
    await AppServices.instance.signOut();
    final loader = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('splash shows only the new logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
    );
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'assets/images/app_icon.png');
    expect(find.byType(Text), findsNothing);
    expect(find.byType(Lottie), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small screen registration exposes teacher code only for teacher role',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AuthScreen(onDone: () {}),
        ),
      );
      await tester.ensureVisible(find.text('Жаңа аккаунт ашу'));
      await tester.tap(find.text('Жаңа аккаунт ашу'));
      await tester.pump();
      await tester.ensureVisible(find.text('Мұғалім'));
      await tester.tap(find.text('Мұғалім'));
      await tester.pump();
      expect(find.text('Мұғалімнің арнайы коды'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Оқушы'));
      await tester.pump();
      expect(find.text('Мұғалімнің арнайы коды'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('onboarding adapts to compact phone and tablet', (tester) async {
    for (final size in [const Size(320, 568), const Size(800, 1024)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: OnboardingScreen(onDone: () {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('AtomIQ'), findsOneWidget);
      expect(find.byType(Lottie), findsNothing);
      expect(
        tester.getTopLeft(find.text('Химияны жаңа\nқырынан түсініңіз.')).dy,
        greaterThan(size.height * .42),
      );
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('onboarding keeps the portrait clear and text below it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(onDone: () {}),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/teacher_onboarding.png'),
        tester.element(find.byType(OnboardingScreen)),
      );
    });
    await tester.pumpAndSettle();
    expect(find.byType(Lottie), findsNothing);
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('previews/onboarding.png'),
    );
    await tester.tap(find.text('Келесі'));
    await tester.pump();
    expect(find.text('Сынып әрдайым\nбайланыста.'), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding appears at every fresh app launch', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    AppServices.instance.prefs = await SharedPreferences.getInstance();

    Future<void> launch() async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const LaunchFlow()),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/teacher_onboarding.png')),
        findsOneWidget,
      );
    }

    await launch();
    await tester.tap(find.text('Өткізу'));
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await launch();
  });

  testWidgets('teacher and student navigation are distinct', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await AppServices.instance.register(
      'Мұғалім',
      'teacher@layout.kz',
      'password1',
      role: AccountRole.teacher,
      teacherCode: AppServices.teacherRegistrationCode,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MainShell(onSignedOut: () {}),
      ),
    );
    await tester.pump();
    expect(find.text('Сынып'), findsWidgets);
    expect(find.text('Тапсырмалар'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Тексеруді күтуде'), findsOneWidget);
    expect(find.text('Өтілген сабақ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google button uses the official color asset', (tester) async {
    AppServices.instance.firebaseReady = true;
    addTearDown(() => AppServices.instance.firebaseReady = false);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AuthScreen(onDone: () {}),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/google_g.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('history search has a Material surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const HistoryScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('AI нәтижелері'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('class sheet closes without a disposed text controller', (
    tester,
  ) async {
    await AppServices.instance.register(
      'Мұғалім',
      'teacher@sheet.kz',
      'password1',
      role: AccountRole.teacher,
      teacherCode: AppServices.teacherRegistrationCode,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: LearningHubScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Жаңа сынып ашыңыз'));
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    await tester.enterText(field, '9A · Химия');
    Navigator.of(tester.element(field)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('main pages and profile edit fit a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await AppServices.instance.register(
      'Аружан',
      'layout@test.kz',
      'password1',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MainShell(onSignedOut: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MainShell),
      matchesGoldenFile('previews/home.png'),
    );
    expect(find.text('Химиялық элементтер'), findsOneWidget);
    await tester.tap(find.byType(ElementTile).first);
    await tester.pumpAndSettle();
    expect(find.text('ЭЛЕМЕНТ №1'), findsOneWidget);
    await tester.tap(find.byTooltip('Жабу'));
    await tester.pumpAndSettle();
    expect(find.text('Тапсырма'), findsOneWidget);
    expect(find.text('Сыныптар'), findsNothing);
    for (final label in ['AI', 'Тапсырма', 'Профиль']) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      if (label == 'AI') {
        await expectLater(
          find.byType(MainShell),
          matchesGoldenFile('previews/ai_chat.png'),
        );
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Аружан'), findsWidgets);
    expect(find.text('Менің көрсеткіштерім'), findsOneWidget);
    expect(find.text('Оқу барысы'), findsOneWidget);
    expect(find.text('Дәлдік'), findsNothing);
    await expectLater(
      find.byType(MainShell),
      matchesGoldenFile('previews/profile.png'),
    );
    await AppServices.instance.saveLessonCompletion('atoms_molecules', 0);
    await tester.tap(find.text('Сабақ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(find.text('1 / ${CurriculumCatalog.theory.length}'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).first, 'Айгерім');
    await tester.tap(find.text('Өзгерістерді сақтау'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(AppServices.instance.displayName, 'Айгерім');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('lessons tab opens on a narrow phone and tablet', (tester) async {
    await AppServices.instance.register(
      'Аружан',
      'lessons-nav@test.kz',
      'password1',
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(320, 640), const Size(800, 1024)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MainShell(onSignedOut: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Өтілген сабақ'), findsOneWidget);
      expect(find.text('0/${CurriculumCatalog.theory.length}'), findsOneWidget);
      expect(find.text('Оңай жаттығулар'), findsNothing);
      expect(
        (tester.getCenter(find.text('AI').last).dx - size.width / 2).abs(),
        lessThan(18),
      );
      await tester.tap(find.text('AI').last);
      await tester.pumpAndSettle();
      expect(find.text('AI көмекші'), findsOneWidget);
      await tester.tap(find.text('Сабақ'));
      await tester.pumpAndSettle();
      expect(find.text('Химияны қадамдап үйрен'), findsOneWidget);
      expect(find.text('Атом және молекула'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('classroom tabs expose publishing only to teacher', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final classroom = Classroom(
      id: 'class-test',
      name: '9A · Химия',
      code: 'ABC234',
      ownerId: 'teacher',
      teacherName: 'Айгерім',
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ClassroomDetailScreen(classroom: classroom, teacher: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Посттар'), findsOneWidget);
    expect(find.text('Үй тапсырмасы'), findsOneWidget);
    expect(find.text('Оқушылар'), findsOneWidget);
    expect(find.text('Пост жазу'), findsOneWidget);
    await expectLater(
      find.byType(ClassroomDetailScreen),
      matchesGoldenFile('previews/classroom_teacher.png'),
    );
    await tester.tap(find.text('Пост жазу'));
    await tester.pumpAndSettle();
    expect(find.text('Жаңа пост'), findsOneWidget);
    await tester.tap(find.text('Постты жариялау'));
    await tester.pumpAndSettle();
    expect(find.text('Тақырыпты жазыңыз'), findsOneWidget);
    Navigator.of(tester.element(find.text('Жаңа пост'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Үй тапсырмасы'));
    await tester.pumpAndSettle();
    expect(find.text('Тапсырма қосу'), findsOneWidget);
    await tester.tap(find.text('Оқушылар'));
    await tester.pumpAndSettle();
    expect(find.text('Пост жазу'), findsNothing);
    expect(find.text('Тапсырма қосу'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ClassroomDetailScreen(classroom: classroom, teacher: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Пост жазу'), findsNothing);
    expect(find.text('Тапсырма қосу'), findsNothing);
    expect(find.textContaining('пікір қалдырыңыз'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ClassroomDetailScreen),
      matchesGoldenFile('previews/classroom_student.png'),
    );
  });

  testWidgets('post comments screen keeps a usable composer', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final post = ClassPost(
      id: 'post-test',
      classId: 'class-test',
      title: 'Ертеңгі сабақ',
      body: 'Химиялық теңдеулерді қайталаңыз.',
      authorId: 'teacher',
      authorName: 'Айгерім',
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PostDetailScreen(post: post),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ертеңгі сабақ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Түсінікті, рақмет!');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('homework detail is readable for student and teacher', (
    tester,
  ) async {
    final mono = FontLoader('JBMono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
    await mono.load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final assignment = LearningAssignment(
      id: 'homework-test',
      classId: 'class-test',
      title: 'Судың түзілуі',
      equation: 'H₂ + O₂ → H₂O',
      instructions:
          'Теңдеуді теңестіріп, әр элементтің атомдарын екі жақтан санаңыз.',
      createdAt: DateTime(2026, 10, 3),
      dueAt: DateTime(2099, 10, 10),
    );
    for (final size in [const Size(320, 640), const Size(800, 1024)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StudentAssignmentScreen(assignment: assignment),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Жауабыңызды дайындаңыз'), findsOneWidget);
      expect(find.text('Мұғалімге жіберу'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 320) {
        await expectLater(
          find.byType(StudentAssignmentScreen),
          matchesGoldenFile('previews/homework_student.png'),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: TeacherAssignmentScreen(assignment: assignment),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Жауап келмеді'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 320) {
        await expectLater(
          find.byType(TeacherAssignmentScreen),
          matchesGoldenFile('previews/homework_teacher.png'),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
