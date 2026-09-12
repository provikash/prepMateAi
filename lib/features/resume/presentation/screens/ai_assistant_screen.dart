import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../widgets/resume_input_widgets.dart';

class AIAssistantScreen extends ConsumerWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Assistant',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Use AI to enhance your resume',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const Spacer(),
                Image.network(
                  'https://cdn-icons-png.flaticon.com/512/4712/4712035.png', // Robot icon placeholder
                  height: 40,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AIActionCard(
              icon: Icons.description_outlined,
              iconColor: colors.primary,
              title: 'Generate Summary',
              description:
                  'Create a professional summary based on your details.',
              onTap: () => context.push('/resume/ai-input/summary'),
            ),
            AIActionCard(
              icon: Icons.edit_outlined,
              iconColor: Colors.purple,
              title: 'Improve Section',
              description:
                  'Improve any section content for clarity and impact.',
              onTap: () => context.push('/resume/ai-input/improve'),
            ),
            AIActionCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.orange,
              title: 'Suggest Skills',
              description:
                  'Get relevant skills based on your role and experience.',
              onTap: () => context.push('/resume/ai-input/skills'),
            ),
            AIActionCard(
              icon: Icons.list_alt_outlined,
              iconColor: Colors.blue,
              title: 'Generate Bullets',
              description:
                  'Generate impactful bullet points for your experience.',
              onTap: () => context.push('/resume/ai-input/bullets'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent AI Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentTask(
              context,
              'Generated Summary',
              '2 mins ago',
              'Completed',
            ),
            _buildRecentTask(
              context,
              'Suggested Skills',
              '10 mins ago',
              'Completed',
            ),
            _buildRecentTask(
              context,
              'Generated Bullets',
              '30 mins ago',
              'Completed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTask(
    BuildContext context,
    String title,
    String time,
    String status,
  ) {
    final colors = AppColors.of(context);
    return Card(
      elevation: 0,
      color: colors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
