import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_scaffold.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  static const _supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const _answers = {
    'How do I create a resume?':
        'Choose a template from Home, fill in each section, then select Preview. Save a draft whenever you need to pause.',
    'How do I export my resume?':
        'Open the resume PDF and tap Share. Choose a destination in your phone’s share menu to save or send the file.',
    'Which files can I analyze?':
        'Upload a PDF up to 10 MB with selectable text, or choose a saved resume. Enter the role you are applying for to get relevant feedback.',
    'What does my ATS score mean?':
        'It is PrepMate’s estimate based on keywords, sections, content, formatting, and contact information. Use the feedback to improve your resume; employer systems can evaluate it differently.',
    'How is learning progress saved?':
        'Open a course inside PrepMate. Your video position is saved while you watch and when you leave the player. An internet connection is required to sync progress.',
    'How can I reset my password?':
        'Use Forgot password on the sign-in screen. Check your email and spam folder for the verification code, then choose a new password.',
  };

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Help & support',
    description: 'Clear answers for common PrepMate tasks.',
    padding: EdgeInsets.zero,
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: [
        Icon(
          Icons.help_outline_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'A little guidance for your next step.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        for (final entry in _answers.entries)
          Card(
            elevation: 0,
            child: ExpansionTile(
              title: Text(entry.key),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                Text(entry.value, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        if (_supportEmail.isNotEmpty) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Contact support'),
            onPressed: () async {
              final opened = await launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: _supportEmail,
                  queryParameters: {'subject': 'PrepMate support'},
                ),
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email $_supportEmail for help.')),
                );
              }
            },
          ),
        ],
      ],
    ),
  );
}
