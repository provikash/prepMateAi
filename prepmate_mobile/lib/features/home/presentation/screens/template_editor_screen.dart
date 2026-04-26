import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import '../../providers/home_providers.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateEditorScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'My Resume');
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildResumeData() {
    final skills = _skillsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return {
      'personal_info': {
        'name': _nameController.text.trim(),
        'role': _roleController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'summary': _summaryController.text.trim(),
      },
      'name': _nameController.text.trim(),
      'role': _roleController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'summary': _summaryController.text.trim(),
      'skills': skills,
      'education': <Map<String, dynamic>>[],
      'experience': <Map<String, dynamic>>[],
      'projects': <Map<String, dynamic>>[],
      'skill_groups': {
        'programming_languages': skills.join(', '),
        'mobile_framework': '',
        'architecture': '',
        'ui_ux': '',
        'tools': '',
      },
    };
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dataSource = ref.read(homeRemoteDataSourceProvider);
      final created = await dataSource.createResumeFromTemplate(
        templateId: widget.templateId,
        title: _titleController.text.trim(),
        data: _buildResumeData(),
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(resumeListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume created successfully.')),
      );
      context.push('/resume-view', extra: created.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save resume: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final templateFuture = ref
        .read(homeRemoteDataSourceProvider)
        .getTemplateById(widget.templateId);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        title: const Text('Template Editor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: templateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load template: ${snapshot.error}'),
            );
          }

          final template = snapshot.data;
          if (template == null) {
            return const Center(child: Text('Template not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Preview',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty
                              ? 'Your Name'
                              : _nameController.text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _roleController.text.isEmpty
                              ? template.title
                              : _roleController.text,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _summaryController.text.isEmpty
                              ? 'Write a short summary in the form below.'
                              : _summaryController.text,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skillsController.text
                              .split(',')
                              .map((value) => value.trim())
                              .where((value) => value.isNotEmpty)
                              .map(
                                (skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    skill,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit Resume Form',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _titleController,
                    label: 'Resume Title',
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _nameController,
                    label: 'Full Name',
                    required: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _roleController,
                    label: 'Job Title / Role',
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _emailController,
                    label: 'Email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _phoneController,
                    label: 'Phone',
                    required: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _summaryController,
                    label: 'Professional Summary',
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                  ),
                  _Field(
                    controller: _skillsController,
                    label: 'Skills (comma separated)',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveResume,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Resume'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool required;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.required = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
