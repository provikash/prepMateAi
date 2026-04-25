import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
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
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      ref.read(analyzeProvider.notifier).analyze(
        file: _selectedFile,
        jobRole: _roleController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyzeProvider);

    ref.listen(analyzeProvider, (previous, next) {
      if (next.data != null) {
        // Navigate to result screen
        context.push('/ats-result', extra: next.data);
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Analyze Resume', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Optimize Your Career",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Upload your resume and specify the target role to get an AI-powered ATS analysis.",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Target Job Role',
                  hintText: 'e.g. Senior Product Designer',
                  prefixIcon: const Icon(Icons.work_outline, color: AppTheme.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile == null 
                          ? 'Upload PDF Resume (Max 10MB)' 
                          : _selectedFile!.path.split('/').last,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      if (_selectedFile == null)
                        const Text(
                          'Only PDF files are supported',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Analyze Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
