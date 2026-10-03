class CheckResult {
  const CheckResult({
    required this.id,
    required this.equation,
    required this.answer,
    required this.isBalanced,
    required this.createdAt,
  });
  final String id;
  final String equation;
  final String answer;
  final bool isBalanced;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'equation': equation,
    'answer': answer,
    'isBalanced': isBalanced,
    'createdAt': createdAt.toIso8601String(),
  };
  factory CheckResult.fromMap(Map<String, dynamic> map) => CheckResult(
    id: map['id']?.toString() ?? '',
    equation: map['equation']?.toString() ?? '',
    answer: map['answer']?.toString() ?? '',
    isBalanced: map['isBalanced'] == true,
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
