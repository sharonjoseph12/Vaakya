import 'package:flutter/foundation.dart';
import '../core/supabase_config.dart';

/// Manages child profile data from Supabase.
class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  // Demo mode fallback profile ID
  static const String _demoProfileId = 'demo-child-001';

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get profileId =>
      _profile?['id'] as String? ?? _demoProfileId;
  String get childName =>
      _profile?['name'] as String? ?? 'Student';
  String get grade =>
      _profile?['grade'] as String? ?? '8';
  String get board =>
      _profile?['board'] as String? ?? 'CBSE';
  String get language =>
      _profile?['language'] as String? ?? 'en-IN';
  String get learnerLevel =>
      _profile?['learner_level'] as String? ?? 'Intermediate';
  int get streakCount =>
      _profile?['streak_count'] as int? ?? 0;
  List<String> get badgesUnlocked =>
      (_profile?['badges_unlocked'] as List<dynamic>?)
          ?.cast<String>() ??
      [];

  /// Load profile from Supabase by child ID.
  Future<void> loadProfile(String childId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('children')
          .select()
          .eq('id', childId)
          .single();

      _profile = response;
      _error = null;
    } catch (e) {
      debugPrint('Profile load error: $e');
      _error = 'Could not load profile';
      // Use demo profile for development
      _profile = _demoProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the first child profile for the logged-in parent.
  Future<void> loadFirstChildForParent(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('children')
          .select()
          .eq('parent_id', parentId)
          .limit(1)
          .single();

      _profile = response;
      _error = null;
    } catch (e) {
      debugPrint('Load child for parent error: $e');
      _error = 'No child profile found';
      _profile = _demoProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile fields in Supabase.
  Future<void> updateProfile({
    String? board,
    String? language,
    String? learnerLevel,
    String? grade,
    String? name,
  }) async {
    final updates = <String, dynamic>{};
    if (board != null) updates['board'] = board;
    if (language != null) updates['language'] = language;
    if (learnerLevel != null) updates['learner_level'] = learnerLevel;
    if (grade != null) updates['grade'] = grade;
    if (name != null) updates['name'] = name;

    if (updates.isEmpty) return;

    try {
      await SupabaseConfig.client
          .from('children')
          .update(updates)
          .eq('id', profileId);

      // Update local profile
      _profile?.addAll(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Profile update error: $e');
    }
  }

  /// Use demo profile (for development without backend).
  void useDemoProfile() {
    _profile = _demoProfile();
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic> _demoProfile() => {
        'id': _demoProfileId,
        'name': 'Student',
        'grade': '8',
        'board': 'CBSE',
        'language': 'en-IN',
        'learner_level': 'Intermediate',
        'streak_count': 0,
        'badges_unlocked': <String>[],
      };
}
