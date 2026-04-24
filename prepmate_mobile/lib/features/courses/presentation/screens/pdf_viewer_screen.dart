import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../data/models/course_model.dart';

class PdfViewerScreen extends StatelessWidget {
  final Course course;

  const PdfViewerScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share logic
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        course.url,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
