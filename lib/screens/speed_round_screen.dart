import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class SpeedRoundScreen extends StatefulWidget {
  const SpeedRoundScreen({super.key});
  @override
  State<SpeedRoundScreen> createState() => _SpeedRoundScreenState();
}

class _SpeedRoundScreenState extends State<SpeedRoundScreen> {
  final _rng = Random();
  int _score = 0;
  int _timeLeft = 60;
  int _currentQ = 0;
  bool _started = false;
  bool _done = false;
  Timer? _timer;

  static const _questions = [
    _TF('The Earth revolves around the Sun.', true),
    _TF('Water boils at 50°C at sea level.', false),
    _TF('The chemical symbol for Gold is Au.', true),
    _TF('Sound travels faster than light.', false),
    _TF('DNA stands for Deoxyribonucleic Acid.', true),
    _TF('The square root of 144 is 14.', false),
    _TF('Photosynthesis produces oxygen.', true),
    _TF('Jupiter is the smallest planet.', false),
    _TF('The mitochondria is the powerhouse of the cell.', true),
    _TF('Acids have a pH greater than 7.', false),
    _TF('Velocity is speed with direction.', true),
    _TF('Diamonds are made of iron.', false),
    _TF('π (pi) is approximately 3.14159.', true),
    _TF('Humans have 206 bones.', true),
    _TF('The Amazon is the longest river.', false),
    _TF('Protons have a positive charge.', true),
    _TF('CO₂ is Carbon Monoxide.', false),
    _TF('A triangle has 180° total angles.', true),
    _TF('Mercury is the hottest planet.', false),
    _TF('Fungi are classified as plants.', false),
    _TF('The speed of light is ~3×10⁸ m/s.', true),
    _TF('NaCl is table sugar.', false),
    _TF('Electrons orbit the nucleus.', true),
    _TF('1 kilometer = 100 meters.', false),
    _TF('The heart has 4 chambers.', true),
  ];

  late List<_TF> _shuffled;

  @override
  void initState() {
    super.initState();
    _shuffled = List.from(_questions)..shuffle(_rng);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _start() {
    setState(() { _started = true; _score = 0; _currentQ = 0; _timeLeft = 60; _done = false; });
    _shuffled = List.from(_questions)..shuffle(_rng);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) { 
        _timer?.cancel(); 
        setState(() { _done = true; }); 
        context.read<GamificationProvider>().recordQuizScore(_score * 4); 
        return; 
      }
      setState(() => _timeLeft--);
    });
  }

  void _answer(bool ans) {
    HapticFeedback.lightImpact();
    if (_shuffled[_currentQ].answer == ans) {
      _score++;
      context.read<GamificationProvider>().onQuestionAsked(subject: 'Science');
    } else {
      context.read<GamificationProvider>().onQuestionFailed(subject: 'Science');
    }
    setState(() { 
      if (_currentQ < _shuffled.length - 1) {
        _currentQ++; 
      } else { 
        _timer?.cancel(); 
        _done = true; 
      } 
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Scaffold(
      appBar: AppBar(title: Text('⚡ Speed Round', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Padding(padding: const EdgeInsets.all(24), child: !_started ? _lobby(tc) : _done ? _results(tc) : _game(isDark, tc)),
    );
  }

  Widget _lobby(Color tc) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('⚡', style: TextStyle(fontSize: 60)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 16),
      Text('Speed Round', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: tc)),
      const SizedBox(height: 8),
      Text('Answer True/False as fast as you can!\n60 seconds on the clock.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: tc.withValues(alpha: 0.5))),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _start,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6584), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text('START', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
    ]));
  }

  Widget _game(bool isDark, Color tc) {
    final q = _shuffled[_currentQ];
    final urgency = _timeLeft <= 10;
    return Column(children: [
      // Timer + Score
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: (urgency ? Colors.red : const Color(0xFFFF6584)).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.timer_rounded, color: urgency ? Colors.red : const Color(0xFFFF6584), size: 20),
            const SizedBox(width: 6),
            Text('${_timeLeft}s', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: urgency ? Colors.red : const Color(0xFFFF6584))),
          ]),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text('Score: $_score', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
        ),
      ]),
      const Spacer(),
      // Question
      Container(
        width: double.infinity, padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Text(q.statement, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: tc, height: 1.4), textAlign: TextAlign.center),
      ).animate(key: ValueKey(_currentQ)).fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0),
      const Spacer(),
      // True / False buttons
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => _answer(true),
          child: Container(
            height: 80,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Center(child: Text('TRUE ✓', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: GestureDetector(
          onTap: () => _answer(false),
          child: Container(
            height: 80,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Center(child: Text('FALSE ✗', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
          ),
        )),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _results(Color tc) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(_score >= 15 ? '🏆' : _score >= 10 ? '⚡' : '💪', style: const TextStyle(fontSize: 60)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 16),
      Text('$_score', style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: const Color(0xFFFF6584))),
      Text('correct answers in 60 seconds!', style: GoogleFonts.outfit(fontSize: 15, color: tc.withValues(alpha: 0.5))),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6584), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: Text('Play Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
    ]));
  }
}

class _TF { final String statement; final bool answer; const _TF(this.statement, this.answer); }
