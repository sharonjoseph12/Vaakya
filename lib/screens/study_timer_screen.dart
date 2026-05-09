import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class SmartPracticeScreen extends StatefulWidget {
  const SmartPracticeScreen({super.key});
  @override
  State<SmartPracticeScreen> createState() => _SmartPracticeScreenState();
}

class _SmartPracticeScreenState extends State<SmartPracticeScreen> {
  final _rng = Random();
  int _currentQ = 0;
  int _score = 0;
  bool _answered = false;
  int _selectedIdx = -1;
  String _weakTopic = '';
  List<_PracticeQ> _questions = [];
  bool _done = false;

  static const _bank = {
    'Math': [
      _PracticeQ('What is the value of sin 30°?', ['0.5', '1', '0.866', '0'], 0, 'sin 30° = 1/2 = 0.5. Remember SOH CAH TOA!'),
      _PracticeQ('Solve: x² - 9 = 0', ['x = ±3', 'x = 3', 'x = 9', 'x = ±9'], 0, 'x² = 9, so x = ±√9 = ±3'),
      _PracticeQ('What is the area of a triangle with base 6 and height 4?', ['12', '24', '10', '8'], 0, 'Area = ½ × base × height = ½ × 6 × 4 = 12'),
      _PracticeQ('What is 15% of 200?', ['30', '15', '20', '25'], 0, '15/100 × 200 = 30'),
      _PracticeQ('If 2x + 5 = 13, what is x?', ['4', '5', '3', '8'], 0, '2x = 13-5 = 8, x = 4'),
    ],
    'Science': [
      _PracticeQ('What is the powerhouse of the cell?', ['Mitochondria', 'Nucleus', 'Ribosome', 'Golgi'], 0, 'Mitochondria produce ATP — the energy currency of the cell.'),
      _PracticeQ('What is the chemical formula of water?', ['H₂O', 'CO₂', 'NaCl', 'O₂'], 0, 'Water = 2 Hydrogen + 1 Oxygen = H₂O'),
      _PracticeQ('Which planet is closest to the Sun?', ['Mercury', 'Venus', 'Mars', 'Earth'], 0, 'Mercury orbits at ~58 million km from the Sun.'),
      _PracticeQ('What is Newton\'s 2nd Law?', ['F = ma', 'E = mc²', 'V = IR', 'PV = nRT'], 0, 'Force = mass × acceleration'),
      _PracticeQ('What gas do plants release during photosynthesis?', ['Oxygen', 'Carbon dioxide', 'Nitrogen', 'Hydrogen'], 0, 'Plants release O₂ as a byproduct of photosynthesis.'),
    ],
    'English': [
      _PracticeQ('Which is the correct sentence?', ['She goes to school daily.', 'She go to school daily.', 'She going to school daily.', 'She gone to school daily.'], 0, 'Third person singular uses "goes" (present simple).'),
      _PracticeQ('What is a synonym of "happy"?', ['Joyful', 'Sad', 'Angry', 'Tired'], 0, 'Joyful means feeling or showing great happiness.'),
      _PracticeQ('Identify the noun: "The cat sat on the mat."', ['cat, mat', 'sat, on', 'the, on', 'sat, mat'], 0, 'Nouns are naming words — cat and mat are things.'),
    ],
    'History': [
      _PracticeQ('Who discovered America in 1492?', ['Columbus', 'Magellan', 'Vasco da Gama', 'Cook'], 0, 'Christopher Columbus sailed from Spain and reached the Americas.'),
      _PracticeQ('The French Revolution began in which year?', ['1789', '1776', '1804', '1815'], 0, 'The storming of the Bastille on July 14, 1789 marked the start.'),
    ],
  };

  @override
  void initState() { super.initState(); _analyze(); }

  void _analyze() {
    final gp = context.read<GamificationProvider>();
    final subjects = gp.subjectCounts;
    // Find weakest topic (least questions asked, or lowest quiz scores)
    String weakest = 'Science';
    int minCount = 999;
    for (final topic in _bank.keys) {
      final count = subjects[topic] ?? 0;
      if (count < minCount) { minCount = count; weakest = topic; }
    }
    final questions = List<_PracticeQ>.from(_bank[weakest] ?? _bank['Science']!);
    questions.shuffle(_rng);
    setState(() { _weakTopic = weakest; _questions = questions.take(5).toList(); });
  }

  void _answer(int idx) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() { _answered = true; _selectedIdx = idx; if (idx == _questions[_currentQ].correctIdx) _score++; });
  }

  void _next() {
    if (_currentQ >= _questions.length - 1) {
      setState(() => _done = true);
      // Record quiz score
      context.read<GamificationProvider>().recordQuizScore(_score * 100 ~/ _questions.length);
      return;
    }
    setState(() { _currentQ++; _answered = false; _selectedIdx = -1; });
  }

  void _restart() { setState(() { _currentQ = 0; _score = 0; _answered = false; _selectedIdx = -1; _done = false; }); _analyze(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final gp = context.watch<GamificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('🎯 Smart Practice', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _done ? _results(textColor, gp) : _quiz(isDark, textColor)),
    );
  }

  Widget _quiz(bool isDark, Color textColor) {
    if (_questions.isEmpty) return Center(child: Text('Loading...', style: GoogleFonts.outfit(color: textColor)));
    final q = _questions[_currentQ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Weak topic badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8FA3)]), borderRadius: BorderRadius.circular(20)),
        child: Text('🎯 Weak Area: $_weakTopic', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ).animate().fadeIn(),
      const SizedBox(height: 16),
      // Progress
      Row(children: [
        Text('Question ${_currentQ + 1}/${_questions.length}', style: GoogleFonts.outfit(fontSize: 14, color: textColor.withValues(alpha: 0.5))),
        const Spacer(),
        Text('Score: $_score', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
        value: (_currentQ + 1) / _questions.length, backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1), color: const Color(0xFF6C63FF), minHeight: 6,
      )),
      const SizedBox(height: 24),
      // Question
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Text(q.question, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: textColor, height: 1.4)),
      ).animate().fadeIn(duration: 300.ms),
      const SizedBox(height: 20),
      // Options
      ...List.generate(q.options.length, (i) {
        final isCorrect = i == q.correctIdx;
        final isSelected = i == _selectedIdx;
        Color borderColor = Theme.of(context).dividerColor;
        Color bgColor = isDark ? const Color(0xFF161B22) : Colors.white;
        if (_answered && isCorrect) { borderColor = Colors.green; bgColor = Colors.green.withValues(alpha: 0.08); }
        else if (_answered && isSelected && !isCorrect) { borderColor = Colors.red; bgColor = Colors.red.withValues(alpha: 0.08); }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _answer(i),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: _answered && (isCorrect || isSelected) ? 2 : 1)),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: borderColor.withValues(alpha: 0.15)),
                  child: Center(child: Text(String.fromCharCode(65 + i), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: textColor))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(q.options[i], style: GoogleFonts.outfit(fontSize: 14, color: textColor))),
                if (_answered && isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
              ]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)),
        );
      }),
      // Explanation
      if (_answered) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Explanation', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
            const SizedBox(height: 6),
            Text(q.explanation, style: GoogleFonts.outfit(fontSize: 13, color: textColor, height: 1.4)),
          ]),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(_currentQ >= _questions.length - 1 ? 'See Results' : 'Next Question', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        )),
      ],
    ]);
  }

  Widget _results(Color textColor, GamificationProvider gp) {
    final pct = _questions.isEmpty ? 0 : (_score * 100 / _questions.length).round();
    final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : pct >= 40 ? '💪' : '📖';
    return Column(children: [
      const SizedBox(height: 20),
      Text(emoji, style: const TextStyle(fontSize: 60)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 16),
      Text('$pct%', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF))),
      Text('$_score/${_questions.length} correct in $_weakTopic', style: GoogleFonts.outfit(fontSize: 16, color: textColor.withValues(alpha: 0.6))),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text('Your Progress', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('🔥', '${gp.streakCount}', 'Day Streak'),
            _stat('📊', '${gp.quizAverage.round()}%', 'Avg Score'),
            _stat('📝', '${gp.totalQuestionsAsked}', 'Questions'),
          ]),
        ]),
      ).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _restart, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: Text('Practice Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      )),
    ]);
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF))),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _PracticeQ {
  final String question;
  final List<String> options;
  final int correctIdx;
  final String explanation;
  const _PracticeQ(this.question, this.options, this.correctIdx, this.explanation);
}
