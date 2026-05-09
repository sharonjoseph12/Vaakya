import 'dart:math';
import 'package:flutter/material.dart';

/// Draws educational diagrams for topics using CustomPainter
class ConceptDiagram extends StatelessWidget {
  final String topic;
  const ConceptDiagram({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = topic.toLowerCase();
    CustomPainter? painter;
    if (t.contains('trigonometry') || t.contains('sin') || t.contains('cos') || t.contains('tan') || t.contains('triangle')) {
      painter = _TrianglePainter(isDark: isDark);
    } else if (t.contains('cell') || t.contains('mitochondria') || t.contains('nucleus')) {
      painter = _CellPainter(isDark: isDark);
    } else if (t.contains('atom') || t.contains('electron') || t.contains('proton')) {
      painter = _AtomPainter(isDark: isDark);
    } else if (t.contains('newton') || t.contains('force') || t.contains('gravity')) {
      painter = _ForcePainter(isDark: isDark);
    } else if (t.contains('photosynthesis') || t.contains('plant') || t.contains('chlorophyll')) {
      painter = _PlantPainter(isDark: isDark);
    } else if (t.contains('circuit') || t.contains('electricity') || t.contains('voltage')) {
      painter = _CircuitPainter(isDark: isDark);
    }
    if (painter == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 48),
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CustomPaint(painter: painter, size: const Size(double.infinity, 180))),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final bool isDark;
  _TrianglePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final fg = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final accent = const Color(0xFF6C63FF);
    final p = Paint()..color = accent..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // Right triangle
    final a = Offset(60, size.height - 30); // bottom-left (right angle)
    final b = Offset(size.width - 60, size.height - 30); // bottom-right
    final c = Offset(60, 40); // top
    canvas.drawLine(a, b, p); canvas.drawLine(b, c, p); canvas.drawLine(c, a, p);
    // Right angle mark
    final sq = Paint()..color = accent..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(a.dx, a.dy - 15, 15, 15), sq);
    // Labels
    final ts = TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold);
    _text(canvas, 'Adjacent', Offset((a.dx + b.dx) / 2 - 25, a.dy + 6), ts);
    _text(canvas, 'Opposite', Offset(a.dx - 10, (a.dy + c.dy) / 2), ts..fontSize);
    _drawRotated(canvas, 'Hypotenuse', Offset((b.dx + c.dx) / 2 + 8, (b.dy + c.dy) / 2), ts, -0.7);
    // Angle theta
    final arcP = Paint()..color = const Color(0xFFFF6584)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCenter(center: b, width: 50, height: 50), pi, 0.55, false, arcP);
    _text(canvas, 'θ', Offset(b.dx - 40, b.dy - 25), TextStyle(color: const Color(0xFFFF6584), fontSize: 14, fontWeight: FontWeight.bold));
    // Formulas
    _text(canvas, 'sin θ = Opp/Hyp', Offset(size.width - 140, 20), TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600));
    _text(canvas, 'cos θ = Adj/Hyp', Offset(size.width - 140, 35), TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600));
    _text(canvas, 'tan θ = Opp/Adj', Offset(size.width - 140, 50), TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CellPainter extends CustomPainter {
  final bool isDark;
  _CellPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    // Cell membrane
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width - 40, height: size.height - 30), Paint()..color = const Color(0xFF00D2FF).withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width - 40, height: size.height - 30), Paint()..color = const Color(0xFF00D2FF)..strokeWidth = 2..style = PaintingStyle.stroke);
    // Nucleus
    canvas.drawCircle(Offset(cx, cy), 30, Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.2));
    canvas.drawCircle(Offset(cx, cy), 30, Paint()..color = const Color(0xFF6C63FF)..strokeWidth = 2..style = PaintingStyle.stroke);
    _text(canvas, 'Nucleus', Offset(cx - 20, cy - 6), TextStyle(color: const Color(0xFF6C63FF), fontSize: 9, fontWeight: FontWeight.bold));
    // Mitochondria
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 70, cy - 20), width: 40, height: 20), Paint()..color = const Color(0xFFFF6584).withValues(alpha: 0.3));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 70, cy - 20), width: 40, height: 20), Paint()..color = const Color(0xFFFF6584)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _text(canvas, 'Mitochondria', Offset(cx + 45, cy - 10), TextStyle(color: const Color(0xFFFF6584), fontSize: 8, fontWeight: FontWeight.bold));
    // ER
    final erP = Paint()..color = const Color(0xFF00FF88)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) { canvas.drawArc(Rect.fromCenter(center: Offset(cx - 70, cy + 10 + i * 12.0), width: 50, height: 10), 0, pi, false, erP); }
    _text(canvas, 'ER', Offset(cx - 80, cy + 45), TextStyle(color: const Color(0xFF00FF88), fontSize: 9, fontWeight: FontWeight.bold));
    // Labels
    _text(canvas, 'Cell Membrane', Offset(20, size.height - 18), TextStyle(color: const Color(0xFF00D2FF), fontSize: 9, fontWeight: FontWeight.bold));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AtomPainter extends CustomPainter {
  final bool isDark;
  _AtomPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    // Nucleus
    canvas.drawCircle(Offset(cx, cy), 20, Paint()..color = const Color(0xFFFF6584).withValues(alpha: 0.3));
    canvas.drawCircle(Offset(cx, cy), 20, Paint()..color = const Color(0xFFFF6584)..strokeWidth = 2..style = PaintingStyle.stroke);
    _text(canvas, 'P+ N', Offset(cx - 10, cy - 5), TextStyle(color: const Color(0xFFFF6584), fontSize: 9, fontWeight: FontWeight.bold));
    // Electron orbits
    for (int i = 0; i < 3; i++) {
      final r = 40.0 + i * 22;
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
      // Electron dot
      final angle = i * 2.1;
      final ex = cx + r * cos(angle); final ey = cy + r * sin(angle);
      canvas.drawCircle(Offset(ex, ey), 5, Paint()..color = const Color(0xFF00D2FF));
      _text(canvas, 'e⁻', Offset(ex - 5, ey - 5), TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold));
    }
    _text(canvas, 'Shell 1', Offset(cx + 38, cy - 50), TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 8));
    _text(canvas, 'Shell 2', Offset(cx + 58, cy - 68), TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 8));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ForcePainter extends CustomPainter {
  final bool isDark;
  _ForcePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    // Block
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 60, height: 40), const Radius.circular(4)), Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.2));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 60, height: 40), const Radius.circular(4)), Paint()..color = const Color(0xFF6C63FF)..strokeWidth = 2..style = PaintingStyle.stroke);
    _text(canvas, 'm', Offset(cx - 4, cy - 6), TextStyle(color: const Color(0xFF6C63FF), fontSize: 14, fontWeight: FontWeight.bold));
    // Force arrow (right)
    _arrow(canvas, Offset(cx + 30, cy), Offset(cx + 100, cy), const Color(0xFFFF6584), 3);
    _text(canvas, 'F = ma', Offset(cx + 55, cy - 18), TextStyle(color: const Color(0xFFFF6584), fontSize: 11, fontWeight: FontWeight.bold));
    // Gravity arrow (down)
    _arrow(canvas, Offset(cx, cy + 20), Offset(cx, cy + 70), const Color(0xFF00D2FF), 2.5);
    _text(canvas, 'mg', Offset(cx + 6, cy + 45), TextStyle(color: const Color(0xFF00D2FF), fontSize: 10, fontWeight: FontWeight.bold));
    // Normal force (up)
    _arrow(canvas, Offset(cx, cy - 20), Offset(cx, cy - 60), const Color(0xFF00FF88), 2.5);
    _text(canvas, 'N', Offset(cx + 6, cy - 55), TextStyle(color: const Color(0xFF00FF88), fontSize: 10, fontWeight: FontWeight.bold));
    // Ground
    canvas.drawLine(Offset(30, cy + 20), Offset(size.width - 30, cy + 20), Paint()..color = (isDark ? Colors.white24 : Colors.black26)..strokeWidth = 1);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PlantPainter extends CustomPainter {
  final bool isDark;
  _PlantPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    // Leaf
    final leafPath = Path()..moveTo(cx, cy - 20)..quadraticBezierTo(cx + 60, cy - 60, cx + 30, cy + 10)..quadraticBezierTo(cx, cy + 5, cx, cy - 20);
    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF00FF88).withValues(alpha: 0.3));
    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF00FF88)..strokeWidth = 2..style = PaintingStyle.stroke);
    // Sun
    canvas.drawCircle(Offset(size.width - 50, 30), 20, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3));
    canvas.drawCircle(Offset(size.width - 50, 30), 20, Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _text(canvas, 'Sun', Offset(size.width - 60, 25), TextStyle(color: const Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold));
    // Arrow: sunlight
    _arrow(canvas, Offset(size.width - 75, 45), Offset(cx + 40, cy - 30), const Color(0xFFFFD700), 1.5);
    // Labels
    _text(canvas, 'CO₂ + H₂O', Offset(30, cy + 30), TextStyle(color: const Color(0xFF00D2FF), fontSize: 10, fontWeight: FontWeight.bold));
    _arrow(canvas, Offset(90, cy + 35), Offset(cx - 10, cy + 5), const Color(0xFF00D2FF), 1.5);
    _text(canvas, '→ C₆H₁₂O₆ + O₂', Offset(cx + 35, cy + 25), TextStyle(color: const Color(0xFF00FF88), fontSize: 10, fontWeight: FontWeight.bold));
    _text(canvas, 'Chloroplast', Offset(cx - 5, cy - 10), TextStyle(color: const Color(0xFF00FF88), fontSize: 8, fontWeight: FontWeight.bold));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CircuitPainter extends CustomPainter {
  final bool isDark;
  _CircuitPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final wire = Paint()..color = const Color(0xFF6C63FF)..strokeWidth = 2..style = PaintingStyle.stroke;
    // Simple circuit rectangle
    final r = Rect.fromLTRB(50, 30, size.width - 50, size.height - 30);
    canvas.drawRect(r, wire);
    // Battery
    canvas.drawLine(Offset(r.left, 70), Offset(r.left, 90), Paint()..color = const Color(0xFFFF6584)..strokeWidth = 4);
    canvas.drawLine(Offset(r.left - 5, 95), Offset(r.left + 5, 95), Paint()..color = const Color(0xFFFF6584)..strokeWidth = 2);
    _text(canvas, 'Battery', Offset(r.left - 30, 100), TextStyle(color: const Color(0xFFFF6584), fontSize: 9, fontWeight: FontWeight.bold));
    // Resistor (zigzag)
    final ry = r.top; final rx = (r.left + r.right) / 2;
    final zigP = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) { canvas.drawLine(Offset(rx - 30 + i * 15.0, ry), Offset(rx - 22 + i * 15.0, ry + (i.isEven ? -8 : 8)), zigP); }
    _text(canvas, 'R (Ω)', Offset(rx - 10, ry + 12), TextStyle(color: const Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold));
    // V=IR
    _text(canvas, 'V = I × R', Offset(rx - 20, size.height - 18), TextStyle(color: const Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.bold));
    // Current arrow
    _arrow(canvas, Offset(r.right, size.height / 2 + 20), Offset(r.right, size.height / 2 - 20), const Color(0xFF00D2FF), 2);
    _text(canvas, 'I', Offset(r.right + 6, size.height / 2 - 8), TextStyle(color: const Color(0xFF00D2FF), fontSize: 11, fontWeight: FontWeight.bold));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

void _text(Canvas c, String t, Offset o, TextStyle s) {
  final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, o);
}

void _arrow(Canvas c, Offset from, Offset to, Color color, double width) {
  c.drawLine(from, to, Paint()..color = color..strokeWidth = width);
  final angle = atan2(to.dy - from.dy, to.dx - from.dx);
  final p = Path()
    ..moveTo(to.dx, to.dy)
    ..lineTo(to.dx - 10 * cos(angle - 0.4), to.dy - 10 * sin(angle - 0.4))
    ..lineTo(to.dx - 10 * cos(angle + 0.4), to.dy - 10 * sin(angle + 0.4))
    ..close();
  c.drawPath(p, Paint()..color = color);
}

void _drawRotated(Canvas c, String t, Offset o, TextStyle s, double angle) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(angle);
  _text(c, t, Offset.zero, s);
  c.restore();
}
