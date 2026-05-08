import 'package:flutter/material.dart';
import '../core/api_client.dart';

class LeaderboardEntry {
  final String name;
  final int streakCount;
  final String grade;
  final String board;

  LeaderboardEntry({
    required this.name,
    required this.streakCount,
    required this.grade,
    required this.board,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] ?? 'Unknown',
      streakCount: json['streak_count'] ?? 0,
      grade: json['grade'] ?? '',
      board: json['board'] ?? '',
    );
  }
}

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;

  List<LeaderboardEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/v1/leaderboard/');
      if (response != null && response is List) {
        _entries = response.map((e) => LeaderboardEntry.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Leaderboard fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
