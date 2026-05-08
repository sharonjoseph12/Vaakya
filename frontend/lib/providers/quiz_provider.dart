import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
    );
  }
}

class QuizProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.0.2.2:8000';

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
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/quiz/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'child_id': childId, 'subject': subject}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _questions = (data['questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList();
          _quizStartTime = DateTime.now();
        }
      }
    } catch (e) {
      _questions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectAnswer(int questionIndex, String answer) {
    _selectedAnswers[questionIndex] = answer;
    notifyListeners();
  }

  Future<void> submitQuiz(String childId, String subject) async {
    // Calculate score
    _score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctAnswer) {
        _score++;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/quiz/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'child_id': childId,
              'subject': subject,
              'score': _score,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _resultMessage = data['message'] ?? '';
        _previousLevel = data['previous_level'] ?? '';
        _newLevel = data['new_level'] ?? '';
        _showConfetti = _score == 3;
      }
    } catch (e) {
      _resultMessage = 'Could not submit quiz. Try again later.';
    }

    _isSubmitted = true;
    _isLoading = false;
    notifyListeners();
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
