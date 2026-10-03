import 'package:chem_balance_ai/services/app_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'profile overview refreshes identity and statistics from Firestore',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'profile-student', email: 'student@school.kz'),
      );
      final app =
          AppServices.forTesting(
              auth: auth,
              firestore: store,
              googleSignIn: () => auth.signInWithCredential(
                GoogleAuthProvider.credential(idToken: 'profile-token'),
              ),
            )
            ..firebaseReady = true
            ..prefs = await SharedPreferences.getInstance();
      await app.signInWithGoogle();
      await app.completeProfile('Бастапқы есім', '', AccountRole.student);
      final user = store.collection('users').doc('profile-student');
      await user.update({'name': 'Аружан Firestore', 'school': '№12 мектеп'});
      await user.collection('checks').doc('check-1').set({'isBalanced': true});
      await user.collection('lessons').doc('atoms_molecules').set({
        'mistakes': 0,
      });
      await user.collection('lessons').doc('practice_formula').set({
        'mistakes': 1,
      });
      await user.collection('practice').doc('water').set({'attempts': 2});
      await user.collection('memberships').doc('class-1').set({
        'classId': 'class-1',
      });

      final overview = await app.loadProfileOverview();
      expect(overview.name, 'Аружан Firestore');
      expect(overview.school, '№12 мектеп');
      expect(overview.email, 'student@school.kz');
      expect(overview.role, AccountRole.student);
      expect(overview.checksCount, 1);
      expect(overview.theoryCompleted, 1);
      expect(overview.practiceCompleted, 1);
      expect(overview.formulasCompleted, 1);
      expect(overview.classesCount, 1);
    },
  );

  test('teacher overview counts owned classrooms from Firestore', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'profile-teacher', email: 'teacher@school.kz'),
    );
    final app =
        AppServices.forTesting(
            auth: auth,
            firestore: store,
            googleSignIn: () => auth.signInWithCredential(
              GoogleAuthProvider.credential(idToken: 'teacher-token'),
            ),
          )
          ..firebaseReady = true
          ..prefs = await SharedPreferences.getInstance();
    await app.signInWithGoogle();
    await app.completeProfile(
      'Айгерім',
      '№12 мектеп',
      AccountRole.teacher,
      teacherCode: AppServices.teacherRegistrationCode,
    );
    await store.collection('classes').doc('owned').set({
      'ownerId': 'profile-teacher',
      'name': '7A',
    });
    await store.collection('classes').doc('other').set({
      'ownerId': 'another-teacher',
      'name': '8A',
    });

    final overview = await app.loadProfileOverview();
    expect(overview.isTeacher, isTrue);
    expect(overview.classesCount, 1);
    expect(overview.name, 'Айгерім');
  });
}
