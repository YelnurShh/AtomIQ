import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isCompact => screenSize.width < 360;
  bool get isTablet => screenSize.width >= 700;
  double get pagePadding => isCompact ? 16 : (isTablet ? 32 : 20);
  double get contentWidth => isTablet ? 760 : 620;
}

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.contentWidth),
      child: Padding(
        padding: padding ?? EdgeInsets.all(context.pagePadding),
        child: child,
      ),
    ),
  );
}

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient = AppColors.primaryGradient,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  final Widget child;
  final Gradient gradient;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withValues(alpha: .28),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Listener(
      onPointerDown: (_) {
        if (!widget.loading && widget.onTap != null) {
          setState(() => pressed = true);
        }
      },
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale:
            pressed &&
                !widget.loading &&
                !MediaQuery.disableAnimationsOf(context)
            ? .97
            : 1,
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 140,
        ),
        curve: const Cubic(.23, 1, .32, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: widget.loading
                ? const []
                : [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: .3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: FilledButton(
            onPressed: widget.loading ? null : widget.onTap,
            child: widget.loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(widget.label)),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 12),
                        Icon(widget.icon, size: 19),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color = Colors.white,
    this.radius = 22.0,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line.withValues(alpha: .72)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.onBrand = false});
  final double size;
  final bool onBrand;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onBrand ? Colors.white.withValues(alpha: .88) : Colors.white,
      borderRadius: BorderRadius.circular(size * .32),
      boxShadow: onBrand
          ? const []
          : [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .16),
                blurRadius: size * .3,
                offset: Offset(0, size * .08),
              ),
            ],
    ),
    child: Padding(
      padding: EdgeInsets.all(size < 30 ? 1 : size * .06),
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

class AuthorPill extends StatelessWidget {
  const AuthorPill({super.key});
  static const name = 'Демесинова Айгерим Кожабековна';

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Text(
        'Жоба авторы',
        style: TextStyle(fontSize: 10, color: AppColors.muted),
      ),
      SizedBox(height: 4),
      Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class AuthorAppBarLine extends StatelessWidget implements PreferredSizeWidget {
  const AuthorAppBarLine({super.key, this.onBrand = false});
  final bool onBrand;

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: preferredSize.height,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Жоба авторы',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: .3,
              color: onBrand ? const Color(0xD9FFFFFF) : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            height: 17,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                AuthorPill.name,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onBrand ? Colors.white : AppColors.cyan,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(action!, style: const TextStyle(fontSize: 11)),
        ),
    ],
  );
}

/// A small indicator-strip tag: a coloured dot plus a label in sentence case.
/// Replaces tracked-out ALL-CAPS eyebrows with a reusable, literal "reagent
/// tag" motif that fits the chemistry subject matter.
class TagLabel extends StatelessWidget {
  const TagLabel(this.label, {super.key, this.color = AppColors.blue});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// Shared abc_app-style page surface. Kept as a wrapper so feature screens do
/// not need to know how the global visual system paints its background.
class GridBackdrop extends StatelessWidget {
  const GridBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.background, child: child);
}

/// A literal balance-scale glyph — the app's core idea (is the equation
/// balanced?) drawn instead of decorated. Used in the home hero instead of
/// a generic mascot so the artwork carries actual meaning.
class BalanceScaleArt extends StatelessWidget {
  const BalanceScaleArt({super.key, this.size = 78});
  final double size;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(size: Size.square(size), painter: _BalancePainter()),
  );
}

class _BalancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const theta = -0.16; // slight tilt, mid-weighing rather than static
    final fulcrum = Offset(w * .5, h * .3);
    final standPaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = w * .05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .5, h * .93), fulcrum, standPaint);
    canvas.drawLine(
      Offset(w * .26, h * .93),
      Offset(w * .74, h * .93),
      standPaint,
    );
    final halfLen = w * .4;
    final left = Offset(
      fulcrum.dx - halfLen * math.cos(theta),
      fulcrum.dy - halfLen * math.sin(theta),
    );
    final right = Offset(
      fulcrum.dx + halfLen * math.cos(theta),
      fulcrum.dy + halfLen * math.sin(theta),
    );
    canvas.drawLine(left, right, standPaint..strokeWidth = w * .04);
    canvas.drawCircle(fulcrum, w * .04, Paint()..color = AppColors.ink);

    void pan(Offset top, Color color) {
      final bottom = top + Offset(0, h * .17);
      canvas.drawLine(
        top,
        bottom,
        Paint()
          ..color = AppColors.blue.withValues(alpha: .55)
          ..strokeWidth = w * .022
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        Rect.fromCenter(center: bottom, width: w * .36, height: h * .17),
        0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .05
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    pan(left, AppColors.mint);
    pan(right, AppColors.accentDeep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fades + lifts a child in once, staggered by [delay]. Skips animation
/// entirely when the platform requests reduced motion.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  Widget build(BuildContext context) => child;
}

/// A quiet, code-native molecular illustration. No image or font network requests.
class MoleculeArt extends StatelessWidget {
  const MoleculeArt({super.key, this.size = 150});
  final double size;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(size: Size.square(size), painter: _MoleculePainter()),
  );
}

class _MoleculePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    final nodes = [
      center,
      Offset(size.width * .2, size.height * .23),
      Offset(size.width * .83, size.height * .31),
      Offset(size.width * .38, size.height * .88),
    ];
    final line = Paint()
      ..color = const Color(0xFF9CB4A2)
      ..strokeWidth = size.width * .045
      ..strokeCap = StrokeCap.round;
    for (final node in nodes.skip(1)) {
      canvas.drawLine(center, node, line);
    }
    for (var i = 0; i < nodes.length; i++) {
      final r = size.width * (i == 0 ? .19 : .125);
      canvas.drawCircle(
        nodes[i] + Offset(0, r * .2),
        r,
        Paint()
          ..color = const Color(0x16236B52)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      final colors = i == 0
          ? [const Color(0xFF619B76), AppColors.blue]
          : [const Color(0xFFF0F7CE), const Color(0xFFB9D178)];
      canvas.drawCircle(
        nodes[i],
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.5, -.6),
            radius: 1.2,
            colors: colors,
          ).createShader(Rect.fromCircle(center: nodes[i], radius: r)),
      );
      canvas.drawArc(
        Rect.fromCircle(center: nodes[i], radius: r * .72),
        math.pi * 1.1,
        .75,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
