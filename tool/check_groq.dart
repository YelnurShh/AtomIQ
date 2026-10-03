import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final data =
      jsonDecode(await File('config/local.json').readAsString())
          as Map<String, dynamic>;
  final response = await http
      .post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${data['GROQ_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': data['GROQ_MODEL'] ?? 'openai/gpt-oss-120b',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Balance H2 + O2 -> H2O. Return only the balanced equation.',
            },
          ],
          'max_completion_tokens': 300,
          'reasoning_effort': 'low',
          'temperature': 0,
        }),
      )
      .timeout(const Duration(seconds: 30));
  // Deliberately never print credentials or request headers.
  stdout.writeln('Groq HTTP ${response.statusCode}');
  if (response.statusCode != 200) {
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    stdout.writeln(
      jsonEncode(
        error['error'],
      ).replaceAll(data['GROQ_API_KEY'] as String, '[redacted]'),
    );
    final models = await http.get(
      Uri.parse('https://api.groq.com/openai/v1/models'),
      headers: {'Authorization': 'Bearer ${data['GROQ_API_KEY']}'},
    );
    if (models.statusCode == 200) {
      final list = jsonDecode(models.body) as Map<String, dynamic>;
      stdout.writeln((list['data'] as List).map((e) => e['id']).join(', '));
    }
    exitCode = 1;
    return;
  }
  final result = jsonDecode(response.body) as Map<String, dynamic>;
  final text = result['choices'][0]['message']['content'] as String;
  stdout.writeln(
    'Response received: ${text.isNotEmpty}; model: ${result['model']}',
  );
}
