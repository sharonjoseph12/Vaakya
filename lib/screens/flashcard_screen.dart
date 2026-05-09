import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/local_db.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Map<String, dynamic>> _cards = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final due = await LocalDatabase.instance.getDueFlashcards();
    if (due.isEmpty) {
      final all = await LocalDatabase.instance.getAllFlashcards();
      setState(() { _cards = all; _loading = false; });
    } else {
      setState(() { _cards = due; _loading = false; });
    }
  }

  void _flip() { HapticFeedback.lightImpact(); setState(() => _showBack = !_showBack); }

  void _rate(int quality) async {
    if (_cards.isEmpty) return;
    HapticFeedback.mediumImpact();
    await LocalDatabase.instance.reviewFlashcard(_cards[_currentIndex]['id'], quality);
    setState(() {
      _showBack = false;
      if (_currentIndex < _cards.length - 1) { _currentIndex++; }
      else { _currentIndex = 0; _load(); } // Reload for next session
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      appBar: AppBar(
        title: Text('🃏 Flashcards', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (_cards.isNotEmpty) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_currentIndex + 1}/${_cards.length}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF)))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _emptyState(textColor)
              : _cardView(isDark, textColor),
    );
  }

  Widget _emptyState(Color textColor) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🎉', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text('No flashcards due!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
      const SizedBox(height: 8),
      Text('Ask questions and tap "Flashcard" to create cards.', style: GoogleFonts.outfit(fontSize: 14, color: textColor.withValues(alpha: 0.5)), textAlign: TextAlign.center),
    ]));
  }

  Widget _cardView(bool isDark, Color textColor) {
    final card = _cards[_currentIndex];
    final front = card['front']?.toString() ?? 'Question';
    final back = card['back']?.toString() ?? 'Answer';
    final interval = card['interval_days'] ?? 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _cards.isEmpty ? 0 : (_currentIndex + 1) / _cards.length,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            color: const Color(0xFF6C63FF), minHeight: 6,
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 8),
        Text('Next review in $interval day${interval > 1 ? 's' : ''}', style: GoogleFonts.outfit(fontSize: 12, color: textColor.withValues(alpha: 0.4))),

        const Spacer(),

        // Flashcard
        GestureDetector(
          onTap: _flip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => RotationTransition(turns: Tween(begin: 0.5, end: 1.0).animate(anim), child: child),
            child: Container(
              key: ValueKey(_showBack),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 280),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: _showBack
                    ? const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF00B4D8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: (_showBack ? const Color(0xFF00D2FF) : const Color(0xFF6C63FF)).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_showBack ? 'ANSWER' : 'QUESTION', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Text(_showBack ? back : front, style: GoogleFonts.outfit(color: Colors.white, fontSize: _showBack ? 15 : 18, fontWeight: FontWeight.w600, height: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text(_showBack ? '' : 'Tap to reveal', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // Rating buttons (only when answer shown)
        if (_showBack)
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _rateButton('😞\nForgot', Colors.red, () => _rate(1)),
            _rateButton('🤔\nHard', Colors.orange, () => _rate(3)),
            _rateButton('😊\nGood', Colors.green, () => _rate(4)),
            _rateButton('🤩\nEasy', const Color(0xFF6C63FF), () => _rate(5)),
          ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0)
        else
          Text('Tap the card to see the answer', style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 14)),

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _rateButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}
