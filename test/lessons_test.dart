import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/models/lesson_curriculum.dart';
import 'package:chem_balance_ai/screens/formulas_screen.dart';
import 'package:chem_balance_ai/screens/lessons_screen.dart';
import 'package:chem_balance_ai/services/app_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('7–11 curriculum has five theory and fifteen practice questions', () {
    expect(CurriculumCatalog.theory.length, greaterThanOrEqualTo(25));
    expect(CurriculumCatalog.practice, hasLength(10));
    expect(CurriculumCatalog.theory.map((e) => e.grade).toSet(), {
      7,
      8,
      9,
      10,
      11,
    });
    final all = [...CurriculumCatalog.theory, ...CurriculumCatalog.practice];
    expect(all.map((lesson) => lesson.id).toSet(), hasLength(all.length));
    for (final lesson in all) {
      expect(lesson.questions, hasLength(lesson.practice ? 15 : 5));
      expect(lesson.workedExamples, hasLength(2));
      expect(lesson.concepts.length, greaterThanOrEqualTo(3));
      expect(lesson.matches, hasLength(3));
      expect(
        lesson.questions.map((q) => q.text).toSet(),
        hasLength(lesson.questions.length),
      );
      for (final question in lesson.questions) {
        expect(question.text, isNotEmpty);
        expect(question.explanation, isNotEmpty);
        expect(question.options.toSet(), hasLength(question.options.length));
        expect(
          question.correctIndex,
          inInclusiveRange(0, question.options.length - 1),
        );
      }
      expect(lesson.matches.map((pair) => pair.left).toSet(), hasLength(3));
      expect(lesson.matches.map((pair) => pair.right).toSet(), hasLength(3));
    }
  });

  test('completed lesson is saved under Firebase user', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'lesson-student', email: 'lesson@school.kz'),
    );
    final app =
        AppServices.forTesting(
            auth: auth,
            firestore: store,
            googleSignIn: () => auth.signInWithCredential(
              GoogleAuthProvider.credential(idToken: 'lesson-token'),
            ),
          )
          ..firebaseReady = true
          ..prefs = await SharedPreferences.getInstance();
    await app.signInWithGoogle();
    await app.completeProfile('Аружан', '', AccountRole.student);
    await app.saveLessonCompletion('atoms_molecules', 1);
    expect(await app.loadLessonProgress(), contains('atoms_molecules'));
    final doc = await store
        .collection('users')
        .doc('lesson-student')
        .collection('lessons')
        .doc('atoms_molecules')
        .get();
    expect(doc.data()?['mistakes'], 1);
  });

  testWidgets('lesson moves from reading to quiz and matching, then saves', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppServices.instance;
    app.prefs = await SharedPreferences.getInstance();
    app.firebaseReady = false;
    app.allowLocalDemo = true;
    await app.signOut();
    await app.register('Аружан', 'lesson@local.kz', 'password1');
    final font = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LessonsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Теория'), findsOneWidget);
    expect(find.text('Практика'), findsOneWidget);
    expect(find.text('Теория сабақтары'), findsOneWidget);
    await expectLater(
      find.byType(LessonsScreen),
      matchesGoldenFile('previews/lessons.png'),
    );
    await tester.tap(find.text('Атом және молекула'));
    await tester.pumpAndSettle();
    expect(find.text('Түсініп алайық'), findsOneWidget);
    expect(find.text('1 C + 2 O = 3 атом.'), findsNothing);
    await tester.ensureVisible(find.text('Жауабын көру').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Жауабын көру').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 сутек және 1 оттек'), findsOneWidget);
    await tester.ensureVisible(find.text('Тестке өту'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тестке өту'));
    await tester.pumpAndSettle();
    final first = CurriculumCatalog.theory.first;
    for (var i = 0; i < first.questions.length; i++) {
      final question = first.questions[i];
      await tester.ensureVisible(
        find.text(question.options[question.correctIndex]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(question.options[question.correctIndex]));
      await tester.pumpAndSettle();
      final next = i == first.questions.length - 1
          ? 'Сәйкестендіруге өту'
          : 'Келесі сұрақ';
      await tester.ensureVisible(find.text(next));
      await tester.pumpAndSettle();
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('H'));
    await tester.tap(find.text('Оттек'));
    await tester.pumpAndSettle();
    expect(find.textContaining('сәйкес келмеді'), findsOneWidget);
    await tester.tap(find.text('Сутек'));
    await tester.tap(find.text('O'));
    await tester.tap(find.text('Оттек'));
    await tester.tap(find.text('C'));
    await tester.tap(find.text('Көміртек'));
    await tester.pumpAndSettle();
    expect(find.text('Сабақ аяқталды!'), findsOneWidget);
    expect(await app.loadLessonProgress(), contains('atoms_molecules'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice tab opens fifteen-question lesson', (tester) async {
    for (final (family, asset) in [
      ('Montserrat', 'assets/fonts/Montserrat.ttf'),
      ('JBMono', 'assets/fonts/JetBrainsMono-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
    SharedPreferences.setMockInitialValues({});
    final app = AppServices.instance;
    app.prefs = await SharedPreferences.getInstance();
    app.firebaseReady = false;
    app.allowLocalDemo = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LessonsScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Практика'));
    await tester.pumpAndSettle();
    expect(find.text('Формулалар'), findsOneWidget);
    expect(find.text('Практикалық бағыттар'), findsOneWidget);
    await tester.tap(find.text('Формулалар'));
    await tester.pumpAndSettle();
    expect(find.text('Формулалар'), findsOneWidget);
    expect(find.text('Химия формулалары'), findsOneWidget);
    expect(find.text('Зат мөлшері'), findsOneWidget);
    expect(find.text('Тапсырма 1'), findsNothing);
    await expectLater(
      find.byType(FormulasScreen),
      matchesGoldenFile('previews/formulas.png'),
    );
    await tester.enterText(find.byType(TextField), 'H₂SO₄');
    await tester.pump();
    expect(find.text('Күкірт қышқылы'), findsOneWidget);
    expect(find.text('Зат мөлшері'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Формула және атом саны'));
    await tester.pumpAndSettle();
    expect(find.text('Түсініп алайық'), findsOneWidget);
    await tester.ensureVisible(find.text('Тестке өту'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тестке өту'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 15 сұрақ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
