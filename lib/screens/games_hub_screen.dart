import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'study_timer_screen.dart';
import 'speed_round_screen.dart';
import 'word_scramble_screen.dart';
import 'match_pairs_screen.dart';
import 'math_ninja_screen.dart';
import 'memory_matrix_screen.dart';
import '../widgets/premium_background.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Scaffold(
      appBar: AppBar(
        title: Text('🎮 Games Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Learning Path', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: textColor)).animate().fadeIn(),
            const SizedBox(height: 4),
            Text('Progress from beginner to advanced!', style: GoogleFonts.outfit(fontSize: 14, color: textColor.withValues(alpha: 0.5))).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            
            _buildCategory('🌱 Basic', [
              _GameCard(
                icon: Icons.bolt_rounded, title: 'Speed Round', subtitle: '60s rapid-fire True/False',
                gradient: const [Color(0xFFFF6584), Color(0xFFFF8FA3)], delay: 200,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedRoundScreen())); },
              ),
              _GameCard(
                icon: Icons.grid_view_rounded, title: 'Match Pairs', subtitle: 'Match terms & definitions',
                gradient: const [Color(0xFF00C853), Color(0xFF00E676)], delay: 300,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchPairsScreen())); },
              ),
            ], textColor),
            
            const SizedBox(height: 24),
            
            _buildCategory('📘 Intermediate', [
              _GameCard(
                icon: Icons.abc_rounded, title: 'Word Scramble', subtitle: 'Unscramble science terms',
                gradient: const [Color(0xFF00D2FF), Color(0xFF00B4D8)], delay: 400,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const WordScrambleScreen())); },
              ),
              _GameCard(
                icon: Icons.track_changes_rounded, title: 'Smart Practice', subtitle: 'AI targets your weak topics',
                gradient: const [Color(0xFF6C63FF), Color(0xFF8B7CFF)], delay: 500,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartPracticeScreen())); },
              ),
            ], textColor),
            
            const SizedBox(height: 24),
            
            _buildCategory('⚡ Advanced', [
              _GameCard(
                icon: Icons.calculate_rounded, title: 'Math Ninja', subtitle: 'Fast-paced equation solving',
                gradient: const [Color(0xFFFF3D00), Color(0xFFFF9100)], delay: 600,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const MathNinjaScreen())); },
              ),
              _GameCard(
                icon: Icons.memory_rounded, title: 'Memory Matrix', subtitle: 'Memorize visual patterns',
                gradient: const [Color(0xFFD500F9), Color(0xFFE040FB)], delay: 700,
                onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryMatrixScreen())); },
              ),
            ], textColor),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategory(String title, List<Widget> cards, Color tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: tc)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  final int delay;
  final VoidCallback onTap;
  const _GameCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.delay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
