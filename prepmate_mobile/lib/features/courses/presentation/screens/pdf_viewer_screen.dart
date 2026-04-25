import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../data/models/course_model.dart';

class PdfViewerScreen extends StatefulWidget {
  final Course course;

  const PdfViewerScreen({super.key, required this.course});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();

    _controller = PdfControllerPinch(
      document: PdfDocument.openDataFromUrl(widget.course.url),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share logic
            },
          ),
        ],
      ),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
