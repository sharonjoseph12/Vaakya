import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../providers/gamification_provider.dart';

class QuizScreen extends StatefulWidget {
  final String childId;
  final String subject;
  const QuizScreen({
    super.key,
    this.childId = "demo_child",
    this.subject = "Science",
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().generateQuiz(widget.childId, widget.subject);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Quiz',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              gravity: 0.15,
              colors: const [
                Color(0xFF6C63FF), Color(0xFFFF6584),
                Color(0xFF00D2FF), Color(0xFFFFD700), Color(0xFF00FF88),
              ],
            ),
          ),
          Consumer<QuizProvider>(builder: (context, quiz, _) {
            if (quiz.isLoading && quiz.questions.isEmpty) return _loading();
            if (quiz.questions.isEmpty) return _empty();
            if (quiz.isSubmitted) return _result(quiz);
            return _quizBody(quiz);
          }),
        ],
      ),
    );
  }

  Widget _loading() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: Color(0xFF6C63FF)),
          const SizedBox(height: 24),
          const Text('Generating your quiz...', style: TextStyle(fontSize: 16)),
        ]),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Could not generate quiz', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<QuizProvider>().generateQuiz(widget.childId, widget.subject),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
          ),
        ]),
      );

  Widget _quizBody(QuizProvider quiz) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Progress
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Center(child: Text('${quiz.selectedAnswers.length}/${quiz.questions.length} answered', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 20),
        ...List.generate(quiz.questions.length, (i) => _questionCard(quiz, i)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: quiz.selectedAnswers.length == quiz.questions.length
              ? () { HapticFeedback.heavyImpact(); quiz.submitQuiz(widget.childId, widget.subject); }
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Submit Quiz', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _questionCard(QuizProvider quiz, int i) {
    final q = quiz.questions[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)]), borderRadius: BorderRadius.circular(20)),
          child: Text('Q${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(height: 14),
        Text(q.question, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4)),
        const SizedBox(height: 16),
        ...q.options.map((opt) {
          final letter = opt.substring(0, 1);
          final selected = quiz.selectedAnswers[i] == letter;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); quiz.selectAnswer(i, letter); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6C63FF).withValues(alpha: 0.15) : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? const Color(0xFF6C63FF) : Theme.of(context).dividerColor, width: selected ? 2 : 1),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200), width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? const Color(0xFF6C63FF) : Colors.transparent, border: Border.all(color: selected ? const Color(0xFF6C63FF) : Theme.of(context).dividerColor, width: 2)),
                  child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(opt, style: TextStyle(color: selected ? const Color(0xFF6C63FF) : Theme.of(context).colorScheme.onSurface, fontSize: 15))),
              ]),
            ),
          );
        }),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * i), duration: 400.ms);
  }

  Widget _result(QuizProvider quiz) {
    if (quiz.showConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confetti.play();
        if (quiz.quizDuration.inSeconds < 60) context.read<GamificationProvider>().onQuizCompletedFast();
      });
    }
    // Record score for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().recordQuizScore(quiz.score);
    });
    final total = quiz.questions.length;
    final pct = total > 0 ? quiz.score / total : 0.0;
    final color = pct >= 0.8 ? const Color(0xFF00FF88) : pct >= 0.5 ? const Color(0xFFFFD700) : const Color(0xFFFF6584);
    final emoji = pct >= 0.8 ? '🏆' : pct >= 0.5 ? '👍' : '💪';
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 64)).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('${quiz.score}/$total', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Text(quiz.resultMessage, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5)),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () { quiz.reset(); Navigator.pop(context); },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Dashboard'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ).animate().fadeIn(delay: 600.ms),
      ])),
    );
  }
}
