import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gamification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../core/local_db.dart';


class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  List<Map<String, dynamic>> _bookmarks = [];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final b = await LocalDatabase.instance.getBookmarks();
    setState(() => _bookmarks = b);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('👪 Parent Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(context.watch<ThemeProvider>().isDark ? Icons.light_mode : Icons.dark_mode), onPressed: () => context.read<ThemeProvider>().toggleTheme()),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () { context.read<ProfileProvider>().setRole(''); Navigator.pushReplacementNamed(context, '/role'); }),
        ],
      ),
      body: Consumer<GamificationProvider>(builder: (context, gp, _) {
        final totalQ = gp.totalQuestionsAsked;
        final streak = gp.streakCount;
        final avg = gp.quizAverage;
        final scores = gp.quizScores;
        final subjects = gp.subjectCounts;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Child info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF00B4D8)]), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Text('🎓', style: TextStyle(fontSize: 28))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.read<ProfileProvider>().childName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Grade ${context.read<ProfileProvider>().grade} • ${context.read<ProfileProvider>().board}', style: GoogleFonts.outfit(color: Colors.white70)),
                ])),
              ]),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),
            Text('Learning Overview', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 16),

            // Stats row
            Row(children: [
              _stat('📚', '$totalQ', 'Questions Asked', const Color(0xFF6C63FF), cardColor, textColor, subtextColor),
              const SizedBox(width: 12),
              _stat('🔥', '$streak', 'Day Streak', const Color(0xFFFF6584), cardColor, textColor, subtextColor),
              const SizedBox(width: 12),
              _stat('📊', avg > 0 ? '${avg.toStringAsFixed(1)}/10' : 'N/A', 'Quiz Average', const Color(0xFF00D2FF), cardColor, textColor, subtextColor),
            ]).animate().fadeIn(delay: 200.ms),

            // Quiz performance
            if (scores.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recent Quiz Scores', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(children: scores.reversed.take(5).map((s) {
                  final pct = s / 10;
                  final color = pct >= 0.8 ? const Color(0xFF00FF88) : pct >= 0.5 ? const Color(0xFFFFD700) : const Color(0xFFFF6584);
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
                    Text('$s/10', style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 16),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: color.withValues(alpha: 0.15), color: color, minHeight: 8))),
                    const SizedBox(width: 12),
                    Text('${(pct * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 13, color: subtextColor)),
                  ]));
                }).toList()),
              ).animate().fadeIn(delay: 400.ms),
            ],

            // Subject breakdown
            if (subjects.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Subjects Studied', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 12),
              ...subjects.entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Row(children: [
                  Text('📖', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${e.value} questions', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600))),
                ]),
              )),
            ],

            // Saved notes
            if (_bookmarks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Student\'s Saved Notes', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 12),
              ..._bookmarks.take(5).map((n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Text(n['text']?.toString().substring(0, (n['text']?.toString().length ?? 0).clamp(0, 120)) ?? '', style: GoogleFonts.outfit(fontSize: 13, color: subtextColor, height: 1.4)),
              )),
            ],
          ]),
        );
      }),
    );
  }

  Widget _stat(String emoji, String val, String label, Color color, Color cardColor, Color textColor, Color subtextColor) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(val, style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(color: subtextColor, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ));
  }
}
