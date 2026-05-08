import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/api_client.dart';
import '../core/local_db.dart';
import '../models/message_model.dart';

/// Manages the chat conversation state and offline intercept logic.
class ChatProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isOffline = false;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  /// Callback fired after a new message is added — used for auto-scroll.
  VoidCallback? onNewMessage;

  /// Send a text query to the backend (or offline cache).
  Future<String?> sendMessage({
    required String query,
    required String profileId,
    String subject = 'General',
    String language = 'en-IN',
    String learnerLevel = 'Intermediate',
  }) async {
    // Add user bubble
    _messages.add(MessageModel.user(query));
    _isLoading = true;
    notifyListeners();
    _notifyNewMessage();

    // Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResults.isNotEmpty &&
        !connectivityResults.contains(ConnectivityResult.none);

    String? aiReply;
    String? sourcePage;

    if (hasInternet) {
      // ── Online path ──
      final response = await ApiClient.askQuestion(
        profileId: profileId,
        query: query,
        subject: subject,
        language: language,
        learnerLevel: learnerLevel,
      );

      if (response != null) {
        aiReply = response['ai_reply'] as String?;
        sourcePage = response['source_textbook_page'] as String?;

        // Cache for offline use
        if (aiReply != null) {
          await LocalDatabase.instance.cacheResponse(
            query: query,
            answer: aiReply,
            language: language,
          );
        }
      } else {
        // API call failed — try offline
        aiReply = await _offlineFallback(query);
      }

      _isOffline = false;
    } else {
      // ── Offline path ──
      _isOffline = true;
      aiReply = await _offlineFallback(query);
    }

    // Fallback message if everything fails
    aiReply ??=
        "My internet brain is a bit slow today, let's try that again!";

    // Add AI bubble
    _messages.add(MessageModel.ai(aiReply, sourcePage: sourcePage));
    _isLoading = false;
    notifyListeners();
    _notifyNewMessage();

    return aiReply;
  }

  /// Add an AI message directly (e.g. from vision or system messages).
  void addAiMessage(String text) {
    _messages.add(MessageModel.ai(text));
    notifyListeners();
    _notifyNewMessage();
  }

  /// Add a user message bubble (no API call).
  void addUserMessage(String text) {
    _messages.add(MessageModel.user(text));
    notifyListeners();
    _notifyNewMessage();
  }

  /// Clear all messages.
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<String?> _offlineFallback(String query) async {
    final cached = await LocalDatabase.instance.searchOffline(query);
    if (cached != null) {
      return '📶 Offline answer:\n$cached';
    }
    return null;
  }

  void _notifyNewMessage() {
    onNewMessage?.call();
  }
}
