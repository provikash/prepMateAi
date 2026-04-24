enum MessageSender { ai, user }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isTyping = false,
  });
}
