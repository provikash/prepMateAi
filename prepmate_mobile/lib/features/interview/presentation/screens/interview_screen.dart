import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import '../viewmodels/interview_viewmodel.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(interviewViewModelProvider.notifier).sendMessage(text);
      _messageController.clear();
      // Auto scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'AI Interview Coach',
              style: TextStyle(color: Color(0xFF1D2939), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Online', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                final isLastAiMessage = message.sender == MessageSender.ai && 
                    (index == 0 || state.messages[index-1].sender == MessageSender.user);

                return _buildMessageBubble(message, isLastAiMessage);
              },
            ),
          ),
          
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('Give me a hint'),
                  _buildQuickAction('Analyze my tone'),
                  _buildQuickAction('Different question'),
                ],
              ),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type your response...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic_none, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF246BFD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showHeader) {
    final isAi = message.sender == MessageSender.ai;

    return Column(
      crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 4, top: 12),
            child: Text(
              isAi ? 'PREPMATE AI' : 'YOU',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
            ),
          ),
        Row(
          mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isAi)
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF246BFD), size: 20),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isAi ? Colors.white : const Color(0xFF1565C0),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isAi ? 4 : 16),
                    bottomRight: Radius.circular(isAi ? 16 : 4),
                  ),
                  boxShadow: [
                    if (isAi)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: message.isTyping 
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(),
                        SizedBox(width: 4),
                        _TypingDot(),
                        SizedBox(width: 4),
                        _TypingDot(),
                      ],
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: isAi ? const Color(0xFF1D2939) : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
              ),
            ),
            if (!isAi)
              const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickAction(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 16),
      child: OutlinedButton(
        onPressed: () => ref.read(interviewViewModelProvider.notifier).sendMessage(text),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: const BorderSide(color: Color(0xFFD0D5DD)),
          backgroundColor: const Color(0xFFF0F5FF),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF246BFD), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot();

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
      ),
    );
  }
}
