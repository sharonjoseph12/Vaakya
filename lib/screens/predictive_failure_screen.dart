import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class PredictiveFailureScreen extends StatelessWidget {
  const PredictiveFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: Text('⚠️ Predictive Failure Engine', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Consumer<GamificationProvider>(builder: (context, gp, _) {
        final rights = gp.subjectCounts;
        final wrongs = gp.subjectWrongs;
        
        // Combine all topics that have either a right or a wrong answer
        final allTopics = <String>{...rights.keys, ...wrongs.keys}.toList();

        if (allTopics.isEmpty) {
          return Center(child: Text('Not enough data to predict risk. Play some games!', style: GoogleFonts.outfit(fontSize: 16, color: tc.withValues(alpha: 0.5))));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Exam Risk Assessment', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFFFF5252))),
            const SizedBox(height: 8),
            Text('Topics at risk based on your quiz mistakes.', style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.8), height: 1.5)),
            const SizedBox(height: 32),
            
            ...allTopics.map((topic) {
              final r = rights[topic] ?? 0;
              final w = wrongs[topic] ?? 0;
              final attempts = r + w;
              
              double completionPct = attempts == 0 ? 0.0 : (r / attempts) * 100;
              
              // If wrongs are high, it's at risk.
              final isHighRisk = w > 0 && completionPct < 70.0;
              final marksLost = (w * 2.5).clamp(0.0, 100.0).toStringAsFixed(1);
              
              String solution = 'Review your notes and try answering more quizzes.';
              if (topic == 'Math') solution = 'Focus on algebraic formulas and speed calculation tricks.';
              if (topic == 'Science') solution = 'Review physics definitions and biological terms carefully.';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isHighRisk ? Colors.red.withValues(alpha: 0.05) : cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isHighRisk ? Colors.red.withValues(alpha: 0.4) : Theme.of(context).dividerColor, width: isHighRisk ? 2 : 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(isHighRisk ? Icons.warning_rounded : Icons.check_circle_outline_rounded, color: isHighRisk ? Colors.red : Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text(topic, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: tc))),
                      if (isHighRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('AT RISK', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.red, fontSize: 12)),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    _statRow('Completion:', '${completionPct.toStringAsFixed(1)}%', tc),
                    _statRow('Course Attempts:', '$attempts (Correct: $r, Wrong: $w)', tc),
                    if (isHighRisk) _statRow('Marks at Risk:', '▼ $marksLost Marks', Colors.red),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    
                    Text('💡 Solution to recover marks:', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: tc)),
                    const SizedBox(height: 4),
                    Text(solution, style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.7), height: 1.4)),
                  ]
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
            }),
            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  Widget _statRow(String label, String val, Color tc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.6))),
          Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: tc)),
        ],
      ),
    );
  }
}
