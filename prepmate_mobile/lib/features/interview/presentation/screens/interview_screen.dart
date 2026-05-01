import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/config/theme.dart';
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'AI Interview Coach',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: colors.textPrimary),
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
                    (index == 0 ||
                        state.messages[index - 1].sender == MessageSender.user);

                return _buildMessageBubble(message, isLastAiMessage, colors);
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
                  _buildQuickAction('Give me a hint', colors),
                  _buildQuickAction('Analyze my tone', colors),
                  _buildQuickAction('Different question', colors),
                ],
              ),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(color: colors.cardBackground),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Type your response...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              hintStyle: TextStyle(
                                color: colors.textSecondary.withOpacity(0.5),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic_none, color: colors.textSecondary),
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
                    decoration: BoxDecoration(
                      color: colors.primary,
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

  Widget _buildMessageBubble(
    ChatMessage message,
    bool showHeader,
    AppColors colors,
  ) {
    final isAi = message.sender == MessageSender.ai;

    return Column(
      crossAxisAlignment:
          isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 4, top: 12),
            child: Text(
              isAi ? 'PREPMATE AI' : 'YOU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
        Row(
          mainAxisAlignment:
              isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isAi)
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isAi ? colors.cardBackground : colors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isAi ? 4 : 16),
                    bottomRight: Radius.circular(isAi ? 16 : 4),
                  ),
                  boxShadow: isAi
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkShadow
                          : AppTheme.lightShadow)
                      : null,
                ),
                child: message.isTyping
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(color: colors.textSecondary),
                          const SizedBox(width: 4),
                          _TypingDot(color: colors.textSecondary),
                          const SizedBox(width: 4),
                          _TypingDot(color: colors.textSecondary),
                        ],
                      )
                    : Text(
                        message.text,
                        style: TextStyle(
                          color: isAi ? colors.textPrimary : Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
              ),
            ),
            if (!isAi) const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickAction(String text, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 16),
      child: OutlinedButton(
        onPressed: () =>
            ref.read(interviewViewModelProvider.notifier).sendMessage(text),
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide(color: colors.border),
          backgroundColor: colors.primarySoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final Color color;
  const _TypingDot({required this.color});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
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
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
