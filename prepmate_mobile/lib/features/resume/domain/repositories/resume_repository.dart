import 'dart:typed_data';

import '../../data/models/created_resume_model.dart';
import '../../data/models/resume_model.dart';
import '../../data/models/template_detail_model.dart';

abstract class ResumeRepository {
  Future<TemplateDetailModel> getTemplateDetail(String id);

  Future<CreatedResumeModel> createResume({
    required String templateId,
    required Map<String, dynamic> data,
  });

  Future<String> getResumePdfUrl(String id);

  Future<Uint8List> getResumePdfBytes(String id);

  Future<Uint8List> downloadPdf(String id);

  Future<List<ResumeModel>> getResumes();
}
