import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchPairsScreen extends StatefulWidget {
  const MatchPairsScreen({super.key});
  @override
  State<MatchPairsScreen> createState() => _MatchPairsScreenState();
}

class _MatchPairsScreenState extends State<MatchPairsScreen> {
  final _rng = Random();
  int _score = 0;
  int _moves = 0;
  int? _selectedTerm;
  int? _selectedDef;
  final _matched = <int>{};
  String _feedback = '';

  static const _allPairs = [
    _Pair('H₂O', 'Water'),
    _Pair('NaCl', 'Salt'),
    _Pair('CO₂', 'Carbon Dioxide'),
    _Pair('O₂', 'Oxygen'),
    _Pair('Fe', 'Iron'),
    _Pair('Au', 'Gold'),
    _Pair('F=ma', "Newton's 2nd Law"),
    _Pair('E=mc²', 'Mass-Energy'),
    _Pair('V=IR', "Ohm's Law"),
    _Pair('sin θ', 'Opp / Hyp'),
    _Pair('π', '3.14159...'),
    _Pair('DNA', 'Genetic Code'),
    _Pair('ATP', 'Cell Energy'),
    _Pair('pH 7', 'Neutral'),
    _Pair('Mitosis', 'Cell Division'),
    _Pair('Photon', 'Light Particle'),
  ];

  late List<_Pair> _pairs;
  late List<int> _defOrder;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final all = List<_Pair>.from(_allPairs)..shuffle(_rng);
    _pairs = all.take(6).toList();
    _defOrder = List.generate(6, (i) => i)..shuffle(_rng);
    _matched.clear();
    _score = 0; _moves = 0; _selectedTerm = null; _selectedDef = null; _feedback = '';
  }

  void _selectTerm(int i) {
    if (_matched.contains(i)) return;
    HapticFeedback.lightImpact();
    setState(() { _selectedTerm = i; _feedback = ''; });
    _tryMatch();
  }

  void _selectDef(int i) {
    if (_matched.contains(_defOrder[i])) return;
    HapticFeedback.lightImpact();
    setState(() { _selectedDef = i; _feedback = ''; });
    _tryMatch();
  }

  void _tryMatch() {
    if (_selectedTerm == null || _selectedDef == null) return;
    _moves++;
    if (_selectedTerm == _defOrder[_selectedDef!]) {
      HapticFeedback.mediumImpact();
      _matched.add(_selectedTerm!);
      _score++;
      _feedback = '✅ Match!';
    } else {
      _feedback = '❌ Try again!';
    }
    setState(() { _selectedTerm = null; _selectedDef = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final done = _matched.length == _pairs.length;

    return Scaffold(
      appBar: AppBar(title: Text('🧩 Match Pairs', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true,
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('$_score/${_pairs.length}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF00C853)))))]),
      body: Padding(padding: const EdgeInsets.all(20), child: done ? _congrats(tc) : _game(isDark, tc)),
    );
  }

  Widget _game(bool isDark, Color tc) {
    return Column(children: [
      if (_feedback.isNotEmpty) Text(_feedback, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _feedback.startsWith('✅') ? Colors.green : Colors.red)).animate().fadeIn(),
      const SizedBox(height: 8),
      Text('Moves: $_moves', style: GoogleFonts.outfit(fontSize: 13, color: tc.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      // Terms & Definitions side by side
      Expanded(
        child: Row(children: [
          // Terms column
          Expanded(child: Column(children: [
            Text('Terms', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
            const SizedBox(height: 8),
            ...List.generate(_pairs.length, (i) {
              final matched = _matched.contains(i);
              final selected = _selectedTerm == i;
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
                onTap: () => _selectTerm(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: matched ? Colors.green.withValues(alpha: 0.15) : selected ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : (isDark ? const Color(0xFF161B22) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: matched ? Colors.green : selected ? const Color(0xFF6C63FF) : Theme.of(context).dividerColor, width: selected ? 2 : 1),
                  ),
                  child: Text(_pairs[i].term, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: matched ? Colors.green : tc), textAlign: TextAlign.center),
                ),
              ));
            }),
          ])),
          const SizedBox(width: 12),
          // Definitions column
          Expanded(child: Column(children: [
            Text('Definitions', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF00C853))),
            const SizedBox(height: 8),
            ...List.generate(_pairs.length, (i) {
              final realIdx = _defOrder[i];
              final matched = _matched.contains(realIdx);
              final selected = _selectedDef == i;
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
                onTap: () => _selectDef(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: matched ? Colors.green.withValues(alpha: 0.15) : selected ? const Color(0xFF00C853).withValues(alpha: 0.2) : (isDark ? const Color(0xFF161B22) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: matched ? Colors.green : selected ? const Color(0xFF00C853) : Theme.of(context).dividerColor, width: selected ? 2 : 1),
                  ),
                  child: Text(_pairs[realIdx].definition, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: matched ? Colors.green : tc), textAlign: TextAlign.center),
                ),
              ));
            }),
          ])),
        ]),
      ),
    ]);
  }

  Widget _congrats(Color tc) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🎉', style: TextStyle(fontSize: 60)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 16),
      Text('All Matched!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF00C853))),
      Text('Completed in $_moves moves', style: GoogleFonts.outfit(fontSize: 15, color: tc.withValues(alpha: 0.5))),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => setState(() => _newRound()),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: Text('Play Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    ]));
  }
}

class _Pair { final String term, definition; const _Pair(this.term, this.definition); }
