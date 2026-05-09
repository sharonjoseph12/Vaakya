import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/profile_provider.dart';
import '../widgets/animated_learning_background.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedLearningBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/images/logo.png', width: 180, height: 180),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text('Vaakya', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF))).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text('Your AI-powered study companion', style: GoogleFonts.outfit(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                Text('I am a...', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                _RoleCard(
                  emoji: '🎓', title: 'Student', subtitle: 'Learn with AI, take quizzes, track progress',
                  gradient: const [Color(0xFF6C63FF), Color(0xFF8B7CFF)],
                  delay: 500, onTap: () => _selectRole(context, 'student'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  emoji: '👨‍🏫', title: 'Faculty', subtitle: 'Upload notes, generate quizzes, manage content',
                  gradient: const [Color(0xFFFF6584), Color(0xFFFF8FA3)],
                  delay: 600, onTap: () => _selectRole(context, 'faculty'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  emoji: '👪', title: 'Parent', subtitle: 'View analytics, track learning progress',
                  gradient: const [Color(0xFF00D2FF), Color(0xFF00B4D8)],
                  delay: 700, onTap: () => _selectRole(context, 'parent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String role) async {
    HapticFeedback.mediumImpact();
    final profile = context.read<ProfileProvider>();
    await profile.setRole(role);
    profile.useDemoProfile();
    if (!context.mounted) return;
    switch (role) {
      case 'student': Navigator.pushReplacementNamed(context, '/dashboard'); break;
      case 'faculty': Navigator.pushReplacementNamed(context, '/faculty'); break;
      case 'parent': Navigator.pushReplacementNamed(context, '/parent'); break;
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final int delay;
  final VoidCallback onTap;
  const _RoleCard({required this.emoji, required this.title, required this.subtitle, required this.gradient, required this.delay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
