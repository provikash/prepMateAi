import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/editor_screen.dart';
import '../widgets/template_card.dart';

class TemplateScreen extends StatelessWidget {
  final int resumeId;

  const TemplateScreen(this.resumeId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Template")),

      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: templatesList.length,
        itemBuilder: (context, index) {
          return TemplateCard(
            template: templatesList[index],
            onSelect: () {

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(resumeId: resumeId,),
                  ));
              // API call + navigate
            },
          );
        },
      ),
    );
  }
}