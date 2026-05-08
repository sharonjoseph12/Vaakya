import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/profile_provider.dart';
import '../providers/gamification_provider.dart';
import '../core/theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final gamification = context.watch<GamificationProvider>();

    return Scaffold(
      backgroundColor: VoiceGuruTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Progress'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Promotion Card ────────────────────────────────────────────────
            _buildPromotionCard(),

            // ── Stat Grid ─────────────────────────────────────────────────────
            _buildStatGrid(profile, gamification),

            // ── Streak Calendar ───────────────────────────────────────────────
            _buildSectionHeader('Streak Calendar'),
            _buildStreakCalendar(gamification),

            // ── Overall Activity ──────────────────────────────────────────────
            _buildSectionHeader('Overall Activity'),
            _buildWeeklyCard(gamification),

            // ── Subjects Explored ─────────────────────────────────────────────
            _buildSectionHeader('What I\'ve Explored'),
            _buildSubjectBreakdown(gamification),

            // ── Achievements ──────────────────────────────────────────────────
            _buildSectionHeader('My Achievements 🏆'),
            _buildAchievementGrid(profile, gamification),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: VoiceGuruTheme.textPrimary)),
    );
  }

  Widget _buildPromotionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Start your learning journey today!', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.purple.shade800, fontSize: 16)),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildStatGrid(ProfileProvider profile, GamificationProvider gamification) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard('Day Streak', '${gamification.streakCount}', VoiceGuruTheme.streakGradient, '🔥'),
          const SizedBox(width: 12),
          _buildStatCard('Stars Earned', '${gamification.totalStars}', VoiceGuruTheme.starGradient, '⭐'),
          const SizedBox(width: 12),
          _buildStatCard('Questions', '${gamification.totalQuestions}', VoiceGuruTheme.questionGradient, '📚'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, LinearGradient gradient, String icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: gradient.colors[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCalendar(GamificationProvider gamification) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final todayIndex = DateTime.now().weekday % 7;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final isToday = i == todayIndex;
          final isStreak = gamification.streakCount > 0 && i <= todayIndex; // Simplified streak visual
          
          return Column(
            children: [
              Container(
                width: 36, height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: isStreak ? VoiceGuruTheme.accentOrange.withValues(alpha: 0.1) : VoiceGuruTheme.backgroundLight, 
                  border: isToday ? Border.all(color: VoiceGuruTheme.accentOrange) : null
                ),
                child: isStreak ? const Icon(Icons.local_fire_department_rounded, size: 20, color: VoiceGuruTheme.accentOrange) : Text(days[i], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VoiceGuruTheme.textSecondary)),
              ),
              const SizedBox(height: 8),
              Text(days[i], style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? VoiceGuruTheme.accentOrange : VoiceGuruTheme.textSecondary)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyCard(GamificationProvider gamification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Real-time stats', style: GoogleFonts.outfit(fontSize: 12, color: VoiceGuruTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            gamification.totalQuestions > 0 
              ? 'You have asked ${gamification.totalQuestions} questions so far! Keep it up!' 
              : 'Start learning to see your progress!', 
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary, fontSize: 14)
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(GamificationProvider gamification) {
    final breakdown = gamification.subjectBreakdown;
    final total = gamification.totalQuestions > 0 ? gamification.totalQuestions : 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _buildSubjectRow('Math', '📐', (breakdown['Math'] ?? 0) / total, Colors.blue, breakdown['Math'] ?? 0),
          _buildSubjectRow('Science', '🔬', (breakdown['Science'] ?? 0) / total, Colors.green, breakdown['Science'] ?? 0),
          _buildSubjectRow('Social Studies', '🌍', (breakdown['Social Studies'] ?? 0) / total, Colors.orange, breakdown['Social Studies'] ?? 0),
          _buildSubjectRow('Other', '💡', (breakdown['Other'] ?? 0) / total, Colors.red, breakdown['Other'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String name, String icon, double progress, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15))),
              Text('$count questions', style: GoogleFonts.outfit(fontSize: 13, color: VoiceGuruTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 8)),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(ProfileProvider profile, GamificationProvider gamification) {
    final unlocked = gamification.badges;
    final achievements = [
      {'name': 'First Question', 'icon': '🌱', 'key': 'First Question'},
      {'name': '3 Day Streak', 'icon': '🔥', 'key': 'Streak Master'},
      {'name': '10 Questions', 'icon': '⭐', 'key': 'Speed Learner'},
      {'name': 'Science Explorer', 'icon': '🔬', 'key': 'Science Explorer'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        final isLocked = !unlocked.contains(ach['key']);
        
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: VoiceGuruTheme.backgroundLight, shape: BoxShape.circle)),
                  Text(ach['icon'] as String, style: const TextStyle(fontSize: 30)),
                  if (isLocked) const Icon(Icons.lock, size: 20, color: Colors.black26),
                ],
              ),
              const SizedBox(height: 8),
              Text(ach['name'] as String, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isLocked ? VoiceGuruTheme.textSecondary : VoiceGuruTheme.primaryPurple)),
            ],
          ),
        );
      },
    );
  }
}
