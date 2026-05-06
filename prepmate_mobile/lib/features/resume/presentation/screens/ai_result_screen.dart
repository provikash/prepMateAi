import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import '../providers/ai_provider.dart';
import '../widgets/resume_widgets.dart';

class AIResultScreen extends ConsumerWidget {
  const AIResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'AI Result',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              ref.read(aiProvider.notifier).reset();
              context.pop();
            },
          ),
        ],
      ),
      body: aiState.status == AIStatus.loading
          ? _buildPollingState()
          : aiState.status == AIStatus.success
              ? _buildSuccessState(context, ref, aiState)
              : aiState.status == AIStatus.error
                  ? _buildErrorState(aiState.errorMessage ?? 'Unknown error')
                  : _buildErrorState('No AI action has been submitted yet.'),
    );
  }

  Widget _buildPollingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00796B)),
          const SizedBox(height: 24),
          const Text(
            'AI is working its magic...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes a few seconds',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    WidgetRef ref,
    AIState aiState,
  ) {
    final result = aiState.result ?? '';
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildSuccessIcon(),
          const SizedBox(height: 24),
          Text(
            _titleForAction(aiState.action),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).primary,),
            ),
          
          const SizedBox(height: 8),
          Text(
            _subtitleForAction(aiState.action),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Text(
                  result,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Regenerate logic
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AIButton(
            text: 'Applied ✓ — Back to Form',
            onPressed: () {
              ref.read(aiProvider.notifier).reset();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2F1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: Color(0xFF00796B),
        size: 48,
      ),
    );
  }

  String _titleForAction(String? action) {
    return switch (action) {
      'generate_summary' => 'Summary Generated ✨',
      'improve_section' => 'Section Improved ✨',
      'suggest_skills' => 'Skills Suggested ✨',
      'generate_bullets' => 'Bullets Generated ✨',
      _ => 'AI Result',
    };
  }

  String _subtitleForAction(String? action) {
    return switch (action) {
      'generate_summary' => 'Applied to your Summary section.',
      'improve_section' => 'Applied to your Summary section.',
      'suggest_skills' => 'Skills added to your Skills section.',
      'generate_bullets' => 'Bullets added to your first experience.',
      _ => 'Applied to your resume form.',
    };
  }
}
