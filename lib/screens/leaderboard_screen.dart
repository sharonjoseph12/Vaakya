import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/leaderboard_provider.dart';
import '../core/theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoiceGuruTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Top Gurus'),
        centerTitle: true,
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.leaderboard_outlined, size: 64, color: VoiceGuruTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text('No data yet!', style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              return _buildLeaderboardTile(entry, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int index) {
    final isTopThree = index < 3;
    final color = switch (index) {
      0 => const Color(0xFFFFD700), // Gold
      1 => const Color(0xFFC0C0C0), // Silver
      2 => const Color(0xFFCD7F32), // Bronze
      _ => VoiceGuruTheme.textSecondary.withValues(alpha: 0.1),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
        border: isTopThree ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopThree ? color : VoiceGuruTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.outfit(
                color: isTopThree ? Colors.white : VoiceGuruTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.outfit(
                    color: VoiceGuruTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry.grade} • ${entry.board}',
                  style: GoogleFonts.outfit(
                    color: VoiceGuruTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.streakCount}',
                style: GoogleFonts.outfit(
                  color: VoiceGuruTheme.accentOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                'STREAK',
                style: GoogleFonts.outfit(
                  color: VoiceGuruTheme.accentOrange.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
  }
}
