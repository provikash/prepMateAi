import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../state/interview_state.dart';
import '../../../../config/dio_client.dart';

final interviewViewModelProvider = StateNotifierProvider<InterviewViewModel, InterviewState>((ref) {
  return InterviewViewModel(ref);
});

class InterviewViewModel extends StateNotifier<InterviewState> {
  final Ref _ref;

  InterviewViewModel(this._ref) : super(InterviewState(messages: [
    ChatMessage(
      text: "Hi there! I'm your AI Coach. Ready to practice? Let's start with a common behavioral question.",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
    ChatMessage(
      text: "Tell me about a time you handled a difficult situation with a coworker or a client?",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
  ]));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    // Add typing indicator
    final typingMessage = ChatMessage(
      text: "...",
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = state.copyWith(messages: [...state.messages, typingMessage]);

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('interview/chat/', data: {'message': text});
      
      final aiResponse = ChatMessage(
        text: response.data['response'] ?? "I'm sorry, I couldn't process that.",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );

      // Remove typing indicator and add AI response
      state = state.copyWith(
        messages: state.messages.where((m) => !m.isTyping).toList()..add(aiResponse),
      );
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => !m.isTyping).toList(),
        error: "Failed to connect to AI Coach",
      );
    }
  }
}
