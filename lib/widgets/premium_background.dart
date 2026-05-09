import 'dart:math';
import 'package:flutter/material.dart';

/// Premium background with floating math/science/chemistry symbols
class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _SymbolsPainter(isDark: isDark))),
      child,
    ]);
  }
}

class _SymbolsPainter extends CustomPainter {
  final bool isDark;
  _SymbolsPainter({required this.isDark});

  static const _symbols = [
    'π', '∑', '∫', 'Δ', '√', '∞', 'θ', 'λ', 'Ω', 'α', 'β',
    'H₂O', 'CO₂', 'NaCl', 'Fe', 'O₂', 'Au',
    'F=ma', 'E=mc²', 'V=IR', 'PV=nRT',
    '+', '−', '×', '÷', '=', '%',
    'sin', 'cos', 'tan', 'log',
    'Σ', 'μ', 'φ', 'ε', '∂',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Fixed seed for consistent layout
    final count = (size.width * size.height / 8000).clamp(15, 40).toInt();
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final symbol = _symbols[rng.nextInt(_symbols.length)];
      final opacity = 0.08 + rng.nextDouble() * 0.08; // Subtly visible: 8-16%
      final fontSize = 16.0 + rng.nextDouble() * 14;
      final rotation = (rng.nextDouble() - 0.5) * 0.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final tp = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: opacity),
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
