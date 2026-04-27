import 'dart:typed_data';

import '../../domain/repositories/resume_repository.dart';
import '../datasources/resume_remote_data_source.dart';
import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';

class ResumeRepositoryImpl implements ResumeRepository {
  final ResumeRemoteDataSource remote;

  ResumeRepositoryImpl(this.remote);

  @override
  Future<TemplateDetailModel> getTemplateDetail(String id) =>
      remote.getTemplateDetail(id);

  @override
  Future<CreatedResumeModel> createResume({
    required String templateId,
    required Map<String, dynamic> data,
  }) =>
      remote.createResume(templateId: templateId, data: data);

  @override
  Future<String> getResumePdfUrl(String id) => remote.getResumePdfUrl(id);

  @override
  Future<Uint8List> getResumePdfBytes(String id) => remote.getResumePdfBytes(id);

  @override
  Future<Uint8List> downloadPdf(String id) => remote.downloadPdf(id);

  @override
  Future<List<ResumeModel>> getResumes() => remote.getResumes();
}
