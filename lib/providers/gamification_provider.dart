import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationProvider extends ChangeNotifier {
  int _streakCount = 0;
  List<String> _badges = [];
  bool _streakJustIncremented = false;
  int _scienceQueryCount = 0;
  int _visionHintCount = 0;

  // Analytics tracking
  int _totalQuestionsAsked = 0;
  List<int> _quizScores = [];
  Map<String, int> _subjectCounts = {};
  Map<String, int> _subjectWrongs = {};
  List<int> _dailyCounts = [0, 0, 0, 0, 0, 0, 0]; // Mon-Sun

  int get streakCount => _streakCount;
  List<String> get badges => _badges;
  bool get streakJustIncremented => _streakJustIncremented;
  int get totalQuestionsAsked => _totalQuestionsAsked;
  List<int> get quizScores => _quizScores;
  Map<String, int> get subjectCounts => _subjectCounts;
  Map<String, int> get subjectWrongs => _subjectWrongs;
  List<int> get dailyCounts => _dailyCounts;
  double get quizAverage => _quizScores.isEmpty ? 0 : _quizScores.reduce((a, b) => a + b) / _quizScores.length;

  /// Topic mastery: 0-4 = Beginner, 5-14 = Intermediate, 15+ = Advanced
  String getLevelForTopic(String topic) {
    final count = _subjectCounts[topic] ?? 0;
    if (count >= 15) return 'Advanced';
    if (count >= 5) return 'Intermediate';
    return 'Beginner';
  }

  String get overallLevel {
    if (_totalQuestionsAsked >= 50) return 'Advanced';
    if (_totalQuestionsAsked >= 15) return 'Intermediate';
    return 'Beginner';
  }

  static const Map<String, Map<String, dynamic>> badgeDefinitions = {
    'Science Explorer': {'icon': '🔬', 'description': '10 science queries answered', 'color': 0xFF4CAF50},
    'Math Wizard': {'icon': '🧙', 'description': '5 vision hints solved', 'color': 0xFF9C27B0},
    'Speed Learner': {'icon': '⚡', 'description': 'Completed quiz under 60 seconds', 'color': 0xFFFF9800},
    'Streak Master': {'icon': '🔥', 'description': '7-day learning streak', 'color': 0xFFF44336},
  };

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _streakCount = prefs.getInt('streak_count') ?? 0;
    _badges = prefs.getStringList('badges_unlocked') ?? [];
    _scienceQueryCount = prefs.getInt('science_query_count') ?? 0;
    _visionHintCount = prefs.getInt('vision_hint_count') ?? 0;
    _totalQuestionsAsked = prefs.getInt('total_questions') ?? 0;

    final scoresStr = prefs.getStringList('quiz_scores') ?? [];
    _quizScores = scoresStr.map((s) => int.tryParse(s) ?? 0).toList();

    final subjectStr = prefs.getString('subject_counts');
    if (subjectStr != null) {
      _subjectCounts = Map<String, int>.from(jsonDecode(subjectStr));
    }

    final wrongsStr = prefs.getString('subject_wrongs');
    if (wrongsStr != null) {
      _subjectWrongs = Map<String, int>.from(jsonDecode(wrongsStr));
    }

    final dailyStr = prefs.getStringList('daily_counts');
    if (dailyStr != null && dailyStr.length == 7) {
      _dailyCounts = dailyStr.map((s) => int.tryParse(s) ?? 0).toList();
    }

    notifyListeners();
  }

  Future<bool> onQuestionAsked({String? subject}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('last_question_date') ?? '';

    _streakJustIncremented = false;
    _totalQuestionsAsked++;
    await prefs.setInt('total_questions', _totalQuestionsAsked);

    // Track daily count
    final dayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    _dailyCounts[dayIndex]++;
    await prefs.setStringList('daily_counts', _dailyCounts.map((c) => c.toString()).toList());

    if (lastDate != today) {
      if (lastDate.isNotEmpty) {
        final last = DateTime.parse(lastDate);
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) {
          _streakCount++;
        } else if (diff > 1) {
          _streakCount = 1;
        }
      } else {
        _streakCount = 1;
      }
      await prefs.setString('last_question_date', today);
      await prefs.setInt('streak_count', _streakCount);
      _streakJustIncremented = true;
    }

    // Track subject
    if (subject != null && subject.isNotEmpty) {
      _subjectCounts[subject] = (_subjectCounts[subject] ?? 0) + 1;
      await prefs.setString('subject_counts', jsonEncode(_subjectCounts));
    }

    if (subject?.toLowerCase() == 'science') {
      _scienceQueryCount++;
      await prefs.setInt('science_query_count', _scienceQueryCount);
    }

    await _checkBadges(prefs);
    notifyListeners();
    return _streakJustIncremented;
  }

  Future<void> recordQuizScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    _quizScores.add(score);
    if (_quizScores.length > 20) _quizScores.removeAt(0); // Keep last 20
    await prefs.setStringList('quiz_scores', _quizScores.map((s) => s.toString()).toList());
    notifyListeners();
  }

  Future<void> onQuestionFailed({required String subject}) async {
    final prefs = await SharedPreferences.getInstance();
    _subjectWrongs[subject] = (_subjectWrongs[subject] ?? 0) + 1;
    await prefs.setString('subject_wrongs', jsonEncode(_subjectWrongs));
    notifyListeners();
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
    if (_scienceQueryCount >= 10 && !_badges.contains('Science Explorer')) { _badges.add('Science Explorer'); changed = true; }
    if (_visionHintCount >= 5 && !_badges.contains('Math Wizard')) { _badges.add('Math Wizard'); changed = true; }
    if (_streakCount >= 7 && !_badges.contains('Streak Master')) { _badges.add('Streak Master'); changed = true; }
    if (changed) await prefs.setStringList('badges_unlocked', _badges);
  }

  Future<void> onQuizCompletedFast() async {
    if (!_badges.contains('Speed Learner')) {
      final prefs = await SharedPreferences.getInstance();
      _badges.add('Speed Learner');
      await prefs.setStringList('badges_unlocked', _badges);
      notifyListeners();
    }
  }

  void clearStreakFlag() { _streakJustIncremented = false; }
}
