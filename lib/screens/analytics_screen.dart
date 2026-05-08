import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final Map<String, int> subjectBreakdown;
  final int totalQuestions;
  final int streakCount;
  final double quizAverage;

  const AnalyticsScreen({
    super.key,
    required this.weeklyData,
    required this.subjectBreakdown,
    required this.totalQuestions,
    required this.streakCount,
    required this.quizAverage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat counters row
            Row(
              children: [
                _statCard('📚', '$totalQuestions', 'Questions', const Color(0xFF6C63FF)),
                const SizedBox(width: 12),
                _statCard('🔥', '$streakCount', 'Day Streak', const Color(0xFFFF6584)),
                const SizedBox(width: 12),
                _statCard('📊', '${quizAverage.toStringAsFixed(1)}', 'Quiz Avg', const Color(0xFF00D2FF)),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),
            const Text('Weekly Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Bar chart
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 188),
                painter: _BarChartPainter(weeklyData),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 28),
            const Text('Subject Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Pie chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _PieChartPainter(subjectBreakdown),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subjectBreakdown.entries.toList().asMap().entries.map((e) {
                        final colors = [
                          const Color(0xFF6C63FF), const Color(0xFFFF6584),
                          const Color(0xFF00D2FF), const Color(0xFFFFD700),
                          const Color(0xFF00FF88),
                        ];
                        final color = colors[e.key % colors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 10),
                            Text(e.value.key, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const Spacer(),
                            Text('${e.value.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.map((d) => (d['count'] as int? ?? 0)).reduce(max).toDouble();
    if (maxVal == 0) return;

    final barWidth = (size.width - 40) / data.length - 8;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < data.length && i < 7; i++) {
      final count = (data[i]['count'] as int? ?? 0).toDouble();
      final barHeight = (count / maxVal) * (size.height - 40);
      final x = 20.0 + i * (barWidth + 8);
      final y = size.height - 30 - barHeight;

      // Bar gradient
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      final rr = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rr, paint);

      // Day label
      final tp = TextPainter(
        text: TextSpan(text: i < days.length ? days[i] : '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, size.height - 20));

      // Count label
      if (count > 0) {
        final cp = TextPainter(
          text: TextSpan(text: '${count.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        cp.paint(canvas, Offset(x + barWidth / 2 - cp.width / 2, y - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.values.reduce((a, b) => a + b).toDouble();
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFFFF6584),
      const Color(0xFF00D2FF), const Color(0xFFFFD700),
      const Color(0xFF00FF88),
    ];

    double startAngle = -pi / 2;
    int i = 0;
    for (final entry in data.entries) {
      final sweep = (entry.value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);

      // Gap line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()..color = const Color(0xFF161B22)..style = PaintingStyle.stroke..strokeWidth = 3,
      );

      startAngle += sweep;
      i++;
    }

    // Inner circle for donut effect
    canvas.drawCircle(center, radius * 0.55, Paint()..color = const Color(0xFF161B22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
