import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

String authErrorMessage(Object error) {
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google арқылы кіру тоқтатылды.';
    }
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google арқылы кіру әлі бапталмаған. Firebase-де Google әдісін қосып, SHA кілттерін тіркеу қажет.';
    }
    return 'Google аккаунтына қосылу мүмкін болмады. Интернет пен Google Play қызметін тексеріңіз.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'email-already-in-use' => 'Бұл email тіркелген. Кіру бетін қолданыңыз.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email немесе құпиясөз дұрыс емес.',
      'account-exists-with-different-credential' =>
        'Бұл email басқа әдіспен тіркелген. Алдымен сол әдіспен кіріңіз.',
      'operation-not-allowed' =>
        'Бұл кіру әдісі Firebase Console-да әлі қосылмаған.',
      'permission-denied' =>
        'Сақтау рұқсаты жоқ. Мұғалім кодын немесе Firestore ережелерін тексеріңіз.',
      'network-request-failed' ||
      'unavailable' ||
      'deadline-exceeded' => 'Интернет байланысын тексеріп, қайта көріңіз.',
      'too-many-requests' => 'Сұрау тым көп. Сәлден кейін қайталаңыз.',
      'user-disabled' => 'Бұл аккаунт тоқтатылған. Әкімшіге хабарласыңыз.',
      'weak-password' => 'Күрделірек құпиясөз таңдаңыз.',
      'invalid-email' => 'Email дұрыс жазылмаған.',
      _ => 'Операция орындалмады. Қайта көріңіз (${error.code}).',
    };
  }
  return error.toString().replaceFirst('Exception: ', '');
}
