import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});
  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  final _rng = Random();
  int _current = 0;
  int _score = 0;
  bool _revealed = false;
  final _controller = TextEditingController();
  String _feedback = '';

  static const _words = [
    _Word('PHOTOSYNTHESIS', 'Process by which plants make food using sunlight'),
    _Word('MITOCHONDRIA', 'Powerhouse of the cell that produces ATP'),
    _Word('TRIGONOMETRY', 'Branch of math dealing with triangles and angles'),
    _Word('CHROMOSOME', 'Thread-like structure carrying genetic information'),
    _Word('EVAPORATION', 'Process where liquid turns to gas at the surface'),
    _Word('POLYNOMIAL', 'An expression with multiple algebraic terms'),
    _Word('HYPOTHESIS', 'A proposed explanation for an observation'),
    _Word('ACCELERATION', 'Rate of change of velocity over time'),
    _Word('ELECTROLYSIS', 'Chemical decomposition using electric current'),
    _Word('QUADRILATERAL', 'A polygon with exactly four sides'),
    _Word('ECOSYSTEM', 'Community of living organisms and their environment'),
    _Word('ISOTOPE', 'Atoms with same protons but different neutrons'),
  ];

  late List<_Word> _shuffledWords;

  @override
  void initState() {
    super.initState();
    _shuffledWords = List.from(_words)..shuffle(_rng);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  String _scramble(String word) {
    final chars = word.split('');
    for (int i = chars.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final temp = chars[i]; chars[i] = chars[j]; chars[j] = temp;
    }
    final result = chars.join();
    return result == word ? _scramble(word) : result;
  }

  void _check() {
    HapticFeedback.mediumImpact();
    final answer = _controller.text.trim().toUpperCase();
    final correct = _shuffledWords[_current].word;
    if (answer == correct) {
      setState(() { _score++; _feedback = '✅ Correct!'; _revealed = true; });
    } else {
      setState(() { _feedback = '❌ The answer was: $correct'; _revealed = true; });
    }
  }

  void _next() {
    if (_current >= _shuffledWords.length - 1) {
      _shuffledWords.shuffle(_rng);
      setState(() { _current = 0; _revealed = false; _feedback = ''; _controller.clear(); });
      return;
    }
    setState(() { _current++; _revealed = false; _feedback = ''; _controller.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final w = _shuffledWords[_current];
    final scrambled = _scramble(w.word);

    return Scaffold(
      appBar: AppBar(title: Text('🔤 Word Scramble', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true,
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('Score: $_score', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF00D2FF)))))]),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        // Progress
        Text('${_current + 1}/${_shuffledWords.length}', style: GoogleFonts.outfit(fontSize: 13, color: tc.withValues(alpha: 0.4))),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_current + 1) / _shuffledWords.length, backgroundColor: const Color(0xFF00D2FF).withValues(alpha: 0.1), color: const Color(0xFF00D2FF), minHeight: 5)),
        const SizedBox(height: 24),
        // Hint
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF00D2FF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.2))),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(w.hint, style: GoogleFonts.outfit(fontSize: 13, color: tc.withValues(alpha: 0.7)))),
          ]),
        ).animate().fadeIn(),
        const Spacer(),
        // Scrambled word
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
          children: scrambled.split('').map((c) => Container(
            width: 36, height: 44,
            decoration: BoxDecoration(color: const Color(0xFF00D2FF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.3))),
            child: Center(child: Text(c, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF00D2FF)))),
          )).toList(),
        ).animate(key: ValueKey(_current)).fadeIn(duration: 300.ms),
        const SizedBox(height: 28),
        // Input
        if (!_revealed) ...[
          TextField(
            controller: _controller, textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: 'Type the word...', hintStyle: GoogleFonts.outfit(color: tc.withValues(alpha: 0.3)),
              filled: true, fillColor: isDark ? const Color(0xFF161B22) : const Color(0xFFF5F3FF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _check, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Check', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          )),
        ],
        if (_revealed) ...[
          Text(_feedback, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: _feedback.startsWith('✅') ? Colors.green : Colors.red)).animate().fadeIn(),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Next Word', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          )),
        ],
        const Spacer(),
      ])),
    );
  }
}

class _Word { final String word, hint; const _Word(this.word, this.hint); }
