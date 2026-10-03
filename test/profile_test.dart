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
    final owned = store.collection('classes').doc('owned');
    await owned.collection('members').doc('student-1').set({
      'userId': 'student-1',
    });
    await owned.collection('posts').doc('post-1').set({
      'authorId': 'profile-teacher',
    });
    final assignment = owned.collection('assignments').doc('assignment-1');
    await assignment.set({'title': 'Теңестіру'});
    await assignment.collection('submissions').doc('student-1').set({
      'status': 'submitted',
    });
    await store.collection('classes').doc('other').set({
      'ownerId': 'another-teacher',
      'name': '8A',
    });

    final overview = await app.loadProfileOverview();
    expect(overview.isTeacher, isTrue);
    expect(overview.classesCount, 1);
    expect(overview.studentsCount, 1);
    expect(overview.postsCount, 1);
    expect(overview.assignmentsCount, 1);
    expect(overview.pendingSubmissionsCount, 1);
    expect(overview.name, 'Айгерім');
  });

  test('deleting a student removes their class activity and profile', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'student-delete', email: 'student@school.kz'),
    );
    final app = AppServices.forTesting(auth: auth, firestore: store)
      ..firebaseReady = true
      ..prefs = await SharedPreferences.getInstance();
    await app.register('Оқушы', 'student@school.kz', 'password123');
    final classroom = store.collection('classes').doc('class-1');
    await classroom.set({'ownerId': 'teacher-1', 'name': '7А'});
    await classroom.collection('members').doc(app.userId).set({
      'userId': app.userId,
    });
    await store
        .collection('users')
        .doc(app.userId)
        .collection('memberships')
        .doc('class-1')
        .set({'classId': 'class-1'});
    final post = classroom.collection('posts').doc('post-1');
    await post.set({'authorId': 'teacher-1'});
    await post.collection('comments').doc('comment-1').set({
      'authorId': app.userId,
    });
    final assignment = classroom.collection('assignments').doc('assignment-1');
    await assignment.set({'title': 'Су'});
    await assignment.collection('submissions').doc(app.userId).set({
      'studentId': app.userId,
    });
    await store
        .collection('users')
        .doc(app.userId)
        .collection('lessons')
        .doc('lesson-1')
        .set({'mistakes': 0});
    final uid = app.userId;

    await app.deleteAccount();

    expect((await store.collection('users').doc(uid).get()).exists, isFalse);
    expect(
      (await store.collection('users').doc(uid).collection('lessons').get())
          .docs,
      isEmpty,
    );
    expect(
      (await classroom.collection('members').doc(uid).get()).exists,
      isFalse,
    );
    expect((await post.collection('comments').get()).docs, isEmpty);
    expect((await assignment.collection('submissions').get()).docs, isEmpty);
  });

  test('deleting a teacher removes classes and nested content', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'teacher-delete', email: 'teacher@school.kz'),
    );
    final app = AppServices.forTesting(auth: auth, firestore: store)
      ..firebaseReady = true
      ..prefs = await SharedPreferences.getInstance();
    await app.register(
      'Мұғалім',
      'teacher@school.kz',
      'password123',
      role: AccountRole.teacher,
      teacherCode: AppServices.teacherRegistrationCode,
    );
    final uid = app.userId;
    final classroom = store.collection('classes').doc('class-1');
    await classroom.set({'ownerId': uid, 'name': '7А'});
    await classroom.collection('members').doc('student-1').set({
      'userId': 'student-1',
    });
    await store
        .collection('users')
        .doc('student-1')
        .collection('memberships')
        .doc('class-1')
        .set({'classId': 'class-1'});
    final post = classroom.collection('posts').doc('post-1');
    await post.set({'authorId': uid});
    await post.collection('comments').doc('comment-1').set({
      'authorId': 'student-1',
    });
    final assignment = classroom.collection('assignments').doc('assignment-1');
    await assignment.set({'title': 'Су'});
    await assignment.collection('submissions').doc('student-1').set({
      'studentId': 'student-1',
    });

    await app.deleteAccount();

    expect((await store.collection('users').doc(uid).get()).exists, isFalse);
    expect((await classroom.get()).exists, isFalse);
    expect((await post.collection('comments').get()).docs, isEmpty);
    expect((await assignment.collection('submissions').get()).docs, isEmpty);
    expect(
      (await store
              .collection('users')
              .doc('student-1')
              .collection('memberships')
              .get())
          .docs,
      isEmpty,
    );
  });
}
