import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a complete résumé PDF without calling the API.
///
/// The input follows the JSON Resume-shaped data already produced by the
/// résumé form. Unknown or empty sections are ignored so partially completed
/// drafts can still be previewed offline.
class LocalResumePdfGenerator {
  const LocalResumePdfGenerator();

  Future<Uint8List> generate({
    required Map<String, dynamic> data,
    String templateId = 'offline-professional',
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
    );
    final accent = _accentFor(templateId);
    final basics = _map(data['basics']);
    final name = _first(
      basics['name'],
      basics['full_name'],
      data['name'],
      'Your Name',
    );
    final headline = _first(basics['label'], basics['title'], data['title']);
    final contact = <String>[
      _first(basics['email']),
      _first(basics['phone'], basics['phone_number']),
      _location(basics['location']),
      _first(basics['linkedin'], basics['website'], basics['url']),
    ].where((item) => item.isNotEmpty).toList(growable: false);

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 14),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: accent, width: 2)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                if (headline.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    headline,
                    style: pw.TextStyle(fontSize: 12, color: accent),
                  ),
                ],
                if (contact.isNotEmpty) ...[
                  pw.SizedBox(height: 7),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 3,
                    children: contact
                        .map(
                          (item) => pw.Text(
                            item,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          ..._summary(basics, accent),
          ..._entriesSection(
            title: 'Experience',
            values: _list(data['work']).isNotEmpty
                ? _list(data['work'])
                : _list(data['experience']),
            accent: accent,
            heading: (entry) =>
                _first(entry['position'], entry['title'], null, 'Role'),
            subheading: (entry) =>
                _first(entry['name'], entry['company'], entry['organization']),
          ),
          ..._entriesSection(
            title: 'Education',
            values: _list(data['education']),
            accent: accent,
            heading: (entry) => _first(
              entry['studyType'],
              entry['degree'],
              entry['area'],
              'Education',
            ),
            subheading: (entry) =>
                _first(entry['institution'], entry['school']),
          ),
          ..._skills(data['skills'], accent),
          ..._entriesSection(
            title: 'Projects',
            values: _list(data['projects']),
            accent: accent,
            heading: (entry) =>
                _first(entry['name'], entry['title'], null, 'Project'),
            subheading: (entry) => _first(entry['role'], entry['url']),
          ),
          ..._entriesSection(
            title: 'Certifications',
            values: _list(data['certificates']).isNotEmpty
                ? _list(data['certificates'])
                : _list(data['certifications']),
            accent: accent,
            heading: (entry) =>
                _first(entry['name'], entry['title'], 'Certification'),
            subheading: (entry) => _first(entry['issuer']),
          ),
        ],
      ),
    );
    return document.save();
  }

  List<pw.Widget> _summary(Map<String, dynamic> basics, PdfColor accent) {
    final value = _first(basics['summary'], basics['bio']);
    if (value.isEmpty) return const [];
    return [
      _sectionTitle('Profile', accent),
      pw.Text(value, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
    ];
  }

  List<pw.Widget> _entriesSection({
    required String title,
    required List<Map<String, dynamic>> values,
    required PdfColor accent,
    required String Function(Map<String, dynamic>) heading,
    required String Function(Map<String, dynamic>) subheading,
  }) {
    if (values.isEmpty) return const [];
    return [
      _sectionTitle(title, accent),
      ...values.map((entry) {
        final dates = _dateRange(entry);
        final details = _first(entry['summary'], entry['description']);
        final highlights = _strings(entry['highlights']);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      heading(entry),
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dates.isNotEmpty)
                    pw.Text(
                      dates,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                ],
              ),
              if (subheading(entry).isNotEmpty)
                pw.Text(
                  subheading(entry),
                  style: pw.TextStyle(fontSize: 9, color: accent),
                ),
              if (details.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(details, style: const pw.TextStyle(fontSize: 9)),
              ],
              ...highlights.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, left: 5),
                  child: pw.Text(
                    '- $item',
                    style: const pw.TextStyle(fontSize: 8.7),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  List<pw.Widget> _skills(dynamic raw, PdfColor accent) {
    final labels = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final name = _first(map['name']);
          final keywords = _strings(map['keywords']);
          final value = [
            name,
            ...keywords,
          ].where((e) => e.isNotEmpty).join(': ');
          if (value.isNotEmpty) labels.add(value);
        } else if (_first(item).isNotEmpty) {
          labels.add(_first(item));
        }
      }
    } else if (_first(raw).isNotEmpty) {
      labels.addAll(_first(raw).split(',').map((e) => e.trim()));
    }
    if (labels.isEmpty) return const [];
    return [
      _sectionTitle('Skills', accent),
      pw.Wrap(
        spacing: 6,
        runSpacing: 5,
        children: labels
            .map(
              (label) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor(accent.red, accent.green, accent.blue, .09),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
              ),
            )
            .toList(),
      ),
    ];
  }

  pw.Widget _sectionTitle(String value, PdfColor accent) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(
      value.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1,
        color: accent,
      ),
    ),
  );

  PdfColor _accentFor(String id) {
    if (id.contains('modern')) return PdfColor.fromHex('#0F766E');
    if (id.contains('simple')) return PdfColor.fromHex('#374151');
    return PdfColor.fromHex('#2457D6');
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false)
      : const [];

  List<String> _strings(dynamic value) => value is List
      ? value
            .map((item) => _first(item))
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const [];

  String _first(
    dynamic first, [
    dynamic second,
    dynamic third,
    String fallback = '',
  ]) {
    for (final value in [first, second, third]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  String _location(dynamic raw) {
    if (raw is Map) {
      final location = Map<String, dynamic>.from(raw);
      return [
        _first(location['city']),
        _first(
          location['region'],
          location['countryCode'],
          location['country'],
        ),
      ].where((item) => item.isNotEmpty).join(', ');
    }
    return _first(raw);
  }

  String _dateRange(Map<String, dynamic> entry) {
    final start = _first(entry['startDate'], entry['start_date']);
    final end = _first(entry['endDate'], entry['end_date']);
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }
}
