import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class MathNinjaScreen extends StatefulWidget {
  const MathNinjaScreen({super.key});
  @override
  State<MathNinjaScreen> createState() => _MathNinjaScreenState();
}

class _MathNinjaScreenState extends State<MathNinjaScreen> {
  final _rng = Random();
  int _score = 0;
  int _lives = 3;
  late String _equation;
  late int _answer;
  late List<int> _options;
  bool _answered = false;
  int _selectedIdx = -1;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final ops = ['+', '-', '*'];
    final op = ops[_rng.nextInt(ops.length)];
    int a, b;
    if (op == '*') {
      a = _rng.nextInt(12) + 2;
      b = _rng.nextInt(12) + 2;
      _answer = a * b;
    } else if (op == '+') {
      a = _rng.nextInt(50) + 10;
      b = _rng.nextInt(50) + 10;
      _answer = a + b;
    } else {
      a = _rng.nextInt(50) + 20;
      b = _rng.nextInt(a - 10) + 1;
      _answer = a - b;
    }
    _equation = '$a $op $b = ?';

    final opts = <int>{_answer};
    while (opts.length < 4) {
      final offset = _rng.nextInt(10) - 5;
      if (offset != 0 && _answer + offset > 0) opts.add(_answer + offset);
    }
    _options = opts.toList()..shuffle(_rng);
    _answered = false;
    _selectedIdx = -1;
  }

  void _check(int idx) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (_options[idx] == _answer) {
        _score += 10;
        context.read<GamificationProvider>().onQuestionAsked(subject: 'Math');
      } else {
        _lives--;
        context.read<GamificationProvider>().onQuestionFailed(subject: 'Math');
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_lives <= 0) {
        context.read<GamificationProvider>().recordQuizScore((_score / 10).clamp(0, 100).toInt());
      } else {
        setState(() => _generate());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);

    if (_lives <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text('🥷 Math Ninja', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💀', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Game Over!', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red)),
          Text('Score: $_score', style: GoogleFonts.outfit(fontSize: 20, color: tc)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() { _lives = 3; _score = 0; _generate(); }),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: Text('Play Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('🥷 Math Ninja', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: List.generate(3, (i) => Icon(Icons.favorite, color: i < _lives ? Colors.red : Colors.grey.withValues(alpha: 0.3)))),
          Text('Score: $_score', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF6C63FF))),
        ]),
        const Spacer(),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 2)),
          child: Center(child: Text(_equation, style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: tc))),
        ).animate(key: ValueKey(_equation)).scale(duration: 300.ms, curve: Curves.easeOutBack),
        const Spacer(),
        GridView.count(
          shrinkWrap: true, crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.5,
          children: List.generate(4, (i) {
            Color bg = isDark ? const Color(0xFF161B22) : Colors.white;
            Color border = Theme.of(context).dividerColor;
            if (_answered) {
              if (_options[i] == _answer) { bg = Colors.green.withValues(alpha: 0.2); border = Colors.green; }
              else if (i == _selectedIdx) { bg = Colors.red.withValues(alpha: 0.2); border = Colors.red; }
            }
            return GestureDetector(
              onTap: () => _check(i),
              child: Container(
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 2)),
                child: Center(child: Text('${_options[i]}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: tc))),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
      ])),
    );
  }
}
