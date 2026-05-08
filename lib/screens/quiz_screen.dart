import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../providers/gamification_provider.dart';
import '../core/theme.dart';

class QuizScreen extends StatefulWidget {
  final String childId;
  final String subject;
  const QuizScreen({super.key, required this.childId, required this.subject});

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
      backgroundColor: VoiceGuruTheme.backgroundLight,
      appBar: AppBar(
        title: Text('${widget.subject} Quiz',
            style: const TextStyle(fontWeight: FontWeight.w700)),
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
                Color(0xFF6366F1), Color(0xFFF43F5E),
                Color(0xFF0EA5E9), Color(0xFFF59E0B), Color(0xFF10B981),
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
          const CircularProgressIndicator(color: VoiceGuruTheme.primaryPurple),
          const SizedBox(height: 24),
          const Text('Generating your quiz...', style: TextStyle(color: VoiceGuruTheme.textSecondary, fontSize: 16)),
        ]),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Could not generate quiz', style: TextStyle(color: VoiceGuruTheme.textSecondary, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<QuizProvider>().generateQuiz(widget.childId, widget.subject),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.1))),
          child: Center(child: Text('${quiz.selectedAnswers.length}/${quiz.questions.length} answered', style: const TextStyle(color: VoiceGuruTheme.primaryPurple, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 20),
        ...List.generate(quiz.questions.length, (i) => _questionCard(quiz, i)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: quiz.selectedAnswers.length == quiz.questions.length
              ? () { HapticFeedback.heavyImpact(); quiz.submitQuiz(widget.childId, widget.subject); }
              : null,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(gradient: VoiceGuruTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
          child: Text('Q${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(height: 14),
        Text(q.question, style: const TextStyle(color: VoiceGuruTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500, height: 1.4)),
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
                color: selected ? VoiceGuruTheme.primaryPurple.withValues(alpha: 0.1) : VoiceGuruTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? VoiceGuruTheme.primaryPurple : Colors.black.withValues(alpha: 0.05), width: selected ? 2 : 1),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200), width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? VoiceGuruTheme.primaryPurple : Colors.transparent, border: Border.all(color: selected ? VoiceGuruTheme.primaryPurple : VoiceGuruTheme.textSecondary, width: 2)),
                  child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(opt, style: TextStyle(color: selected ? VoiceGuruTheme.textPrimary : VoiceGuruTheme.textSecondary, fontSize: 15))),
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
        if (quiz.quizDuration.inSeconds < 30) context.read<GamificationProvider>().onQuizCompletedFast();
      });
    }
    final color = quiz.score == 3 ? VoiceGuruTheme.successGreen : quiz.score == 2 ? VoiceGuruTheme.warningAmber : VoiceGuruTheme.errorRed;
    final emoji = quiz.score == 3 ? '🏆' : quiz.score == 2 ? '👍' : '💪';
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 64)).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('${quiz.score}/3', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
          child: Text(quiz.resultMessage, textAlign: TextAlign.center, style: const TextStyle(color: VoiceGuruTheme.textPrimary, fontSize: 16, height: 1.5)),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () { quiz.reset(); Navigator.pop(context); },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Dashboard'),
        ).animate().fadeIn(delay: 600.ms),
      ])),
    );
  }
}
