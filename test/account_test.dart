import 'package:chem_balance_ai/services/app_services.dart';
import 'package:chem_balance_ai/models/check_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final app = AppServices.instance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app.prefs = await SharedPreferences.getInstance();
    app.firebaseReady = false;
    app.allowLocalDemo = true;
    await app.signOut();
  });

  test('invalid teacher code does not create an account or session', () async {
    await expectLater(
      app.register(
        'Мұғалім',
        'teacher@test.kz',
        'password1',
        role: AccountRole.teacher,
        teacherCode: 'WRONG',
      ),
      throwsException,
    );
    expect(app.isSignedIn, isFalse);
    expect(app.prefs.containsKey('account_teacher@test.kz'), isFalse);
  });

  test('teacher registration code must match', () {
    expect(AppServices.teacherRegistrationCode, 'tech2026');
    expect(() => AppServices.validateTeacherCode(''), throwsException);
    expect(() => AppServices.validateTeacherCode('wrong'), throwsException);
    expect(
      () =>
          AppServices.validateTeacherCode(AppServices.teacherRegistrationCode),
      returnsNormally,
    );
  });

  test('valid teacher role survives sign out and sign in', () async {
    await app.register(
      'Тест мұғалім',
      'teacher@test.kz',
      'password1',
      role: AccountRole.teacher,
      teacherCode: AppServices.teacherRegistrationCode,
    );
    expect(app.isTeacher, isTrue);
    await app.signOut();
    await app.signIn('teacher@test.kz', 'password1');
    expect(app.isTeacher, isTrue);
    expect(app.roleLabel, 'Мұғалім');
  });

  test(
    'student profile and history persist, other accounts cannot see results',
    () async {
      await app.register(
        'Оқушы Бір',
        'student@test.kz',
        'password1',
        school: '12 мектеп',
      );
      expect(app.role, AccountRole.student);
      await app.saveResult(
        CheckResult(
          id: 'one',
          equation: '2H2 + O2 -> 2H2O',
          answer: 'Balanced',
          isBalanced: true,
          createdAt: DateTime(2026),
        ),
      );
      await app.updateProfile('Жаңа есім', '15 мектеп');
      await app.signOut();
      await expectLater(
        app.signIn('student@test.kz', 'incorrect'),
        throwsException,
      );
      expect(app.isSignedIn, isFalse);
      await app.signIn('student@test.kz', 'password1');
      expect(app.displayName, 'Жаңа есім');
      expect(app.school, '15 мектеп');
      expect((await app.loadHistory()).length, 1);
      await app.signOut();
      await app.register('Екінші оқушы', 'second@test.kz', 'password2');
      expect(await app.loadHistory(), isEmpty);
    },
  );
}
