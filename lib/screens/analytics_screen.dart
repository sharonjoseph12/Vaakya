import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gamification_provider.dart';
import '../providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gp, _) {
          final totalQ = gp.totalQuestionsAsked;
          final streak = gp.streakCount;
          final avg = gp.quizAverage;
          final daily = gp.dailyCounts;
          final subjects = gp.subjectCounts.isEmpty
              ? {'General': totalQ > 0 ? totalQ : 1}
              : gp.subjectCounts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat counters
                Row(children: [
                  _statCard('📚', '$totalQ', 'Questions', const Color(0xFF6C63FF), cardColor, borderColor, textColor, subtextColor),
                  const SizedBox(width: 12),
                  _statCard('🔥', '$streak', 'Day Streak', const Color(0xFFFF6584), cardColor, borderColor, textColor, subtextColor),
                  const SizedBox(width: 12),
                  _statCard('📊', avg.toStringAsFixed(1), 'Quiz Avg', const Color(0xFF00D2FF), cardColor, borderColor, textColor, subtextColor),
                ]).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 28),
                Text('Weekly Activity', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Bar chart
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 188),
                    painter: _BarChartPainter(daily, subtextColor),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 28),
                Text('Subject Breakdown', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Pie chart
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 140, height: 140,
                      child: CustomPaint(painter: _PieChartPainter(subjects, cardColor)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SizedBox(
                        height: 140,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: subjects.entries.toList().asMap().entries.map((e) {
                              final colors = [const Color(0xFF6C63FF), const Color(0xFFFF6584), const Color(0xFF00D2FF), const Color(0xFFFFD700), const Color(0xFF00FF88)];
                              final color = colors[e.key % colors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(children: [
                                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(e.value.key, style: TextStyle(color: subtextColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 8),
                                  Text('${e.value.value}', style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
                                ]),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                // Quiz history
                if (gp.quizScores.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Recent Quiz Scores', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gp.quizScores.length > 10 ? 10 : gp.quizScores.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final s = gp.quizScores.reversed.toList()[index];
                        final pct = s / 10;
                        final color = pct >= 0.8 ? const Color(0xFF00FF88) : pct >= 0.5 ? const Color(0xFFFFD700) : const Color(0xFFFF6584);
                        return Container(
                          width: 110,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor, 
                            borderRadius: BorderRadius.circular(20), 
                            border: Border.all(color: borderColor),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 50, height: 50,
                                    child: CircularProgressIndicator(
                                      value: pct, strokeWidth: 6,
                                      backgroundColor: color.withValues(alpha: 0.15),
                                      color: color,
                                    ),
                                  ),
                                  Text('${(pct * 100).toInt()}%', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('$s / 10', style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = context.read<ProfileProvider>().childName;
                    final avg = gp.quizAverage;
                    final streak = gp.streakCount;
                    String weakest = 'None';
                    if (gp.subjectCounts.isNotEmpty) {
                      weakest = gp.subjectCounts.entries.reduce((a, b) => a.value < b.value ? a : b).key;
                    }
                    final daily = gp.dailyCounts;
                    final weeklyTotal = daily.reduce((a, b) => a + b);
                    final msg = Uri.encodeComponent('📊 *Vaakya Weekly Progress Report*\n\n*Student:* $name\n*Total Weekly Questions:* $weeklyTotal\n*Current Streak:* $streak days\n*Quiz Average:* ${avg.toStringAsFixed(1)}/10\n\n*Depth Engine Insights:*\n- Topics Mastered: ${gp.subjectCounts.length}\n- Most Focus Needed On: $weakest\n\nKeep up the great work! 🚀');
                    final url = Uri.parse('https://wa.me/917975801997?text=$msg');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                    }
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Send Weekly Report to Parents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color, Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
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
          Text(label, style: TextStyle(color: subtextColor, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final Color labelColor;
  _BarChartPainter(this.data, this.labelColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max).toDouble();
    if (maxVal == 0) return;

    final barWidth = (size.width - 40) / 7 - 8;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final count = (i < data.length ? data[i] : 0).toDouble();
      final barHeight = (count / maxVal) * (size.height - 40);
      final x = 20.0 + i * (barWidth + 8);
      final y = size.height - 30 - barHeight;

      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(x, y, barWidth, barHeight), topLeft: const Radius.circular(6), topRight: const Radius.circular(6)), paint);

      final tp = TextPainter(text: TextSpan(text: days[i], style: TextStyle(color: labelColor, fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, size.height - 20));

      if (count > 0) {
        final cp = TextPainter(text: TextSpan(text: '${count.toInt()}', style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
        cp.paint(canvas, Offset(x + barWidth / 2 - cp.width / 2, y - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Color centerColor;
  _PieChartPainter(this.data, this.centerColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final total = data.values.reduce((a, b) => a + b).toDouble();
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final colors = [const Color(0xFF6C63FF), const Color(0xFFFF6584), const Color(0xFF00D2FF), const Color(0xFFFFD700), const Color(0xFF00FF88)];

    double startAngle = -pi / 2;
    int i = 0;
    for (final entry in data.entries) {
      final sweep = (entry.value / total) * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, Paint()..color = colors[i % colors.length]..style = PaintingStyle.fill);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, Paint()..color = centerColor..style = PaintingStyle.stroke..strokeWidth = 3);
      startAngle += sweep;
      i++;
    }
    canvas.drawCircle(center, radius * 0.55, Paint()..color = centerColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
