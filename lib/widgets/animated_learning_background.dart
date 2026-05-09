import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedLearningBackground extends StatefulWidget {
  final Widget child;
  const AnimatedLearningBackground({super.key, required this.child});

  @override
  State<AnimatedLearningBackground> createState() => _AnimatedLearningBackgroundState();
}

class _AnimatedLearningBackgroundState extends State<AnimatedLearningBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _rng = Random(42);
  late List<_AnimatedSymbol> _symbols;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _generateSymbols();
  }

  void _generateSymbols() {
    final chars = ['🎓', '🔬', '🌍', '📐', '🧬', '🚀', '🧠', '💡', '📚', '⚛️', '🔭', '🎨'];
    _symbols = List.generate(20, (i) {
      return _AnimatedSymbol(
        symbol: chars[_rng.nextInt(chars.length)],
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 20 + _rng.nextDouble() * 30,
        phase: _rng.nextDouble() * 2 * pi,
        speed: 0.5 + _rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF000000), const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)]
                    : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
              ),
            ),
          ),
        ),
        // Animated Symbols
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LearningBackgroundPainter(
                  symbols: _symbols,
                  progress: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _AnimatedSymbol {
  final String symbol;
  final double x, y, size, phase, speed;
  _AnimatedSymbol({required this.symbol, required this.x, required this.y, required this.size, required this.phase, required this.speed});
}

class _LearningBackgroundPainter extends CustomPainter {
  final List<_AnimatedSymbol> symbols;
  final double progress;
  final bool isDark;

  _LearningBackgroundPainter({required this.symbols, required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final sym in symbols) {
      // Calculate pulsing alpha and scale using sin wave
      final time = progress * 2 * pi * sym.speed + sym.phase;
      final pulse = (sin(time) + 1) / 2; // 0.0 to 1.0

      // Opacity: subtly visible (e.g., max 15% opacity)
      final maxOpacity = isDark ? 0.20 : 0.15;
      final opacity = pulse * maxOpacity;

      // Scale: slightly grows and shrinks
      final scale = 0.8 + (pulse * 0.4);

      final tp = TextPainter(
        text: TextSpan(
          text: sym.symbol,
          style: TextStyle(
            fontSize: sym.size * scale,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(sym.x * size.width, sym.y * size.height);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LearningBackgroundPainter old) => true;
}
