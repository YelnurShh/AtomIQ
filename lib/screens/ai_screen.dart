import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/check_result.dart';
import '../services/app_services.dart';
import '../services/equation_checker.dart';
import '../widgets/ui.dart';
import '../widgets/ai_answer.dart';

typedef AiResponder =
    Future<String> Function(String prompt, List<Map<String, String>> history);

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, required this.onSaved, this.responder});
  final VoidCallback onSaved;
  final AiResponder? responder;
  @override
  State<AiScreen> createState() => AiScreenState();
}

class AiScreenState extends State<AiScreen> {
  final input = TextEditingController(), scroll = ScrollController();
  final messages = <_Message>[];
  bool loading = false;
  String? lastPrompt;
  int chatSession = 0;

  void newChat() {
    FocusScope.of(context).unfocus();
    chatSession++;
    input.clear();
    setState(() {
      messages.clear();
      loading = false;
      lastPrompt = null;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void prefill(String text) {
    input.text = text;
    setState(() {});
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) {
      scroll.jumpTo(scroll.position.maxScrollExtent);
    }
  });

  Future<void> send([String? retry]) async {
    final text = (retry ?? input.text).trim();
    if (text.isEmpty || loading) return;
    final session = chatSession;
    final prior = messages
        .where((m) => !m.error)
        .map((m) => {'role': m.user ? 'user' : 'assistant', 'content': m.text})
        .toList();
    input.clear();
    final local = EquationChecker.check(text);
    setState(() {
      loading = true;
      lastPrompt = text;
      if (retry == null) {
        messages.add(_Message(user: true, text: text));
      } else if (messages.isNotEmpty && messages.last.error) {
        messages.removeLast();
      }
    });
    jump();
    try {
      final answer = widget.responder == null
          ? await GroqService().ask(text, history: prior)
          : await widget.responder!(text, prior);
      if (!mounted || session != chatSession) return;
      final message = _Message(
        user: false,
        text: answer,
        check: local.valid ? local : null,
      );
      setState(() => messages.add(message));
      if (local.valid) {
        message.result = CheckResult(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          equation: text,
          answer: answer,
          isBalanced: local.balanced,
          createdAt: DateTime.now(),
        );
        await _save(message);
      }
    } catch (e) {
      if (mounted && session == chatSession) {
        setState(
          () => messages.add(
            _Message(
              user: false,
              text: e.toString().replaceFirst('Exception: ', ''),
              error: true,
              check: local.valid ? local : null,
            ),
          ),
        );
      }
    } finally {
      if (mounted && session == chatSession) {
        setState(() => loading = false);
        jump();
      }
    }
  }

  Future<void> _save(_Message message) async {
    if (message.result == null || message.saving) return;
    setState(() => message.saving = true);
    try {
      await AppServices.instance.saveResult(message.result!);
      if (mounted) {
        setState(() => message.saved = true);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Жауап алынды, бірақ сақталмады. Қайта сақтап көріңіз.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => message.saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF6FBFE),
    child: Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _ChatEmptyState(onPrompt: prefill)
              : ListView.builder(
                  controller: scroll,
                  padding: EdgeInsets.fromLTRB(
                    context.pagePadding,
                    18,
                    context.pagePadding,
                    20,
                  ),
                  itemCount: messages.length + (loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const _ThinkingCard();
                    }
                    final message = messages[index];
                    return _ChatMessageTile(
                      message: message,
                      loading: loading,
                      onRetry: () => send(lastPrompt),
                      onSave: () => _save(message),
                    );
                  },
                ),
        ),
        _ChatComposer(input: input, loading: loading, onSend: () => send()),
      ],
    ),
  );
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      context.pagePadding,
      22,
      context.pagePadding,
      30,
    ),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.isCompact ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: AppColors.aquaGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: .18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        BrandMark(size: 46, onBrand: true),
                        SizedBox(width: 11),
                        Text(
                          'AtomIQ AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Химияны бірге\nтүсінейік.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: context.isCompact ? 24 : 28,
                            height: 1.16,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Теңдеуді тексеріңіз, есепті шығарыңыз немесе түсінбегеніңізді сұраңыз.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Неден бастаймыз?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              const Text(
                'Үлгіні таңдаңыз немесе өз сұрағыңызды жазыңыз.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 15),
              _PromptCard(
                icon: Icons.balance_rounded,
                title: 'Теңдеуді теңестіру',
                prompt: 'H2 + O2 → H2O',
                onTap: onPrompt,
              ),
              const SizedBox(height: 9),
              _PromptCard(
                icon: Icons.science_outlined,
                title: 'Реакцияны талдау',
                prompt: 'Fe + O2 → Fe2O3',
                onTap: onPrompt,
              ),
              const SizedBox(height: 9),
              _PromptCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Түсіндіріп бер',
                prompt: 'Коэффициентті қалай табамыз?',
                onTap: onPrompt,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.icon,
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  final IconData icon;
  final String title, prompt;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    onTap: () => onTap(prompt),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                prompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.north_west_rounded, size: 16, color: AppColors.cyan),
      ],
    ),
  );
}

class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        const BrandMark(size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Жауап дайындалып жатыр…',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChatMessageTile extends StatelessWidget {
  const _ChatMessageTile({
    required this.message,
    required this.loading,
    required this.onRetry,
    required this.onSave,
  });

  final _Message message;
  final bool loading;
  final VoidCallback onRetry, onSave;

  @override
  Widget build(BuildContext context) {
    if (message.user) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isTablet
                  ? 520
                  : MediaQuery.sizeOf(context).width * .8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                gradient: AppColors.aquaGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    BrandMark(size: 28),
                    SizedBox(width: 9),
                    Text(
                      'AtomIQ',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI көмекші',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: message.error ? const Color(0xFFFFF7F9) : Colors.white,
                  border: Border.all(
                    color: message.error
                        ? AppColors.coral.withValues(alpha: .4)
                        : AppColors.line,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: .035),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.error)
                      SelectableText(
                        message.text,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      )
                    else
                      AiAnswer(message.text),
                    if (message.check != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.line),
                      const SizedBox(height: 16),
                      _AtomTable(check: message.check!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (message.error)
                    TextButton.icon(
                      onPressed: loading ? null : onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Қайта сұрау'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Жауап көшірілді')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Көшіру'),
                    ),
                  if (message.result != null)
                    message.saved
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '✓ Нәтижелерге сақталды',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: message.saving ? null : onSave,
                            icon: const Icon(
                              Icons.bookmark_add_outlined,
                              size: 16,
                            ),
                            label: Text(
                              message.saving ? 'Сақталуда…' : 'Нәтижені сақтау',
                            ),
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.input,
    required this.loading,
    required this.onSend,
  });

  final TextEditingController input;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(top: BorderSide(color: AppColors.line)),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .055),
          blurRadius: 18,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            11,
            context.pagePadding,
            9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 5, 4),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: const InputDecoration(
                          hintText: 'Теңдеу немесе сұрақ жазыңыз…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: input,
                      builder: (context, value, _) => IconButton.filled(
                        onPressed: loading || value.text.trim().isEmpty
                            ? null
                            : onSend,
                        tooltip: 'Жіберу',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.blue.withValues(
                            alpha: .25,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 21),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 12,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'AI жауабын атомдар балансымен тексеріңіз',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Message {
  _Message({
    required this.user,
    required this.text,
    this.error = false,
    this.check,
  });
  final bool user, error;
  final String text;
  final EquationCheck? check;
  CheckResult? result;
  bool saved = false, saving = false;
}

class _AtomTable extends StatelessWidget {
  const _AtomTable({required this.check});
  final EquationCheck check;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.soft,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          check.balanced ? 'Атомдар саны тең' : 'Атомдар саны тең емес',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: check.balanced ? AppColors.blue : AppColors.coral,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Тәуелсіз есептеу · енгізілген теңдеу',
          style: TextStyle(fontSize: 9),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {0: FlexColumnWidth(2)},
          children: [
            const TableRow(
              children: [
                Text('Элемент', style: TextStyle(fontSize: 10)),
                Text('Сол жақ', style: TextStyle(fontSize: 10)),
                Text('Оң жақ', style: TextStyle(fontSize: 10)),
              ],
            ),
            ...{...check.left.keys, ...check.right.keys}.map((element) {
              final left = check.left[element] ?? 0;
              final right = check.right[element] ?? 0;
              final mismatch = left != right;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      element,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final value in [left, right])
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$value',
                        style: formulaStyle(
                          fontSize: 13,
                          weight: FontWeight.w600,
                          color: mismatch ? AppColors.coral : AppColors.ink,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ],
    ),
  );
}
