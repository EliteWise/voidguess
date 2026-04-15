import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

class FloatingLetters extends StatefulWidget {
  const FloatingLetters();

  @override
  State<FloatingLetters> createState() => _FloatingLettersState();
}

class _FloatingLettersState extends State<FloatingLetters>
    with TickerProviderStateMixin {
  final List<_Particle> _particles = [];
  final List<AnimationController> _controllers = [];
  final _chars = ['_', '?', 'A', 'Z', 'E', 'R', '_', '?', 'X', 'Q', '_'];
  final _random = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spawnParticles();
    });
  }

  void _spawnParticles() {
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 14; i++) {
      final seed = (_random + i * 1337) % 1000;
      final startX = (seed % 100) / 100.0 * size.width;
      final startY = size.height + 20 + (seed % 200).toDouble();
      final duration = 6000 + (seed % 4000);
      final char = _chars[i % _chars.length];
      final delay = (seed % 3000);

      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration),
      );

      _particles.add(_Particle(
        char: char,
        startX: startX,
        startY: startY,
        endY: -40,
        opacity: 0.08 + (seed % 20) / 100.0,
        fontSize: 12.0 + (seed % 10),
        controller: controller,
      ));

      _controllers.add(controller);

      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          controller.repeat();
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _particles.map((p) {
            return AnimatedBuilder(
              animation: p.controller,
              builder: (_, __) {
                final t = p.controller.value;
                final y = p.startY + (p.endY - p.startY) * t;
                double opacity = p.opacity;
                if (t < 0.1) opacity *= t / 0.1;
                if (t > 0.8) opacity *= (1 - t) / 0.2;
                return Positioned(
                  left: p.startX,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Text(
                      p.char,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: p.fontSize,
                        fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Particle {
  final String char;
  final double startX;
  final double startY;
  final double endY;
  final double opacity;
  final double fontSize;
  final AnimationController controller;

  _Particle({
    required this.char,
    required this.startX,
    required this.startY,
    required this.endY,
    required this.opacity,
    required this.fontSize,
    required this.controller,
  });
}