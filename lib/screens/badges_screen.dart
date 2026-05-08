import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gamification_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('My Badges', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gp, _) {
          final allBadges = GamificationProvider.badgeDefinitions;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        '${gp.streakCount} Day Streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep learning every day!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                const SizedBox(height: 28),
                const Text(
                  'Achievements',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                // Badge grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: allBadges.entries.map((entry) {
                      final name = entry.key;
                      final info = entry.value;
                      final unlocked = gp.badges.contains(name);

                      return Container(
                        decoration: BoxDecoration(
                          color: unlocked
                              ? Color(info['color'] as int).withValues(alpha: 0.1)
                              : const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: unlocked
                                ? Color(info['color'] as int).withValues(alpha: 0.5)
                                : const Color(0xFF30363D),
                            width: unlocked ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              info['icon'] as String,
                              style: TextStyle(
                                fontSize: 40,
                                color: unlocked ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: unlocked ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                info['description'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: unlocked ? Colors.white54 : Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (unlocked) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(info['color'] as int).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✓ Unlocked',
                                  style: TextStyle(
                                    color: Color(info['color'] as int),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              const Icon(Icons.lock_outline, color: Colors.white24, size: 18),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
