import 'package:chem_balance_ai/services/app_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'teacher assignment, student submission and feedback complete the loop',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = FakeFirebaseFirestore();
      final teacherAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'teacher-1',
          email: 'teacher@example.com',
          displayName: 'Айгерім мұғалім',
        ),
      );
      final teacher =
          AppServices.forTesting(
              auth: teacherAuth,
              firestore: store,
              googleSignIn: () => teacherAuth.signInWithCredential(
                GoogleAuthProvider.credential(idToken: 'teacher-token'),
              ),
            )
            ..firebaseReady = true
            ..prefs = await SharedPreferences.getInstance();
      await teacher.signInWithGoogle();
      await teacher.completeProfile(
        'Айгерім мұғалім',
        '№12 мектеп',
        AccountRole.teacher,
        teacherCode: AppServices.teacherRegistrationCode,
      );
      final classroom = await teacher.createClassroom('9A химия');
      await teacher.createClassPost(
        classroom.id,
        title: 'Ертеңгі сабақ',
        body: 'Теңдеуді теңестіру тақырыбын қайталаңыз.',
      );
      await teacher.createAssignment(
        classroom.id,
        title: 'Суды теңестіру',
        equation: 'H2 + O2 → H2O',
        instructions: 'Қадамдарын көрсетіңіз',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      );
      final assignment = (await teacher.loadAssignments(classroom.id)).single;

      final studentAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'student-1',
          email: 'student@example.com',
          displayName: 'Аружан',
        ),
      );
      final student =
          AppServices.forTesting(
              auth: studentAuth,
              firestore: store,
              googleSignIn: () => studentAuth.signInWithCredential(
                GoogleAuthProvider.credential(idToken: 'student-token'),
              ),
            )
            ..firebaseReady = true
            ..prefs = await SharedPreferences.getInstance();
      await student.signInWithGoogle();
      await student.completeProfile(
        'Аружан',
        '№12 мектеп',
        AccountRole.student,
      );
      await student.joinClassroom(classroom.code);
      expect((await student.loadStudentClasses()).single.id, classroom.id);
      final posts = await student.loadClassPosts(classroom.id);
      expect(posts.single.title, 'Ертеңгі сабақ');
      await student.addPostComment(posts.single, 'Түсінікті, рақмет!');
      await expectLater(
        student.createClassPost(
          classroom.id,
          title: 'Рұқсатсыз',
          body: 'Мәтін',
        ),
        throwsException,
      );
      expect(
        (await teacher.loadPostComments(posts.single)).single.body,
        'Түсінікті, рақмет!',
      );
      expect(
        (await teacher.loadClassMembers(classroom.id)).single.name,
        'Аружан',
      );
      await student.submitAssignment(assignment, '2H2 + O2 → 2H2O');

      final submission = (await teacher.loadSubmissions(assignment)).single;
      expect(submission.studentName, 'Аружан');
      await teacher.reviewSubmission(
        assignment,
        submission,
        feedback: 'Дұрыс теңестірілген. Жарайсың!',
        score: 100,
      );
      final reviewed = await student.mySubmission(assignment);
      expect(reviewed!.reviewed, isTrue);
      expect(reviewed.score, 100);
      expect(reviewed.feedback, contains('Жарайсың'));
    },
  );
}
