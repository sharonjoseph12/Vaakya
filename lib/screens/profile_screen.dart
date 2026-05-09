import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _board;
  late String _language;
  late double _levelValue; // 0=Beginner, 1=Intermediate, 2=Advanced
  late String _grade;
  late TextEditingController _nameCtrl;
  bool _saving = false;

  static const boards = ['CBSE', 'ICSE', 'STATE'];
  static const languages = [
    {'code': 'en-IN', 'label': 'English'},
    {'code': 'hi-IN', 'label': 'हिन्दी'},
    {'code': 'ta-IN', 'label': 'தமிழ்'},
    {'code': 'te-IN', 'label': 'తెలుగు'},
    {'code': 'kn-IN', 'label': 'ಕನ್ನಡ'},
  ];
  static const levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const grades = ['5', '6', '7', '8', '9', '10', '11', '12'];

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _board = p.board;
    _language = p.language;
    _levelValue = levels.indexOf(p.learnerLevel).toDouble().clamp(0, 2);
    _grade = p.grade;
    _nameCtrl = TextEditingController(text: p.childName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _currentLevel => levels[_levelValue.round()];

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<ProfileProvider>().updateProfile(
      name: _nameCtrl.text.trim(),
      board: _board,
      language: _language,
      learnerLevel: _currentLevel,
      grade: _grade,
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated! ✨',
              style: GoogleFonts.outfit()),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name
            Center(
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: VoiceGuruTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: VoiceGuruTheme.primaryPurple
                            .withValues(alpha: 0.3),
                        blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded,
                      size: 36, color: Colors.white),
                ).animate().scale(
                    duration: 400.ms,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut),
                const SizedBox(height: 16),
              ]),
            ),

            // Name field
            _sectionLabel('Name'),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.outfit(fontSize: 16),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_rounded,
                    color: VoiceGuruTheme.primaryPurple),
              ),
            ),
            const SizedBox(height: 24),

            // Board selector
            _sectionLabel('Board'),
            _chipRow<String>(
              items: boards,
              selected: _board,
              labelOf: (b) => b,
              onTap: (b) => setState(() => _board = b),
            ),
            const SizedBox(height: 24),

            // Grade selector
            _sectionLabel('Grade'),
            _chipRow<String>(
              items: grades,
              selected: _grade,
              labelOf: (g) => 'Class $g',
              onTap: (g) => setState(() => _grade = g),
            ),
            const SizedBox(height: 24),

            // Language selector
            _sectionLabel('Language'),
            _chipRow<Map<String, String>>(
              items: languages,
              selected: languages
                  .firstWhere((l) => l['code'] == _language,
                      orElse: () => languages[0]),
              labelOf: (l) => l['label']!,
              onTap: (l) => setState(() => _language = l['code']!),
            ),
            const SizedBox(height: 24),

            // Difficulty Level — SLIDER
            _sectionLabel('Difficulty Level'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(
                        _levelValue.round() == 0 ? Icons.child_care_rounded
                            : _levelValue.round() == 1 ? Icons.trending_up_rounded
                            : Icons.rocket_launch_rounded,
                        color: VoiceGuruTheme.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_currentLevel,
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _levelValue.round() == 0 ? 'Easy' : _levelValue.round() == 1 ? 'Medium' : 'Hard',
                        style: GoogleFonts.outfit(
                            color: VoiceGuruTheme.primaryPurple,
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: VoiceGuruTheme.primaryPurple,
                    inactiveTrackColor: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.2),
                    thumbColor: VoiceGuruTheme.primaryPurple,
                    overlayColor: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.1),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _levelValue,
                    min: 0,
                    max: 2,
                    divisions: 2,
                    onChanged: (v) => setState(() => _levelValue = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Beginner', style: GoogleFonts.outfit(fontSize: 11, color: VoiceGuruTheme.textSecondary)),
                    Text('Intermediate', style: GoogleFonts.outfit(fontSize: 11, color: VoiceGuruTheme.textSecondary)),
                    Text('Advanced', style: GoogleFonts.outfit(fontSize: 11, color: VoiceGuruTheme.textSecondary)),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 36),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }

  Widget _chipRow<T>({
    required List<T> items,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onTap,
    List<IconData>? icons,
  }) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? VoiceGuruTheme.primaryPurple.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? VoiceGuruTheme.primaryPurple
                    : VoiceGuruTheme.surfaceElevated,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icons != null) ...[
                Icon(icons[i],
                    size: 16,
                    color: isSelected
                        ? VoiceGuruTheme.primaryPurpleLight
                        : VoiceGuruTheme.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(labelOf(item),
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        );
      }),
    );
  }
}
