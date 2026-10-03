import 'package:chem_balance_ai/core/app_theme.dart';
import 'package:chem_balance_ai/models/practice.dart';
import 'package:chem_balance_ai/screens/practice_screen.dart';
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

  test('all beginner exercises have valid answers', () {
    for (final task in PracticeCatalog.tasks) {
      expect(task.options, contains(task.answer), reason: task.id);
      expect(task.isCorrect(task.answer), isTrue, reason: task.id);
      expect(task.check(task.answer).balanced, isTrue, reason: task.id);
    }
  });

  test('wrong choice leaves the equation unbalanced', () {
    final water = PracticeCatalog.tasks.first;
    expect(water.isCorrect(1), isFalse);
    expect(water.check(1).balanced, isFalse);
  });

  test('completed exercise is saved under the Firebase user', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'practice-student', email: 'student@school.kz'),
    );
    final app =
        AppServices.forTesting(
            auth: auth,
            firestore: store,
            googleSignIn: () => auth.signInWithCredential(
              GoogleAuthProvider.credential(idToken: 'practice-token'),
            ),
          )
          ..firebaseReady = true
          ..prefs = await SharedPreferences.getInstance();
    await app.signInWithGoogle();
    await app.completeProfile('Аружан', '', AccountRole.student);
    await app.savePracticeCompletion('water', 2);

    expect(await app.loadPracticeProgress(), contains('water'));
    final document = await store
        .collection('users')
        .doc('practice-student')
        .collection('practice')
        .doc('water')
        .get();
    expect(document.data()?['attempts'], 2);
  });

  testWidgets('student solves an exercise and progress persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppServices.instance;
    app.prefs = await SharedPreferences.getInstance();
    app.firebaseReady = false;
    app.allowLocalDemo = true;
    await app.signOut();
    await app.register('Аружан', 'practice@school.kz', 'password1');
    final font = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final mono = FontLoader('JBMono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
    await mono.load();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const PracticeScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Коэффициент жаттығуы'), findsOneWidget);
    await expectLater(
      find.byType(PracticeScreen),
      matchesGoldenFile('previews/practice.png'),
    );

    await tester.ensureVisible(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('Тағы бір рет байқап көр.'), findsOneWidget);

    await tester.ensureVisible(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('Дұрыс! Жарайсың.'), findsOneWidget);
    expect(await app.loadPracticeProgress(), contains('water'));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const PracticeScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 6 тапсырма  ·  1 аяқталды'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 1024);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
