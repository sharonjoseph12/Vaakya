/// Represents a single chat message in the conversation.
class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? sourcePage;

  MessageModel({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.sourcePage,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
        'sourcePage': sourcePage,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        text: map['text'] as String,
        isUser: (map['isUser'] as int) == 1,
        timestamp: DateTime.parse(map['timestamp'] as String),
        sourcePage: map['sourcePage'] as String?,
      );

  /// Quick factory for a user message.
  factory MessageModel.user(String text) =>
      MessageModel(text: text, isUser: true);

  /// Quick factory for an AI reply.
  factory MessageModel.ai(String text, {String? sourcePage}) =>
      MessageModel(text: text, isUser: false, sourcePage: sourcePage);
}
