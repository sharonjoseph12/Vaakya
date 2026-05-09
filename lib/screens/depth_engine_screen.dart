import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import 'predictive_failure_screen.dart';

class DepthEngineScreen extends StatelessWidget {
  const DepthEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: Text('🧠 Depth Engine', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Consumer<GamificationProvider>(builder: (context, gp, _) {
        final subjects = gp.subjectCounts;
        final avg = gp.quizAverage;

        if (subjects.isEmpty) {
          return Center(child: Text('Not enough data. Take more quizzes!', style: GoogleFonts.outfit(fontSize: 16, color: tc.withValues(alpha: 0.5))));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Life Depth Engine', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF))),
            const SizedBox(height: 4),
            Text('How far you have come on each topic', style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            ...subjects.entries.map((e) {
              final qCount = e.value;
              String depthName;
              Color depthColor;
              double depthLevel; // 0.0 to 1.0
              if (qCount < 5) { depthName = 'Surface Water'; depthColor = const Color(0xFF00D2FF); depthLevel = 0.2; }
              else if (qCount < 15) { depthName = 'Twilight Zone'; depthColor = const Color(0xFF6C63FF); depthLevel = 0.5; }
              else if (qCount < 30) { depthName = 'Midnight Zone'; depthColor = const Color(0xFF9D4EDD); depthLevel = 0.8; }
              else { depthName = 'Abyssal Mastery'; depthColor = const Color(0xFFD90429); depthLevel = 1.0; }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: depthColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(e.key, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: tc)),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: depthColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(depthName, style: GoogleFonts.outfit(color: depthColor, fontSize: 12, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: depthLevel, minHeight: 12, backgroundColor: depthColor.withValues(alpha: 0.15), color: depthColor)),
                  const SizedBox(height: 8),
                  Text('$qCount questions mastered', style: GoogleFonts.outfit(fontSize: 12, color: tc.withValues(alpha: 0.5))),
                ]),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
            }),
            
            // Life Depth Engine Metrics
            const SizedBox(height: 32),
            Text('Life Depth Engine', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF00D2FF))),
            const SizedBox(height: 16),
            
            _metricRow(context, '📚 Course Progress', '${(gp.totalQuestionsAsked ~/ 10)} lessons completed', tc, cardColor),
            _metricRow(context, '⏱️ Avg Time / Lesson', '${(gp.totalQuestionsAsked ~/ 10) == 0 ? 2 : (gp.totalQuestionsAsked * 2) ~/ (gp.totalQuestionsAsked ~/ 10)} mins/lesson', tc, cardColor),
            _metricRow(context, '⚡ Learning Efficiencies', '${(avg * 10).toStringAsFixed(1)}% efficiency', tc, cardColor),
            
            // Concept Knowledge Map
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔗 Concept Knowledge Maps', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: tc)),
                const SizedBox(height: 8),
                Text('Visualize how your learned subjects interlink.', style: GoogleFonts.outfit(fontSize: 13, color: tc.withValues(alpha: 0.6))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: subjects.keys.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                  )).toList(),
                ),
              ]),
            ),
            
            // Learning Timeline
            const SizedBox(height: 24),
            Text('Learning Timeline', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: tc)),
            const SizedBox(height: 12),
            ...List.generate((gp.totalQuestionsAsked ~/ 10).clamp(0, 5), (i) {
              final lessonNum = i + 1;
              final subj = subjects.keys.elementAt(i % (subjects.keys.isEmpty ? 1 : subjects.keys.length));
              final timeTaken = 15 + (i * 2);
              final eff = 70 + (i * 5);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: const Color(0xFF6C63FF).withValues(alpha: 0.5), width: 4)),
                  color: cardColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lesson $lessonNum: $subj', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: tc)),
                    const SizedBox(height: 4),
                    Text('Time taken: $timeTaken mins • Efficiency: $eff%', style: GoogleFonts.outfit(fontSize: 13, color: tc.withValues(alpha: 0.6))),
                  ],
                ),
              );
            }),
            if ((gp.totalQuestionsAsked ~/ 10) == 0)
              Text('Complete your first 10 questions to unlock the timeline!', style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.5))),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictiveFailureScreen()));
              },
              icon: const Icon(Icons.warning_rounded, color: Colors.white),
              label: Text('Open Predictive Failure Engine', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _metricRow(BuildContext context, String title, String value, Color tc, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        children: [
          Expanded(child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: tc))),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF6C63FF))),
        ],
      ),
    );
  }
}
