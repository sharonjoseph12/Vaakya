import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationProvider extends ChangeNotifier {
  int _streakCount = 0;
  List<String> _badges = [];
  bool _streakJustIncremented = false;
  int _scienceQueryCount = 0;
  int _visionHintCount = 0;

  int get streakCount => _streakCount;
  List<String> get badges => _badges;
  bool get streakJustIncremented => _streakJustIncremented;

  // Badge definitions
  static const Map<String, Map<String, dynamic>> badgeDefinitions = {
    'Science Explorer': {
      'icon': '🔬',
      'description': '10 science queries answered',
      'color': 0xFF4CAF50,
    },
    'Math Wizard': {
      'icon': '🧙',
      'description': '5 vision hints solved',
      'color': 0xFF9C27B0,
    },
    'Speed Learner': {
      'icon': '⚡',
      'description': 'Completed quiz under 30 seconds',
      'color': 0xFFFF9800,
    },
    'Streak Master': {
      'icon': '🔥',
      'description': '7-day learning streak',
      'color': 0xFFF44336,
    },
  };

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _streakCount = prefs.getInt('streak_count') ?? 0;
    _badges = prefs.getStringList('badges_unlocked') ?? [];
    _scienceQueryCount = prefs.getInt('science_query_count') ?? 0;
    _visionHintCount = prefs.getInt('vision_hint_count') ?? 0;
    notifyListeners();
  }

  /// Call this every time a question is asked. Checks if it's a new day.
  Future<bool> onQuestionAsked({String? subject}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('last_question_date') ?? '';

    _streakJustIncremented = false;

    if (lastDate != today) {
      // Check if it's consecutive (yesterday)
      if (lastDate.isNotEmpty) {
        final last = DateTime.parse(lastDate);
        final now = DateTime.now();
        final diff = now.difference(last).inDays;
        if (diff == 1) {
          _streakCount++;
        } else if (diff > 1) {
          _streakCount = 1; // Reset streak
        }
      } else {
        _streakCount = 1;
      }

      await prefs.setString('last_question_date', today);
      await prefs.setInt('streak_count', _streakCount);
      _streakJustIncremented = true;
    }

    // Track subject-specific counts
    if (subject?.toLowerCase() == 'science') {
      _scienceQueryCount++;
      await prefs.setInt('science_query_count', _scienceQueryCount);
    }

    // Check badge unlocks
    await _checkBadges(prefs);

    notifyListeners();
    return _streakJustIncremented;
  }

  Future<void> onVisionHintUsed() async {
    final prefs = await SharedPreferences.getInstance();
    _visionHintCount++;
    await prefs.setInt('vision_hint_count', _visionHintCount);
    await _checkBadges(prefs);
    notifyListeners();
  }

  Future<void> _checkBadges(SharedPreferences prefs) async {
    bool changed = false;

    if (_scienceQueryCount >= 10 && !_badges.contains('Science Explorer')) {
      _badges.add('Science Explorer');
      changed = true;
    }
    if (_visionHintCount >= 5 && !_badges.contains('Math Wizard')) {
      _badges.add('Math Wizard');
      changed = true;
    }
    if (_streakCount >= 7 && !_badges.contains('Streak Master')) {
      _badges.add('Streak Master');
      changed = true;
    }

    if (changed) {
      await prefs.setStringList('badges_unlocked', _badges);
    }
  }

  Future<void> onQuizCompletedFast() async {
    if (!_badges.contains('Speed Learner')) {
      final prefs = await SharedPreferences.getInstance();
      _badges.add('Speed Learner');
      await prefs.setStringList('badges_unlocked', _badges);
      notifyListeners();
    }
  }

  void clearStreakFlag() {
    _streakJustIncremented = false;
  }
}
