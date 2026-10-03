import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import '../core/app_theme.dart';

/// The same renderer is used for live and saved answers. Source stays unchanged
/// in Firestore and on the clipboard. Code spans/fences are handled by Markdown.
class AiAnswer extends StatelessWidget {
  const AiAnswer(this.data, {super.key});
  final String data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: AppColors.ink,
        fontSize: 14,
        height: 1.65,
      );
      final codeStyle = style.copyWith(
        fontFamily: AppFonts.mono,
        fontSize: 13,
        height: 1.5,
      );
      return MarkdownBody(
        data: data,
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        blockSyntaxes: [DisplayMathSyntax()],
        inlineSyntaxes: [InlineMathSyntax()],
        builders: {
          'math-inline': _MathBuilder(false, constraints.maxWidth, style),
          'math-display': _MathBuilder(true, constraints.maxWidth, style),
          'pre': _CodeBlockBuilder(codeStyle),
        },
        // Model-generated image URLs must not trigger unsolicited requests.
        sizedImageBuilder: (_) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 16, color: AppColors.muted),
              SizedBox(width: 8),
              Text(
                'Сурет көрсетілмейді',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: style,
          h1: style.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
          h2: style.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          h3: style.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          strong: style.copyWith(fontWeight: FontWeight.w700),
          em: style.copyWith(fontStyle: FontStyle.italic),
          a: style.copyWith(
            color: AppColors.blue,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.blue,
          ),
          listBullet: style,
          listIndent: 20,
          blockquote: style.copyWith(color: AppColors.muted),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: AppColors.mint, width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          code: codeStyle,
          tableHead: style.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          tableBody: style.copyWith(fontSize: 13),
          tableBorder: TableBorder.all(color: AppColors.line, width: 1),
          tableColumnWidth: const FlexColumnWidth(),
          tableCellsPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          tableCellsDecoration: const BoxDecoration(color: Colors.white),
          horizontalRuleDecoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          blockSpacing: 12,
        ),
      );
    },
  );
}

class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax()
    : super(
        r'\$\$([^\n]+?)\$\$|\\\(([^\n]+?)\\\)|\\\[([^\n]+?)\\\]|\$(?!\s)([^$\n]+?)\$',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tex =
        match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4)!;
    parser.addNode(md.Element.empty('math-inline')..attributes['tex'] = tex);
    return true;
  }
}

/// Only consumes a display block when its closing delimiter exists. An
/// unfinished streamed/model response must not swallow the remaining prose.
class DisplayMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\s*(\$\$|\\\[)');

  int? _end(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;
    final close = match.group(1) == r'$$' ? r'$$' : r'\]';
    for (var i = 0; parser.peek(i) != null; i++) {
      final line = parser.peek(i)!.content;
      final tail = i == 0 ? line.substring(match.end) : line;
      if (tail.trimRight().endsWith(close)) return i;
      if (i > 0 && tail.trim().isEmpty) return null;
    }
    return null;
  }

  @override
  bool canParse(md.BlockParser parser) => _end(parser) != null;

  @override
  md.Node parse(md.BlockParser parser) {
    final end = _end(parser)!;
    final opening = pattern.firstMatch(parser.current.content)!;
    final lines = <String>[];
    for (var i = 0; i <= end; i++) {
      var line = parser.current.content;
      if (i == 0) line = line.substring(opening.end);
      if (i == end) {
        line = line.trimRight();
        line = line.substring(0, line.length - 2);
      }
      lines.add(line);
      parser.advance();
    }
    return md.Element.empty('math-display')
      ..attributes['tex'] = lines.join('\n').trim();
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  _MathBuilder(this.display, this.maxWidth, this.style);
  final bool display;
  final double maxWidth;
  final TextStyle style;
  @override
  bool isBlockElement() => display;

  void _copy(BuildContext context, String tex) {
    Clipboard.setData(ClipboardData(text: tex));
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Формула көшірілді')));
  }

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.attributes['tex'] ?? '';
    final maxFormulaWidth = (maxWidth - 48).clamp(40.0, double.infinity);
    final lines = display ? _mathLines(tex) : [tex];
    return Semantics(
      label: tex,
      child: GestureDetector(
        onLongPress: () => _copy(context, tex),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxFormulaWidth),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: display ? 6 : 0),
            padding: EdgeInsets.symmetric(
              horizontal: display ? 12 : 0,
              vertical: display ? 12 : 2,
            ),
            decoration: display
                ? BoxDecoration(
                    color: AppColors.mint.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: .28),
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in lines)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: display ? 3 : 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Math.tex(
                        line,
                        mathStyle: display ? MathStyle.display : MathStyle.text,
                        textStyle: style.copyWith(
                          color: display
                              ? const Color(0xFF267344)
                              : AppColors.ink,
                          fontSize:
                              16 * MediaQuery.textScalerOf(context).scale(1),
                        ),
                        onErrorFallback: (_) => SizedBox(
                          width: maxFormulaWidth - (display ? 26 : 0),
                          child: Text(
                            readableMath(line),
                            softWrap: true,
                            style: style.copyWith(
                              fontSize: 15,
                              color: const Color(0xFF267344),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _mathLines(String tex) {
  final body = tex
      .replaceAll(RegExp(r'\\begin\{(?:aligned|align\*?|gathered)\}'), '')
      .replaceAll(RegExp(r'\\end\{(?:aligned|align\*?|gathered)\}'), '');
  return body
      .split(RegExp(r'\\\\|\n'))
      .map((line) => line.replaceAll('&', '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

/// Readable fallback for model output that flutter_math cannot parse.
String readableMath(String tex) {
  var value = tex;
  value = value.replaceAllMapped(
    RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}'),
    (match) => '(${match.group(1)})/(${match.group(2)})',
  );
  for (final command in [r'\mathrm', r'\text', r'\operatorname']) {
    value = value.replaceAll('$command{', '{');
  }
  value = value
      .replaceAll(r'\cdot', '·')
      .replaceAll(r'\times', '×')
      .replaceAll(r'\rightarrow', '→')
      .replaceAll(r'\to', '→')
      .replaceAll(r'\approx', '≈')
      .replaceAll(r'\Delta', 'Δ')
      .replaceAll(r'\leq', '≤')
      .replaceAll(r'\geq', '≥')
      .replaceAll(r'\pm', '±')
      .replaceAll(r'\%', '%')
      .replaceAll(RegExp(r'\\(?:left|right)'), '')
      .replaceAll(RegExp(r'\\(?:begin|end)\{[^}]*\}'), '')
      .replaceAll('&', '')
      .replaceAll('\\', '');
  value = value.replaceAllMapped(
    RegExp(r'_\{([^{}]+)\}|_([A-Za-z0-9]+)'),
    (match) => _script(match.group(1) ?? match.group(2)!, subscript: true),
  );
  value = value.replaceAllMapped(
    RegExp(r'\^\{([^{}]+)\}|\^(-?[A-Za-z0-9]+)'),
    (match) => _script(match.group(1) ?? match.group(2)!, subscript: false),
  );
  return value
      .replaceAll(RegExp(r'[{}]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _script(String value, {required bool subscript}) {
  const subscripts = '₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎';
  const superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾';
  const source = '0123456789+-=()';
  final target = subscript ? subscripts : superscripts;
  return value.split('').map((character) {
    final index = source.indexOf(character);
    return index < 0 ? character : target[index];
  }).join();
}

/// Fenced code blocks get their own card: a language chip and a copy button,
/// instead of the plain grey box flutter_markdown draws by default.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder(this.style);
  final TextStyle style;
  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    String? language;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final cls = child.attributes['class'];
        if (cls != null && cls.startsWith('language-')) {
          language = cls.substring(9);
        }
      }
    }
    final code = element.textContent.trimRight();
    return _CodeBlock(code: code, language: language, style: style);
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code, required this.style, this.language});
  final String code;
  final String? language;
  final TextStyle style;
  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.soft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
          child: Row(
            children: [
              const Icon(
                Icons.data_object_rounded,
                size: 13,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                widget.language?.toUpperCase() ?? 'КОД',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: .4,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _copy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 13,
                          color: _copied ? AppColors.mint : AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Көшірілді' : 'Көшіру',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _copied ? AppColors.mint : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(widget.code, style: widget.style),
          ),
        ),
      ],
    ),
  );
}
