import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class VoidActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const VoidActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.backgroundColor = AppTheme.action,
    this.foregroundColor = AppTheme.actionText,
    this.accentColor = AppTheme.primaryDeep,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.32),
            width: 0.6,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _VoidActionPainter(
                  accentColor: accentColor,
                  foregroundColor: foregroundColor,
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  color: foregroundColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoidActionPainter extends CustomPainter {
  final Color accentColor;
  final Color foregroundColor;

  const _VoidActionPainter({
    required this.accentColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawPlanet(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.48),
      radius: 13,
      alpha: 0.12,
    );
    _drawPlanet(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.28),
      radius: 9,
      alpha: 0.10,
    );
    _drawPlanet(
      canvas,
      center: Offset(size.width * 0.75, size.height * 0.78),
      radius: 5,
      alpha: 0.08,
    );

    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = foregroundColor.withValues(alpha: 0.10);

    for (final point in [
      Offset(size.width * 0.28, size.height * 0.24),
      Offset(size.width * 0.42, size.height * 0.72),
      Offset(size.width * 0.61, size.height * 0.30),
      Offset(size.width * 0.93, size.height * 0.66),
    ]) {
      canvas.drawCircle(point, 0.9, starPaint);
    }
  }

  void _drawPlanet(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
  }) {
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accentColor.withValues(alpha: alpha);
    final shadePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = foregroundColor.withValues(alpha: alpha * 0.35);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accentColor.withValues(alpha: alpha * 1.15);

    canvas.drawCircle(center, radius, bodyPaint);
    canvas.drawCircle(
      center.translate(radius * 0.35, -radius * 0.18),
      radius * 0.72,
      shadePaint,
    );
    canvas.drawLine(
      center.translate(-radius * 0.62, radius * 0.10),
      center.translate(radius * 0.58, -radius * 0.08),
      linePaint,
    );
    canvas.drawLine(
      center.translate(-radius * 0.42, radius * 0.38),
      center.translate(radius * 0.35, radius * 0.24),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_VoidActionPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
