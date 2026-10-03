import 'package:chem_balance_ai/models/check_result.dart';
import 'package:chem_balance_ai/services/app_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore store;
  late AppServices app;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: 'google-user',
        email: 'teacher@example.com',
        displayName: 'Айгерім',
      ),
    );
    store = FakeFirebaseFirestore();
    app = AppServices.forTesting(
      auth: auth,
      firestore: store,
      googleSignIn: () => auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: 'test-token'),
      ),
    );
    app.prefs = await SharedPreferences.getInstance();
    app.firebaseReady = true;
  });
  test(
    'new Google user must complete role/profile before accessing app',
    () async {
      expect(await app.signInWithGoogle(), isTrue);
      expect(app.needsProfile, isTrue);
      expect(app.isSignedIn, isFalse);
      expect((await store.doc('users/google-user').get()).exists, isFalse);
      await app.completeProfile(
        'Айгерім',
        'Мектеп 12',
        AccountRole.teacher,
        teacherCode: AppServices.teacherRegistrationCode,
      );
      final profile = (await store.doc('users/google-user').get()).data()!;
      expect(profile['role'], 'teacher');
      expect(profile.containsKey('invitationHash'), isFalse);
      expect(profile.containsKey('password'), isFalse);
      expect(app.isSignedIn, isTrue);
      expect(app.needsProfile, isFalse);
    },
  );
  test('wrong teacher code cannot create a Google profile', () async {
    expect(await app.signInWithGoogle(), isTrue);
    await expectLater(
      app.completeProfile(
        'Айгерім',
        'Мектеп 12',
        AccountRole.teacher,
        teacherCode: 'WRONG',
      ),
      throwsException,
    );
    expect((await store.doc('users/google-user').get()).exists, isFalse);
    expect(app.isSignedIn, isFalse);
  });
  test(
    'existing Google user keeps role/name and saved Firestore results',
    () async {
      await app.signInWithGoogle();
      await app.completeProfile(
        'Бұрынғы есім',
        'Мектеп',
        AccountRole.teacher,
        teacherCode: AppServices.teacherRegistrationCode,
      );
      await app.saveResult(
        CheckResult(
          id: 'check',
          equation: '2H2 + O2 -> 2H2O',
          answer: 'Тең',
          isBalanced: true,
          createdAt: DateTime.now(),
        ),
      );
      await app.signOut();
      await app.signInWithGoogle();
      expect(app.role, AccountRole.teacher);
      expect(app.displayName, 'Бұрынғы есім');
      expect((await app.loadHistory()).single.id, 'check');
      await app.completeProfile('Жаңа есім', '', AccountRole.student);
      expect(app.displayName, 'Бұрынғы есім');
      expect(app.role, AccountRole.teacher);
      expect(app.prefs.getKeys(), isEmpty);
    },
  );
  test('cancelled Google flow does not create a profile or session', () async {
    final cancelled = AppServices.forTesting(
      auth: auth,
      firestore: store,
      googleSignIn: () async => null,
    )..firebaseReady = true;
    expect(await cancelled.signInWithGoogle(), isFalse);
    expect(cancelled.isSignedIn, isFalse);
    expect((await store.collection('users').get()).docs, isEmpty);
  });
  test(
    'email/password registration still persists profile to Firestore',
    () async {
      await app.register('Оқушы', 'student@example.com', 'password123');
      expect(app.isSignedIn, isTrue);
      final profile = (await store.doc('users/${auth.currentUser!.uid}').get())
          .data()!;
      expect(profile['role'], 'student');
      expect(profile['email'], 'student@example.com');
      expect(profile.containsKey('passwordHash'), isFalse);
    },
  );
  test('normal mode refuses silent local fallback', () async {
    app.firebaseReady = false;
    await expectLater(
      app.register('Оқушы', 'student@example.com', 'password123'),
      throwsException,
    );
    await expectLater(app.loadHistory(), throwsException);
    expect(app.prefs.getKeys(), isEmpty);
  });
}
