import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({required this.question, required this.options, required this.correctAnswer});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
    );
  }
}

class QuizProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://172.18.116.80:8000';

  List<QuizQuestion> _questions = [];
  Map<int, String> _selectedAnswers = {};
  bool _isLoading = false;
  bool _isSubmitted = false;
  int _score = 0;
  String _resultMessage = '';
  String _previousLevel = '';
  String _newLevel = '';
  bool _showConfetti = false;
  DateTime? _quizStartTime;

  List<QuizQuestion> get questions => _questions;
  Map<int, String> get selectedAnswers => _selectedAnswers;
  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;
  int get score => _score;
  String get resultMessage => _resultMessage;
  String get previousLevel => _previousLevel;
  String get newLevel => _newLevel;
  bool get showConfetti => _showConfetti;
  Duration get quizDuration =>
      _quizStartTime != null ? DateTime.now().difference(_quizStartTime!) : Duration.zero;

  Future<void> generateQuiz(String childId, String subject) async {
    _isLoading = true;
    _isSubmitted = false;
    _selectedAnswers = {};
    _score = 0;
    _showConfetti = false;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/quiz/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'child_id': childId, 'subject': subject}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && (data['questions'] as List).isNotEmpty) {
          _questions = (data['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList();
          _quizStartTime = DateTime.now();
        } else {
          _questions = _mockQuestions(subject);
          _quizStartTime = DateTime.now();
        }
      } else {
        _questions = _mockQuestions(subject);
        _quizStartTime = DateTime.now();
      }
    } catch (e) {
      _questions = _mockQuestions(subject);
      _quizStartTime = DateTime.now();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<QuizQuestion> _mockQuestions(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) {
      return [
        QuizQuestion(question: 'What is the square root of 144?', options: ['A. 10', 'B. 11', 'C. 12', 'D. 14'], correctAnswer: 'C'),
        QuizQuestion(question: 'If x + 5 = 12, what is x?', options: ['A. 5', 'B. 6', 'C. 7', 'D. 8'], correctAnswer: 'C'),
        QuizQuestion(question: 'What is 15% of 200?', options: ['A. 20', 'B. 25', 'C. 30', 'D. 35'], correctAnswer: 'C'),
        QuizQuestion(question: 'Area of circle with radius 7? (pi=22/7)', options: ['A. 44', 'B. 154', 'C. 132', 'D. 77'], correctAnswer: 'B'),
        QuizQuestion(question: 'Simplify: 3x + 2x - x', options: ['A. 3x', 'B. 4x', 'C. 5x', 'D. 6x'], correctAnswer: 'B'),
        QuizQuestion(question: 'LCM of 12 and 18?', options: ['A. 24', 'B. 36', 'C. 48', 'D. 72'], correctAnswer: 'B'),
        QuizQuestion(question: 'Triangle angles 60, 60, x. What is x?', options: ['A. 40', 'B. 50', 'C. 60', 'D. 70'], correctAnswer: 'C'),
        QuizQuestion(question: '2 to the power of 8?', options: ['A. 128', 'B. 256', 'C. 512', 'D. 64'], correctAnswer: 'B'),
        QuizQuestion(question: 'Slope of y = 3x + 5?', options: ['A. 5', 'B. 3', 'C. 8', 'D. 15'], correctAnswer: 'B'),
        QuizQuestion(question: 'Degrees in a straight angle?', options: ['A. 90', 'B. 120', 'C. 180', 'D. 360'], correctAnswer: 'C'),
      ];
    }
    return [
      QuizQuestion(question: 'Powerhouse of the cell?', options: ['A. Nucleus', 'B. Ribosome', 'C. Mitochondria', 'D. Golgi Body'], correctAnswer: 'C'),
      QuizQuestion(question: 'Gas absorbed in photosynthesis?', options: ['A. Oxygen', 'B. Nitrogen', 'C. Carbon Dioxide', 'D. Hydrogen'], correctAnswer: 'C'),
      QuizQuestion(question: 'Newton\'s Second Law?', options: ['A. Action-reaction', 'B. F = ma', 'C. Inertia', 'D. Conservation'], correctAnswer: 'B'),
      QuizQuestion(question: 'Chemical formula for water?', options: ['A. CO2', 'B. H2O', 'C. NaCl', 'D. O2'], correctAnswer: 'B'),
      QuizQuestion(question: 'Planet closest to Sun?', options: ['A. Venus', 'B. Earth', 'C. Mercury', 'D. Mars'], correctAnswer: 'C'),
      QuizQuestion(question: 'pH of pure water?', options: ['A. 5', 'B. 7', 'C. 9', 'D. 14'], correctAnswer: 'B'),
      QuizQuestion(question: 'Lens to correct myopia?', options: ['A. Convex', 'B. Concave', 'C. Bifocal', 'D. Cylindrical'], correctAnswer: 'B'),
      QuizQuestion(question: 'Blood cells that fight infection?', options: ['A. RBC', 'B. Platelets', 'C. WBC', 'D. Plasma'], correctAnswer: 'C'),
      QuizQuestion(question: 'SI unit of current?', options: ['A. Volt', 'B. Ohm', 'C. Watt', 'D. Ampere'], correctAnswer: 'D'),
      QuizQuestion(question: 'Vitamin from sunlight?', options: ['A. Vitamin A', 'B. Vitamin C', 'C. Vitamin D', 'D. Vitamin K'], correctAnswer: 'C'),
    ];
  }

  void selectAnswer(int questionIndex, String answer) {
    _selectedAnswers[questionIndex] = answer;
    notifyListeners();
  }

  /// INSTANT submit — compute locally, fire-and-forget to backend
  Future<void> submitQuiz(String childId, String subject) async {
    _score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctAnswer) _score++;
    }

    // Apply result INSTANTLY — no loading, no waiting
    _applyLocalResult();
    _isSubmitted = true;
    notifyListeners();

    // Fire-and-forget backend submit (non-blocking)
    try {
      http.post(
        Uri.parse('$_baseUrl/api/v1/quiz/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'child_id': childId, 'subject': subject, 'score': _score}),
      ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('Error', 500));
    } catch (_) {}
  }

  void _applyLocalResult() {
    final total = _questions.length;
    _showConfetti = _score >= (total * 0.8).round();
    if (_score >= (total * 0.8).round()) {
      _resultMessage = 'Outstanding! You scored $_score/$total! Promoted to Advanced level.';
      _previousLevel = 'Intermediate';
      _newLevel = 'Advanced';
    } else if (_score >= (total * 0.5).round()) {
      _resultMessage = 'Good effort! You scored $_score/$total. Keep practicing!';
      _previousLevel = 'Intermediate';
      _newLevel = 'Intermediate';
    } else {
      _resultMessage = 'You scored $_score/$total. Let us review the concepts together.';
      _previousLevel = 'Intermediate';
      _newLevel = 'Beginner';
    }
  }

  void reset() {
    _questions = [];
    _selectedAnswers = {};
    _isLoading = false;
    _isSubmitted = false;
    _score = 0;
    _showConfetti = false;
    _quizStartTime = null;
    notifyListeners();
  }
}
