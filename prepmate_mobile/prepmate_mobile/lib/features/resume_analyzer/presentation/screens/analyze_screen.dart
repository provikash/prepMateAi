import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../resume/presentation/providers/resume_providers.dart';
import '../../../resume/data/models/resume_model.dart';
import '../providers/resume_analyzer_providers.dart';

class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  File? _selectedFile;
  bool _useSavedResume = true;
  String? _selectedResumeId;

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();

      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large (max 10MB)')),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useSavedResume &&
        (_selectedResumeId == null || _selectedResumeId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a saved resume.')),
      );
      return;
    }

    if (!_useSavedResume && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a PDF resume.')),
      );
      return;
    }

    ref.read(analyzeProvider.notifier).analyze(
          resumeId: _useSavedResume ? _selectedResumeId : null,
          file: _useSavedResume ? null : _selectedFile,
          jobRole: _roleController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyzeProvider);
    final resumesAsync = ref.watch(storedResumesProvider);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(analyzeProvider, (previous, next) {
      if (next.data != null) {
        context.push('/ats-result', extra: next.data);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        title: Text(
          'ATS Analyzer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: colors.textPrimary),
            onPressed: () => context.push('/ats-history'),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(colors),
                const SizedBox(height: 32),
                Text(
                  'Target Job Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                NeuTextField(
                  controller: _roleController,
                  hint: 'e.g. Senior Flutter Developer',
                  prefixIcon: Icons.work_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Job role is required'
                      : null,
                ),
                const SizedBox(height: 32),
                Text(
                  'Resume Source',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSourceSelector(colors),
                const SizedBox(height: 24),
                if (_useSavedResume)
                  _buildResumeDropdown(resumesAsync, colors, isDark)
                else
                  _buildFileUploadArea(colors, isDark),
                const SizedBox(height: 32),
                _buildInfoCard(colors),
                const SizedBox(height: 40),
                NeuButton(
                  isLoading: state.isLoading,
                  onPressed: _submit,
                  text: 'Analyze Resume',
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boost Your Interview Chances 🚀',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Our AI-powered ATS analyzer evaluates your resume against industry standards and job descriptions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildSourceSelector(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: _SourceOption(
            title: 'Saved Resume',
            icon: Icons.description_outlined,
            isSelected: _useSavedResume,
            onTap: () => setState(() => _useSavedResume = true),
            colors: colors,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SourceOption(
            title: 'Upload New',
            icon: Icons.cloud_upload_outlined,
            isSelected: !_useSavedResume,
            onTap: () => setState(() => _useSavedResume = false),
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildResumeDropdown(
      AsyncValue<List<ResumeModel>> resumesAsync, AppColors colors, bool isDark) {
    return resumesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error', style: TextStyle(color: Colors.red)),
      data: (resumes) {
        if (resumes.isEmpty) {
          return _buildEmptyState('No saved resumes found. Please upload one.', colors);
        }

        // Initialize _selectedResumeId if it's null or if the selected one is no longer in the list
        if (_selectedResumeId == null || !resumes.any((r) => r.id == _selectedResumeId)) {
          _selectedResumeId = resumes.first.id;
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? colors.cardBackground : colors.screenBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedResumeId,
              dropdownColor: colors.cardBackground,
              decoration: const InputDecoration(border: InputBorder.none, filled: false),
              items: resumes
                  .map((resume) => DropdownMenuItem(
                        value: resume.id,
                        child: Text(
                          resume.title,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedResumeId = value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileUploadArea(AppColors colors, bool isDark) {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? colors.cardBackground : colors.screenBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
          border: _selectedFile != null
              ? Border.all(color: colors.primary.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile == null
                  ? Icons.cloud_upload_outlined
                  : Icons.check_circle_outline,
              size: 48,
              color: _selectedFile == null ? colors.primary : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile == null
                  ? 'Tap to upload PDF'
                  : _selectedFile!.path.split(Platform.pathSeparator).last,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile == null
                  ? 'Only PDF • Max size 10MB'
                  : '${(_selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _selectedFile = null),
                child: const Text('Change File',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: colors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Pro-tip: A score above 75% significantly increases your chances of getting shortlisted.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColors colors;

  const _SourceOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : (isDark ? colors.cardBackground : colors.screenBackground),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : (isDark ? AppTheme.darkShadow : AppTheme.lightShadow),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
