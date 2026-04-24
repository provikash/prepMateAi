import 'package:flutter/material.dart';

class AtsAnalysis {
  final int score;
  final String status;
  final String role;
  final List<AtsInsight> insights;

  AtsAnalysis({
    required this.score,
    required this.status,
    required this.role,
    required this.insights,
  });
}

enum InsightStatus { success, warning, error }

class AtsInsight {
  final String title;
  final String description;
  final InsightStatus status;

  AtsInsight({
    required this.title,
    required this.description,
    required this.status,
  });
}
