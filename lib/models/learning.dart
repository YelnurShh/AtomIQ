import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _date(Object? value) => value is Timestamp
    ? value.toDate()
    : DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.teacherName,
    required this.createdAt,
  });
  final String id, name, code, ownerId, teacherName;
  final DateTime createdAt;
  factory Classroom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Classroom(
      id: doc.id,
      name: d['name'] ?? '',
      code: d['code'] ?? '',
      ownerId: d['ownerId'] ?? '',
      teacherName: d['teacherName'] ?? '',
      createdAt: _date(d['createdAt']),
    );
  }
}

class ClassPost {
  const ClassPost({
    required this.id,
    required this.classId,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });
  final String id, classId, title, body, authorId, authorName;
  final DateTime createdAt;

  factory ClassPost.fromDoc(
    String classId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ClassPost(
      id: doc.id,
      classId: classId,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: _date(data['createdAt']),
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });
  final String id, authorId, authorName, body;
  final DateTime createdAt;

  factory PostComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostComment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      body: data['body'] ?? '',
      createdAt: _date(data['createdAt']),
    );
  }
}

class ClassMember {
  const ClassMember({
    required this.userId,
    required this.name,
    required this.joinedAt,
  });
  final String userId, name;
  final DateTime joinedAt;

  factory ClassMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassMember(
      userId: doc.id,
      name: data['name'] ?? '',
      joinedAt: _date(data['joinedAt']),
    );
  }
}

class LearningAssignment {
  const LearningAssignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.equation,
    required this.instructions,
    required this.createdAt,
    required this.dueAt,
  });
  final String id, classId, title, equation, instructions;
  final DateTime createdAt, dueAt;
  bool get overdue => dueAt.isBefore(DateTime.now());
  factory LearningAssignment.fromDoc(
    String classId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return LearningAssignment(
      id: doc.id,
      classId: classId,
      title: d['title'] ?? '',
      equation: d['equation'] ?? '',
      instructions: d['instructions'] ?? '',
      createdAt: _date(d['createdAt']),
      dueAt: _date(d['dueAt']),
    );
  }
}

class StudentSubmission {
  const StudentSubmission({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.answer,
    required this.status,
    required this.feedback,
    required this.score,
    required this.submittedAt,
  });
  final String id, studentId, studentName, answer, status, feedback;
  final int? score;
  final DateTime submittedAt;
  bool get reviewed => status == 'reviewed';
  factory StudentSubmission.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return StudentSubmission(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      answer: d['answer'] ?? '',
      status: d['status'] ?? 'submitted',
      feedback: d['feedback'] ?? '',
      score: (d['score'] as num?)?.toInt(),
      submittedAt: _date(d['submittedAt']),
    );
  }
}
