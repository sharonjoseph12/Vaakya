import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class MemoryMatrixScreen extends StatefulWidget {
  const MemoryMatrixScreen({super.key});
  @override
  State<MemoryMatrixScreen> createState() => _MemoryMatrixScreenState();
}

class _MemoryMatrixScreenState extends State<MemoryMatrixScreen> {
  final _rng = Random();
  int _level = 1;
  int _gridSize = 3; // 3x3
  List<int> _pattern = [];
  List<int> _userInput = [];
  bool _showingPattern = false;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    setState(() {
      _userInput.clear();
      _showingPattern = true;
      if (_level > 3) _gridSize = 4; // 4x4 for higher levels
      final totalCells = _gridSize * _gridSize;
      final patternLength = 2 + _level; // Increases with level
      
      _pattern = [];
      while (_pattern.length < patternLength) {
        final cell = _rng.nextInt(totalCells);
        if (_pattern.isEmpty || _pattern.last != cell) {
          _pattern.add(cell);
        }
      }
    });

    _playPattern();
  }

  Future<void> _playPattern() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < _pattern.length; i++) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      // Highlight the cell temporarily
      setState(() { _userInput = [_pattern[i]]; });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() { _userInput.clear(); });
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() { _showingPattern = false; });
  }

  void _onTap(int index) {
    if (_showingPattern || _gameOver) return;
    HapticFeedback.lightImpact();
    
    setState(() {
      _userInput.add(index);
      
      // Check correctness so far
      for (int i = 0; i < _userInput.length; i++) {
        if (_userInput[i] != _pattern[i]) {
          _gameOver = true;
          context.read<GamificationProvider>().recordQuizScore((_level * 10).clamp(0, 100));
          return;
        }
      }

      // Check if pattern complete
      if (_userInput.length == _pattern.length) {
        _level++;
        Future.delayed(const Duration(milliseconds: 500), _startLevel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = isDark ? Colors.white : const Color(0xFF1A1A2E);

    if (_gameOver) {
      return Scaffold(
        appBar: AppBar(title: Text('🧠 Memory Matrix', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💥', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Pattern Broken!', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red)),
          Text('You reached Level $_level', style: GoogleFonts.outfit(fontSize: 20, color: tc)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() { _level = 1; _gridSize = 3; _gameOver = false; _startLevel(); }),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: Text('Try Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('🧠 Memory Matrix', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Level $_level', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF6C63FF))),
          Text(_showingPattern ? 'Watch...' : 'Your Turn!', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: _showingPattern ? Colors.orange : Colors.green)),
        ]),
        const Spacer(),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize, mainAxisSpacing: 12, crossAxisSpacing: 12,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (context, index) {
              bool isHighlighted = false;
              if (_showingPattern && _userInput.isNotEmpty && _userInput.first == index) {
                isHighlighted = true;
              } else if (!_showingPattern && _userInput.contains(index)) {
                // Flash briefly when user taps
                isHighlighted = _userInput.last == index;
              }

              return GestureDetector(
                onTap: () => _onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isHighlighted ? const Color(0xFF00D2FF) : (isDark ? const Color(0xFF161B22) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isHighlighted ? const Color(0xFF00D2FF) : Theme.of(context).dividerColor, width: isHighlighted ? 3 : 1),
                    boxShadow: isHighlighted ? [BoxShadow(color: const Color(0xFF00D2FF).withValues(alpha: 0.5), blurRadius: 12)] : [],
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(),
        Text('Memorize the sequence and repeat it.', style: GoogleFonts.outfit(color: tc.withValues(alpha: 0.5))),
        const SizedBox(height: 32),
      ])),
    );
  }
}
