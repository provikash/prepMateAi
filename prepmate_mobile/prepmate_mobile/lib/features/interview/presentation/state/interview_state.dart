import '../../domain/models/chat_message.dart';

class InterviewState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  InterviewState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  InterviewState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return InterviewState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
