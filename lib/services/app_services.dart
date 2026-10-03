import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_result.dart';
import '../models/learning.dart';
import '../firebase_options.dart';

enum AccountRole { student, teacher }

class ProfileOverview {
  const ProfileOverview({
    required this.name,
    required this.email,
    required this.school,
    required this.role,
    required this.checksCount,
    required this.theoryCompleted,
    required this.practiceCompleted,
    required this.formulasCompleted,
    required this.classesCount,
    this.studentsCount = 0,
    this.postsCount = 0,
    this.assignmentsCount = 0,
    this.pendingSubmissionsCount = 0,
  });

  final String name;
  final String email;
  final String school;
  final AccountRole role;
  final int checksCount;
  final int theoryCompleted;
  final int practiceCompleted;
  final int formulasCompleted;
  final int classesCount;
  final int studentsCount;
  final int postsCount;
  final int assignmentsCount;
  final int pendingSubmissionsCount;
  bool get isTeacher => role == AccountRole.teacher;
  String get roleLabel => isTeacher ? 'Мұғалім' : 'Оқушы';
}

class AppServices {
  static const teacherRegistrationCode = 'tech2026';
  AppServices._()
    : _authOverride = null,
      _firestoreOverride = null,
      _googleSignInOverride = null;
  AppServices.forTesting({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    Future<UserCredential?> Function()? googleSignIn,
  }) : _authOverride = auth,
       _firestoreOverride = firestore,
       _googleSignInOverride = googleSignIn;
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final Future<UserCredential?> Function()? _googleSignInOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static final instance = AppServices._();
  late SharedPreferences prefs;
  bool firebaseReady = false;
  bool allowLocalDemo = const bool.fromEnvironment('ENABLE_LOCAL_DEMO');
  String? startupError;
  bool needsProfile = false;
  bool _profileReady = false;
  Future<void>? _googleInitialization;
  AccountRole role = AccountRole.student;
  String _name = 'Зерттеуші';
  String _email = '';
  String _school = '';
  String get displayName => _name;
  String get email => _email;
  String get school => _school;
  String get roleLabel => role == AccountRole.teacher ? 'Мұғалім' : 'Оқушы';
  String get userId => firebaseReady ? (_auth.currentUser?.uid ?? '') : _email;
  bool get isTeacher => role == AccountRole.teacher;
  bool get isSignedIn => firebaseReady
      ? _auth.currentUser != null && _profileReady
      : allowLocalDemo && (prefs.getString('local_session') ?? '').isNotEmpty;
  String get _historyKey =>
      'history_${firebaseReady ? _auth.currentUser?.uid : _email.toLowerCase()}';

  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
    startupError = null;
    _profileReady = false;
    needsProfile = false;
    try {
      if (!allowLocalDemo) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      }
    } catch (_) {
      firebaseReady = false;
      startupError =
          'Firebase қосылмады. Қосылым мен жоба баптауларын тексеріп, қайта көріңіз.';
      return;
    }
    if (firebaseReady && _auth.currentUser != null) {
      // A failed profile fetch never grants a teacher role.
      try {
        await _loadProfile();
      } catch (_) {
        _email = '';
        startupError =
            'Профиль жүктелмеді. Интернетті тексеріп, қайта көріңіз. Деректеріңіз бұлтта сақталған.';
      }
    } else if (allowLocalDemo) {
      final session = prefs.getString('local_session');
      if (session != null) {
        final data = prefs.getString('account_$session');
        if (data != null) {
          _applyProfile(jsonDecode(data) as Map<String, dynamic>);
        } else {
          await prefs.remove('local_session');
        }
      }
    }
  }

  void _applyProfile(Map<String, dynamic> data) {
    _name = data['name'] as String? ?? 'Зерттеуші';
    _email = data['email'] as String? ?? '';
    _school = data['school'] as String? ?? '';
    role = data['role'] == 'teacher'
        ? AccountRole.teacher
        : AccountRole.student;
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser!;
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get(const GetOptions(source: Source.server));
    if (!doc.exists) {
      _name = user.displayName ?? '';
      _email = user.email ?? '';
      _school = '';
      role = AccountRole.student;
      needsProfile = true;
      _profileReady = false;
      return;
    }
    _applyProfile(doc.data()!);
    needsProfile = false;
    _profileReady = true;
  }

  void _requireBackend() {
    if (!firebaseReady && !allowLocalDemo) {
      throw Exception(
        'Firebase байланысы қолжетімсіз. Қосымшаны қайта ашып көріңіз.',
      );
    }
  }

  /// Google authentication and profile creation are separate so that a new
  /// teacher cannot accidentally be registered as a student on a retry.
  Future<bool> signInWithGoogle() async {
    _requireBackend();
    if (!firebaseReady) {
      throw Exception('Google арқылы кіру үшін Firebase режимін қосыңыз.');
    }
    if (_googleSignInOverride != null) {
      final result = await _googleSignInOverride();
      if (result == null) return false;
      _profileReady = false;
      needsProfile = false;
      await _loadProfile();
      return true;
    }
    try {
      _googleInitialization ??= GoogleSignIn.instance.initialize();
      await _googleInitialization;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception(
          'Google аккаунтын растау мүмкін болмады. Қайта көріңіз.',
        );
      }
      _profileReady = false;
      needsProfile = false;
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      await _loadProfile();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  Future<void> completeProfile(
    String name,
    String school,
    AccountRole selectedRole, {
    String teacherCode = '',
  }) async {
    _requireBackend();
    final user = _auth.currentUser;
    if (user == null) throw Exception('Алдымен аккаунтқа кіріңіз.');
    if (name.trim().length < 2) throw Exception('Аты-жөніңізді енгізіңіз.');
    if (selectedRole == AccountRole.teacher) {
      validateTeacherCode(teacherCode);
    }
    final ref = _firestore.collection('users').doc(user.uid);
    final profile = <String, dynamic>{
      'name': name.trim(),
      'email': user.email!,
      'school': school.trim(),
      'role': selectedRole.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
    // A transaction makes retries safe; never overwrite an existing role/profile.
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists) transaction.set(ref, profile);
    });
    await _loadProfile();
  }

  static void validateTeacherCode(String code) {
    if (code.trim() != teacherRegistrationCode) {
      throw Exception(
        'Мұғалім коды дұрыс емес. Кодты жоба әкімшісінен алыңыз.',
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    _requireBackend();
    final normalized = email.trim().toLowerCase();
    if (firebaseReady) {
      await _auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      await _loadProfile();
    } else {
      final raw = prefs.getString('account_$normalized');
      if (raw == null) {
        throw Exception('Бұл email тіркелмеген. Алдымен тіркеліңіз.');
      }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['passwordHash'] != _hash(password, data['salt'] as String)) {
        throw Exception('Email немесе құпиясөз дұрыс емес.');
      }
      _applyProfile(data);
      await prefs.setString('local_session', normalized);
    }
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    AccountRole role = AccountRole.student,
    String teacherCode = '',
    String school = '',
  }) async {
    _requireBackend();
    final normalized = email.trim().toLowerCase();
    if (name.trim().length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized) ||
        password.length < 8) {
      throw Exception(
        'Аты-жөніңізді, email және кемінде 8 таңбалы құпиясөз енгізіңіз.',
      );
    }
    if (role == AccountRole.teacher) {
      validateTeacherCode(teacherCode);
    }
    final profile = <String, dynamic>{
      'name': name.trim(),
      'email': normalized,
      'school': school.trim(),
      'role': role.name,
    };
    if (firebaseReady) {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          ...profile,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        // Undo only the account created by this unsuccessful registration.
        try {
          await credential.user!.delete();
        } catch (_) {
          await _auth.signOut();
        }
        if (error is FirebaseException && error.code == 'permission-denied') {
          throw Exception(
            'Тіркелу расталмады. Мұғалім кодын және Firebase ережелерін тексеріңіз.',
          );
        }
        rethrow;
      }
      _applyProfile(profile);
      _profileReady = true;
      needsProfile = false;
    } else {
      if (prefs.containsKey('account_$normalized')) {
        throw Exception('Бұл email тіркелген. Кіру бетін қолданыңыз.');
      }
      final salt = List.generate(
        24,
        (_) => Random.secure().nextInt(256),
      ).join('-');
      await prefs.setString(
        'account_$normalized',
        jsonEncode({
          ...profile,
          'salt': salt,
          'passwordHash': _hash(password, salt),
        }),
      );
      await prefs.setString('local_session', normalized);
      _applyProfile(profile);
    }
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<void> updateProfile(String name, String school) async {
    _requireBackend();
    if (name.trim().length < 2) {
      throw Exception('Аты-жөніңіз кемінде 2 таңба болуы керек.');
    }
    if (firebaseReady) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'name': name.trim(),
        'school': school.trim(),
      });
    } else {
      final key = 'account_${_email.toLowerCase()}';
      final data = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      await prefs.setString(
        key,
        jsonEncode({...data, 'name': name.trim(), 'school': school.trim()}),
      );
    }
    _name = name.trim();
    _school = school.trim();
  }

  /// Always reads the profile and progress from Firestore while signed in.
  /// The local branch is only for the explicitly enabled demo mode.
  Future<ProfileOverview> loadProfileOverview() async {
    _requireBackend();
    if (firebaseReady) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Алдымен аккаунтқа кіріңіз.');
      final userRef = _firestore.collection('users').doc(uid);
      final profile = await userRef.get(
        const GetOptions(source: Source.server),
      );
      if (!profile.exists) throw Exception('Профиль Firestore-дан табылмады.');
      final data = profile.data()!;
      _applyProfile(data);
      const server = GetOptions(source: Source.server);
      if (isTeacher) {
        final classes = await _firestore
            .collection('classes')
            .where('ownerId', isEqualTo: uid)
            .get(server);
        final students = <String>{};
        var posts = 0;
        var assignments = 0;
        var pending = 0;
        for (final classroom in classes.docs) {
          final members = await classroom.reference
              .collection('members')
              .get(server);
          final classPosts = await classroom.reference
              .collection('posts')
              .get(server);
          final classAssignments = await classroom.reference
              .collection('assignments')
              .get(server);
          students.addAll(members.docs.map((member) => member.id));
          posts += classPosts.docs.length;
          assignments += classAssignments.docs.length;
          for (final assignment in classAssignments.docs) {
            final submissions = await assignment.reference
                .collection('submissions')
                .get(server);
            pending += submissions.docs
                .where(
                  (submission) => submission.data()['status'] == 'submitted',
                )
                .length;
          }
        }
        return ProfileOverview(
          name: displayName,
          email: email,
          school: school,
          role: role,
          checksCount: 0,
          theoryCompleted: 0,
          practiceCompleted: 0,
          formulasCompleted: 0,
          classesCount: classes.docs.length,
          studentsCount: students.length,
          postsCount: posts,
          assignmentsCount: assignments,
          pendingSubmissionsCount: pending,
        );
      }
      final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        userRef.collection('checks').get(server),
        userRef.collection('lessons').get(server),
        userRef.collection('practice').get(server),
        userRef.collection('memberships').get(server),
      ]);
      final checks = snapshots[0];
      final lessons = snapshots[1];
      final formulas = snapshots[2];
      final classesCount = snapshots[3].docs.length;
      return ProfileOverview(
        name: displayName,
        email: email,
        school: school,
        role: role,
        checksCount: checks.docs.length,
        theoryCompleted: lessons.docs
            .where((doc) => !doc.id.startsWith('practice_'))
            .length,
        practiceCompleted: lessons.docs
            .where((doc) => doc.id.startsWith('practice_'))
            .length,
        formulasCompleted: formulas.docs.length,
        classesCount: classesCount,
      );
    }
    if (!allowLocalDemo || !isSignedIn) {
      throw Exception('Алдымен аккаунтқа кіріңіз.');
    }
    final checks = await loadHistory();
    final lessons = await loadLessonProgress();
    final formulas = await loadPracticeProgress();
    return ProfileOverview(
      name: displayName,
      email: email,
      school: school,
      role: role,
      checksCount: checks.length,
      theoryCompleted: lessons
          .where((id) => !id.startsWith('practice_'))
          .length,
      practiceCompleted: lessons
          .where((id) => id.startsWith('practice_'))
          .length,
      formulasCompleted: formulas.length,
      classesCount: 0,
    );
  }

  Future<void> resetPassword(String email) async {
    if (!firebaseReady) {
      throw Exception(
        'Құпиясөзді қалпына келтіру Firebase қосылғанда қолжетімді.',
      );
    }
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (firebaseReady) {
      await _auth.signOut();
    }
    await prefs.remove('local_session');
    if (_googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase is already signed out. */
      }
    }
    _profileReady = false;
    needsProfile = false;
    startupError = null;
    _name = 'Зерттеуші';
    _email = '';
    _school = '';
    role = AccountRole.student;
  }

  bool get usesGoogleSignIn =>
      firebaseReady &&
      (_auth.currentUser?.providerData.any(
            (provider) => provider.providerId == 'google.com',
          ) ??
          false);

  Future<void> deleteAccount({String? password}) async {
    _requireBackend();
    if (!firebaseReady) {
      if (!allowLocalDemo || !isSignedIn) {
        throw Exception('Алдымен аккаунтқа кіріңіз.');
      }
      final email = _email.toLowerCase();
      await prefs.remove('account_$email');
      await prefs.remove('history_$email');
      await prefs.remove(_lessonsKey);
      await prefs.remove(_practiceKey);
      await signOut();
      return;
    }
    final user = _auth.currentUser;
    if (user == null) throw Exception('Алдымен аккаунтқа кіріңіз.');
    final uid = user.uid;
    final email = _email.toLowerCase();

    // Firebase Auth may require a recent login. Do this before removing data.
    if (_authOverride == null) {
      if (usesGoogleSignIn) {
        _googleInitialization ??= GoogleSignIn.instance.initialize();
        await _googleInitialization;
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null) {
          throw Exception('Google аккаунтын растау мүмкін болмады.');
        }
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        );
      } else {
        if (password == null || password.isEmpty || user.email == null) {
          throw Exception('Аккаунтты өшіру үшін құпиясөзді енгізіңіз.');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      }
    }

    final userRef = _firestore.collection('users').doc(uid);
    if (isTeacher) {
      final classes = await _firestore
          .collection('classes')
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final classroom in classes.docs) {
        final posts = await classroom.reference.collection('posts').get();
        for (final post in posts.docs) {
          await _deleteCollection(post.reference.collection('comments'));
          await post.reference.delete();
        }
        final assignments = await classroom.reference
            .collection('assignments')
            .get();
        for (final assignment in assignments.docs) {
          await _deleteCollection(
            assignment.reference.collection('submissions'),
          );
          await assignment.reference.delete();
        }
        final members = await classroom.reference.collection('members').get();
        for (final member in members.docs) {
          await _firestore
              .collection('users')
              .doc(member.id)
              .collection('memberships')
              .doc(classroom.id)
              .delete();
          await member.reference.delete();
        }
        await classroom.reference.delete();
      }
    } else {
      final memberships = await userRef.collection('memberships').get();
      for (final membership in memberships.docs) {
        final classroom = _firestore.collection('classes').doc(membership.id);
        final classDoc = await classroom.get();
        if (classDoc.exists) {
          final posts = await classroom.collection('posts').get();
          for (final post in posts.docs) {
            final comments = await post.reference
                .collection('comments')
                .where('authorId', isEqualTo: uid)
                .get();
            for (final comment in comments.docs) {
              await comment.reference.delete();
            }
          }
          final assignments = await classroom.collection('assignments').get();
          for (final assignment in assignments.docs) {
            await assignment.reference
                .collection('submissions')
                .doc(uid)
                .delete();
          }
          await classroom.collection('members').doc(uid).delete();
        }
        await membership.reference.delete();
      }
    }
    for (final collection in ['checks', 'lessons', 'practice', 'memberships']) {
      await _deleteCollection(userRef.collection(collection));
    }
    await userRef.delete();
    await user.delete();
    await prefs.remove('history_$uid');
    await prefs.remove('lessons_$uid');
    await prefs.remove('practice_$uid');
    await prefs.remove('account_$email');
    await signOut();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final page = await collection.limit(200).get();
      if (page.docs.isEmpty) return;
      for (final doc in page.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<List<CheckResult>> loadHistory() async {
    _requireBackend();
    if (firebaseReady && _auth.currentUser == null) {
      throw Exception('Алдымен аккаунтқа кіріңіз.');
    }
    if (firebaseReady && _auth.currentUser != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('checks')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((d) {
        final data = {...d.data(), 'id': d.id};
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return CheckResult.fromMap(data);
      }).toList();
    }
    return (prefs.getStringList(_historyKey) ?? [])
        .map((e) => CheckResult.fromMap(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveResult(CheckResult result) async {
    _requireBackend();
    if (firebaseReady && _auth.currentUser == null) {
      throw Exception('Алдымен аккаунтқа кіріңіз.');
    }
    if (firebaseReady && _auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('checks')
          .doc(result.id)
          .set({...result.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      return;
    }
    final items = prefs.getStringList(_historyKey) ?? [];
    items.removeWhere(
      (e) => (jsonDecode(e) as Map<String, dynamic>)['id'] == result.id,
    );
    items.insert(0, jsonEncode(result.toMap()));
    await prefs.setStringList(_historyKey, items.take(50).toList());
  }

  Future<void> deleteHistory(String id) async {
    _requireBackend();
    if (firebaseReady && _auth.currentUser == null) {
      throw Exception('Алдымен аккаунтқа кіріңіз.');
    }
    if (firebaseReady && _auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('checks')
          .doc(id)
          .delete();
    } else {
      final items = prefs.getStringList(_historyKey) ?? [];
      items.removeWhere(
        (e) => (jsonDecode(e) as Map<String, dynamic>)['id'] == id,
      );
      await prefs.setStringList(_historyKey, items);
    }
  }

  String get _practiceKey => 'practice_$userId';

  Future<Set<String>> loadPracticeProgress() async {
    _requireBackend();
    if (userId.isEmpty) return {};
    if (firebaseReady) {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('practice')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    }
    return (prefs.getStringList(_practiceKey) ?? []).toSet();
  }

  Future<void> savePracticeCompletion(String taskId, int attempts) async {
    _requireBackend();
    if (userId.isEmpty) throw Exception('Алдымен аккаунтқа кіріңіз.');
    if (firebaseReady) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('practice')
          .doc(taskId)
          .set({
            'completedAt': FieldValue.serverTimestamp(),
            'attempts': attempts,
          });
      return;
    }
    final completed = (prefs.getStringList(_practiceKey) ?? []).toSet();
    completed.add(taskId);
    await prefs.setStringList(_practiceKey, completed.toList());
  }

  String get _lessonsKey => 'lessons_$userId';

  Future<Set<String>> loadLessonProgress() async {
    _requireBackend();
    if (userId.isEmpty) return {};
    final local = (prefs.getStringList(_lessonsKey) ?? []).toSet();
    if (!firebaseReady) return local;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .get();
      return {...local, ...snapshot.docs.map((doc) => doc.id)};
    } catch (_) {
      return local;
    }
  }

  Future<void> saveLessonCompletion(String lessonId, int mistakes) async {
    _requireBackend();
    if (userId.isEmpty) throw Exception('Алдымен аккаунтқа кіріңіз.');
    final completed = (prefs.getStringList(_lessonsKey) ?? []).toSet()
      ..add(lessonId);
    await prefs.setStringList(_lessonsKey, completed.toList());
    if (firebaseReady) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .doc(lessonId)
          .set({
            'completedAt': FieldValue.serverTimestamp(),
            'mistakes': mistakes,
          });
    }
  }

  Future<Classroom> createClassroom(String name) async {
    _requireBackend();
    if (!firebaseReady || !isTeacher) {
      throw Exception('Сыныпты тек Firebase жүйесіндегі мұғалім аша алады.');
    }
    if (name.trim().length < 2) throw Exception('Сынып атауын енгізіңіз.');
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    final ref = _firestore.collection('classes').doc();
    await ref.set({
      'name': name.trim(),
      'code': code,
      'ownerId': userId,
      'teacherName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return Classroom(
      id: ref.id,
      name: name.trim(),
      code: code,
      ownerId: userId,
      teacherName: displayName,
      createdAt: DateTime.now(),
    );
  }

  Future<List<Classroom>> loadTeacherClasses() async {
    if (!firebaseReady) return [];
    final snap = await _firestore
        .collection('classes')
        .where('ownerId', isEqualTo: userId)
        .get();
    final result = snap.docs.map(Classroom.fromDoc).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> joinClassroom(String code) async {
    _requireBackend();
    if (!firebaseReady || isTeacher) {
      throw Exception('Сыныпқа тек Firebase жүйесіндегі оқушы қосылады.');
    }
    final clean = code.trim().toUpperCase();
    final found = await _firestore
        .collection('classes')
        .where('code', isEqualTo: clean)
        .limit(1)
        .get();
    if (found.docs.isEmpty) throw Exception('Бұл кодпен сынып табылмады.');
    final classroom = found.docs.first;
    final batch = _firestore.batch();
    batch.set(classroom.reference.collection('members').doc(userId), {
      'userId': userId,
      'name': displayName,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('memberships')
          .doc(classroom.id),
      {'classId': classroom.id, 'joinedAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<List<Classroom>> loadStudentClasses() async {
    if (!firebaseReady) return [];
    final memberships = await _firestore
        .collection('users')
        .doc(userId)
        .collection('memberships')
        .get();
    final result = <Classroom>[];
    for (final membership in memberships.docs) {
      final doc = await _firestore
          .collection('classes')
          .doc(membership.id)
          .get();
      if (doc.exists) result.add(Classroom.fromDoc(doc));
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> createClassPost(
    String classId, {
    required String title,
    required String body,
  }) async {
    if (!firebaseReady || !isTeacher) {
      throw Exception('Постты тек мұғалім жариялай алады.');
    }
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) {
      throw Exception('Посттың атауы мен мәтінін толтырыңыз.');
    }
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .add({
          'title': cleanTitle,
          'body': cleanBody,
          'authorId': userId,
          'authorName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<ClassPost>> loadClassPosts(String classId) async {
    if (!firebaseReady) return [];
    final snapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .get();
    final posts = snapshot.docs
        .map((doc) => ClassPost.fromDoc(classId, doc))
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> addPostComment(ClassPost post, String body) async {
    if (!firebaseReady) throw Exception('Firebase байланысы қажет.');
    final cleanBody = body.trim();
    if (cleanBody.isEmpty) throw Exception('Пікір мәтінін енгізіңіз.');
    await _firestore
        .collection('classes')
        .doc(post.classId)
        .collection('posts')
        .doc(post.id)
        .collection('comments')
        .add({
          'body': cleanBody,
          'authorId': userId,
          'authorName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<PostComment>> loadPostComments(ClassPost post) async {
    if (!firebaseReady) return [];
    final snapshot = await _firestore
        .collection('classes')
        .doc(post.classId)
        .collection('posts')
        .doc(post.id)
        .collection('comments')
        .get();
    final comments = snapshot.docs.map(PostComment.fromDoc).toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  Future<List<ClassMember>> loadClassMembers(String classId) async {
    if (!firebaseReady) return [];
    final snapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('members')
        .get();
    final members = snapshot.docs.map(ClassMember.fromDoc).toList();
    members.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return members;
  }

  Future<void> createAssignment(
    String classId, {
    required String title,
    required String equation,
    required String instructions,
    required DateTime dueAt,
  }) async {
    if (!firebaseReady || !isTeacher) throw Exception('Мұғалім рөлі қажет.');
    if (title.trim().isEmpty || equation.trim().isEmpty) {
      throw Exception('Тапсырма атауы мен теңдеуді енгізіңіз.');
    }
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .add({
          'title': title.trim(),
          'equation': equation.trim(),
          'instructions': instructions.trim(),
          'dueAt': Timestamp.fromDate(dueAt),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<LearningAssignment>> loadAssignments(String classId) async {
    if (!firebaseReady) return [];
    final snap = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .get();
    final result = snap.docs
        .map((d) => LearningAssignment.fromDoc(classId, d))
        .toList();
    result.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return result;
  }

  Future<void> submitAssignment(
    LearningAssignment assignment,
    String answer,
  ) async {
    if (!firebaseReady || isTeacher) throw Exception('Оқушы рөлі қажет.');
    if (answer.trim().isEmpty) throw Exception('Жауабыңызды енгізіңіз.');
    await _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc(assignment.id)
        .collection('submissions')
        .doc(userId)
        .set({
          'studentId': userId,
          'studentName': displayName,
          'answer': answer.trim(),
          'status': 'submitted',
          'feedback': '',
          'score': null,
          'submittedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<StudentSubmission?> mySubmission(LearningAssignment assignment) async {
    if (!firebaseReady) return null;
    final doc = await _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc(assignment.id)
        .collection('submissions')
        .doc(userId)
        .get();
    return doc.exists ? StudentSubmission.fromDoc(doc) : null;
  }

  Future<List<StudentSubmission>> loadSubmissions(
    LearningAssignment assignment,
  ) async {
    if (!firebaseReady || !isTeacher) return [];
    final snap = await _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc(assignment.id)
        .collection('submissions')
        .get();
    final result = snap.docs.map(StudentSubmission.fromDoc).toList();
    result.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return result;
  }

  Future<void> reviewSubmission(
    LearningAssignment assignment,
    StudentSubmission submission, {
    required String feedback,
    int? score,
  }) async {
    if (!firebaseReady || !isTeacher) throw Exception('Мұғалім рөлі қажет.');
    if (feedback.trim().isEmpty) throw Exception('Кері байланыс жазыңыз.');
    await _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc(assignment.id)
        .collection('submissions')
        .doc(submission.id)
        .update({
          'feedback': feedback.trim(),
          'score': score,
          'status': 'reviewed',
          'reviewedAt': FieldValue.serverTimestamp(),
        });
  }
}

class GroqService {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  bool get configured => _apiKey.isNotEmpty;

  Future<String> ask(
    String prompt, {
    List<Map<String, String>> history = const [],
  }) async {
    if (!configured) {
      throw Exception(
        'AI байланысы бапталмаған. Жоба әкімшісіне хабарласыңыз.',
      );
    }
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': const String.fromEnvironment(
              'GROQ_MODEL',
              defaultValue: 'openai/gpt-oss-120b',
            ),
            'messages': [
              {
                'role': 'system',
                'content':
                    'Сен AtomIQ химия көмекшісісің. Қазақ тілінде қысқа және түсінікті жауап бер. Қолданушы: ${AppServices.instance.roleLabel}. Теңдеуде формулаларды өзгертпе, ең кіші бүтін коэффициенттерді тап. Әр элемент атомдарын екі жақта санап көрсет. Атомдық баланс реакцияның жүзеге асатынын дәлелдемейтінін ажырат. Оқушыға қадаммен түсіндір, мұғалімге оқушы қатесін тексеру жолын көрсет. Белгісіздікті жасырма. Тақырып химия мен оны оқытуға қатысты болсын.',
              },
              {
                'role': 'system',
                'content':
                    r'Жауапты Markdown түрінде жаз: қысқа тақырыптар, тізімдер, қажет болса қалың мәтін. Формулаларды $...$ ішінде, жеке теңдеулерді бөлек жолдағы $$...$$ ішінде LaTeX түрінде бер. Көпжолды есептеуде әр теңдеуді жеке $$...$$ блогына жаз; \begin{aligned}, align, gathered қолданба. Химиялық таңбаларды \mathrm{H}_{2} түрінде жаз, реакция үшін \rightarrow, бөлшек үшін \frac{}{} қолдан. \ce, \pu, mhchem немесе қосымша LaTeX пакеттерін қолданба. Формулаларды код блогына салма. Қарапайым мәтінді математика режимінен тыс жаз.',
              },
              ...history.skip(history.length > 12 ? history.length - 12 : 0),
              {'role': 'user', 'content': prompt},
            ],
            'temperature': .2,
            'max_completion_tokens': 2400,
            'reasoning_effort': 'low',
          }),
        )
        .timeout(const Duration(seconds: 35));
    if (response.statusCode == 401) {
      throw Exception(
        'AI қызметіне кіру кілті жарамсыз. Әкімшіге хабарласыңыз.',
      );
    }
    if (response.statusCode == 429) {
      throw Exception('Сұраулар шегіне жеттік. Сәлден кейін қайталаңыз.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'AI уақытша қолжетімсіз (${response.statusCode}). Қайта көріңіз.',
      );
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI жауабы бос. Қайта көріңіз.');
    }
    return content.trim();
  }
}
