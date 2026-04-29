import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../../config/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/resume_providers.dart';
import '../widgets/dynamic_list_field.dart';
import '../widgets/dynamic_list_object_field.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateFormScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  @override
  void initState() {
    super.initState();
    // show quick debug info about which template id was opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening template: ${widget.templateId}')),
        );
      }
    });
  }
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _sectionTitleControllers = {};
  final Map<String, dynamic> _formData = {};
  bool _initialized = false;
  TemplateDetailModel? _template;
  bool _showedSectionCount = false;

  String _profileValueForField(String key) {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      return '';
    }

    final normalized = key.toLowerCase();
    if (normalized.contains('name')) return user.fullName ?? '';
    if (normalized.contains('email')) return user.email;
    if (normalized.contains('phone')) return user.phoneNumber ?? '';
    if (normalized.contains('title') || normalized.contains('role')) {
      return user.title ?? '';
    }
    if (normalized.contains('location')) return user.location ?? '';
    if (normalized.contains('linkedin')) return user.linkedin ?? '';
    if (normalized.contains('github')) return user.github ?? '';
    if (normalized.contains('summary') || normalized.contains('bio')) {
      return user.bio ?? '';
    }
    return '';
  }

  List<String> _profileListValueForField(String key) {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      return const <String>[];
    }

    final normalized = key.toLowerCase();
    if (normalized.contains('skill') && user.skills != null) {
      return List<String>.from(user.skills!);
    }
    return const <String>[];
  }

  dynamic _getFieldValue(String key) {
    if (!key.contains('.')) {
      return _formData[key];
    }

    final segments = key.split('.');
    dynamic current = _formData;
    for (final segment in segments) {
      if (current is! Map<String, dynamic>) {
        return null;
      }
      current = current[segment];
    }
    return current;
  }

  void _setFieldValue(String key, dynamic value) {
    if (!key.contains('.')) {
      _formData[key] = value;
      return;
    }

    final segments = key.split('.');
    Map<String, dynamic> current = _formData;
    for (var index = 0; index < segments.length - 1; index++) {
      final segment = segments[index];
      final existing = current[segment];
      if (existing is! Map<String, dynamic>) {
        current[segment] = <String, dynamic>{};
      }
      current = current[segment] as Map<String, dynamic>;
    }
    current[segments.last] = value;
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    final copied = <String, dynamic>{};
    for (final entry in source.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        copied[entry.key] = _deepCopyMap(value);
      } else if (value is List) {
        copied[entry.key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _deepCopyMap(item);
          }
          return item;
        }).toList();
      } else {
        copied[entry.key] = value;
      }
    }
    return copied;
  }

  List<String> _normalizeDetailList(dynamic rawDetails) {
    if (rawDetails is List) {
      return rawDetails
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (rawDetails is String) {
      final normalized = rawDetails.replaceAll('\r\n', '\n').trim();
      if (normalized.isEmpty) {
        return const <String>[];
      }

      final lines = normalized
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.length > 1) {
        return lines;
      }

      return normalized
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const <String>[];
  }

  void _normalizeObjectDetailLists(Map<String, dynamic> payload, String key) {
    final raw = payload[key];
    if (raw is! List) {
      payload[key] = <Map<String, dynamic>>[];
      return;
    }

    payload[key] = raw.whereType<Map>().map((item) {
      final mapped = <String, dynamic>{
        for (final entry in item.entries)
          entry.key.toString(): entry.value,
      };
      if (mapped.containsKey('details')) {
        mapped['details'] = _normalizeDetailList(mapped['details']);
      }
      return mapped;
    }).toList();
  }

  Map<String, dynamic> _buildSubmissionData() {
    final payload = _deepCopyMap(_formData);
    _normalizeObjectDetailLists(payload, 'education');
    _normalizeObjectDetailLists(payload, 'experience');
    return payload;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _sectionTitleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialize(TemplateDetailModel template) {
    if (_initialized) {
      return;
    }

    for (var sectionIndex = 0; sectionIndex < template.sections.length; sectionIndex++) {
      final section = template.sections[sectionIndex];
      _sectionTitleControllers[sectionIndex] = TextEditingController(text: section.title);
      for (final field in section.fields) {
        // Try to prefill from template raw schema first
        dynamic templateValue;
        try {
          templateValue = _valueFromTemplate(field.key, template.rawSchema);
        } catch (e) {
          templateValue = null;
        }

        if (field.isList) {
          final listVal = templateValue is List ? List<String>.from(templateValue.map((e) => e.toString())) : _profileListValueForField(field.key);
          _setFieldValue(field.key, listVal);
        } else if (field.isListObject) {
          final items = <Map<String, String>>[];
          if (templateValue is List) {
            for (final item in templateValue) {
              if (item is Map) {
                final mapped = <String, String>{};
                for (final of in field.objectFields) {
                  final v = item[of.key] ?? item[of.key.toString()];
                  mapped[of.key] = v?.toString() ?? '';
                }
                items.add(mapped);
              }
            }
          }
          _setFieldValue(field.key, items);
        } else {
          final initialValue = templateValue != null ? templateValue.toString() : _profileValueForField(field.key);
          _controllers[field.key] = TextEditingController(text: initialValue);
          _setFieldValue(field.key, initialValue);
        }
      }
    }

    _template = template;
    _initialized = true;
  }

  dynamic _valueFromTemplate(String key, Map<String, dynamic> schema) {
    if (schema.isEmpty) return null;

    if (!key.contains('.')) {
      // handle top-level keys
      if (key == 'skills') {
        final s = schema['skills'];
        if (s is List) {
          return s.map((e) {
            if (e is Map) return e['name'] ?? (e['keywords'] is List ? (e['keywords'] as List).join(', ') : null) ?? '';
            return e?.toString() ?? '';
          }).where((e) => e != null).toList();
        }
      }

      if (key == 'experience' || key == 'work') {
        final w = schema['work'] ?? schema['experience'];
        if (w is List) {
          return w.map((e) {
            if (e is Map) {
              return {
                'title': e['position'] ?? e['title'] ?? '',
                'company': e['company'] ?? '',
                'startDate': e['startDate'] ?? e['start'] ?? '',
                'endDate': e['endDate'] ?? e['end'] ?? '',
                'summary': e['summary'] ?? e['description'] ?? '',
              };
            }
            return <String, String>{};
          }).toList();
        }
      }

      if (schema.containsKey(key)) return schema[key];
      return null;
    }

    final segments = key.split('.');
    dynamic current = schema;
    for (final seg in segments) {
      if (current is! Map<String, dynamic>) return null;
      if (!current.containsKey(seg)) return null;
      current = current[seg];
    }
    return current;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    for (final entry in _controllers.entries) {
      _setFieldValue(entry.key, entry.value.text.trim());
    }

    final template = _template;
    if (template != null) {
      for (final section in template.sections) {
        for (final field in section.fields) {
          if (!field.isList) {
            if (!field.isListObject) {
              continue;
            }

            final objectItems = (_getFieldValue(field.key) as List?) ?? const [];
            if (objectItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${field.label} requires at least one item.')),
              );
              return;
            }
            continue;
          }
          final values = (_getFieldValue(field.key) as List?) ?? const [];
          if (values.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${field.label} is required.')),
            );
            return;
          }
        }
      }
    }

    final submissionData = _buildSubmissionData();

    final created = await ref.read(createResumeProvider.notifier).submit(
      templateId: widget.templateId,
      formData: submissionData,
    );

    if (!mounted) {
      return;
    }

    if (created != null) {
      ref.invalidate(storedResumesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume created successfully.')),
      );
      context.push('/resume-view', extra: created.id);
      return;
    }

    final error = ref.read(createResumeProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Failed to create resume.')),
    );
  }

  Future<void> _callAi(String path, Map<String, dynamic> payload) async {
    final dio = ref.read(dioProvider);
    try {
      final resp = await dio.post(path, data: payload);
      final data = resp.data;
      final taskId = data is Map ? data['task_id'] : null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskId != null ? 'Task queued: $taskId' : 'AI request queued')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI request failed: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _collectAiInputs(List<Map<String, String>> required) async {
    // required: list of {'key': 'role', 'label': 'Role'}
    final Map<String, TextEditingController> ctrls = {};
    for (final r in required) {
      ctrls[r['key']!] = TextEditingController();
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Additional AI inputs'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final r in required)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: ctrls[r['key']!],
                      decoration: InputDecoration(labelText: r['label'] ?? r['key']),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final Map<String, dynamic> out = {};
              for (final e in ctrls.entries) {
                out[e.key] = e.value.text.trim();
              }
              Navigator.of(ctx).pop(out);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // dispose
    for (final c in ctrls.values) c.dispose();
    return result;
  }

  Future<void> _preview() async {
    final dio = ref.read(dioProvider);
    final payload = _buildSubmissionData();
    final url = 'exports/templates/${widget.templateId}/preview/';
    try {
      final resp = await dio.post(url, data: {'data': payload}, options: Options(responseType: ResponseType.plain));
      final html = resp.data?.toString() ?? '';
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preview'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Html(data: html),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.templateId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resume Form')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Template not specified.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final templateAsync = ref.watch(templateDetailProvider(widget.templateId));
    final createState = ref.watch(createResumeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resume Form')),
      body: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          // show an actionable error with retry
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load template:\n${error.toString()}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => ref.refresh(templateDetailProvider(widget.templateId)),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        data: (template) {
          _initialize(template);
          if (!_showedSectionCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template loaded with ${template.sections.length} sections')),
                );
              }
            });
            _showedSectionCount = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  template.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                // AI action buttons + Preview
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final resumeData = _buildSubmissionData();
                        final experience = resumeData['experience'] ?? resumeData['work'] ?? [];
                        if (experience == null || (experience is List && experience.isEmpty)) {
                          // ask the user for experience entries
                          final resp = await _collectAiInputs([
                            {'key': 'experience_text', 'label': 'Experience (one per line, format: title|company|start|end|summary)'}
                          ]);
                          if (resp == null) return;
                          final lines = (resp['experience_text'] as String).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                          final parsed = lines.map((line) {
                            final parts = line.split('|');
                            return {
                              'title': parts.length > 0 ? parts[0] : '',
                              'company': parts.length > 1 ? parts[1] : '',
                              'startDate': parts.length > 2 ? parts[2] : '',
                              'endDate': parts.length > 3 ? parts[3] : '',
                              'summary': parts.length > 4 ? parts[4] : '',
                            };
                          }).toList();
                          await _callAi('/ai/generate-bullets/', {'experience': parsed});
                        } else {
                          await _callAi('/ai/generate-bullets/', {'experience': experience});
                        }
                      },
                      child: const Text('AI Bullets'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final resumeData = _buildSubmissionData();
                        final role = (resumeData['basics'] != null && resumeData['basics']['label'] != null) ? resumeData['basics']['label'] : '';
                        if (role == null || role.isEmpty) {
                          final resp = await _collectAiInputs([{'key': 'role', 'label': 'Role / Job Title'}]);
                          if (resp == null) return;
                          await _callAi('/ai/generate-summary/', {'role': resp['role']});
                        } else {
                          await _callAi('/ai/generate-summary/', {'role': role});
                        }
                      },
                      child: const Text('AI Summary'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final resumeData = _buildSubmissionData();
                        final text = (resumeData['basics'] != null && resumeData['basics']['summary'] != null) ? resumeData['basics']['summary'] : '';
                        if (text == null || text.isEmpty) {
                          final resp = await _collectAiInputs([{'key': 'text', 'label': 'Text to improve'}]);
                          if (resp == null) return;
                          await _callAi('/ai/improve-section/', {'text': resp['text'], 'section_name': 'summary'});
                        } else {
                          await _callAi('/ai/improve-section/', {'text': text, 'section_name': 'summary'});
                        }
                      },
                      child: const Text('AI Improve'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final resumeData = _buildSubmissionData();
                        final role = (resumeData['basics'] != null && resumeData['basics']['label'] != null) ? resumeData['basics']['label'] : '';
                        final existing = (resumeData['skills'] is List) ? resumeData['skills'].map((s) => s is Map ? s['name'] ?? '' : s).toList() : [];
                        if (role == null || role.isEmpty) {
                          final resp = await _collectAiInputs([{'key': 'role', 'label': 'Role / Job Title'}]);
                          if (resp == null) return;
                          await _callAi('/ai/suggest-skills/', {'role': resp['role'], 'existing_skills': existing});
                        } else {
                          await _callAi('/ai/suggest-skills/', {'role': role, 'existing_skills': existing});
                        }
                      },
                      child: const Text('AI Skills'),
                    ),
                    OutlinedButton(
                      onPressed: _preview,
                      child: const Text('Preview'),
                    ),
                  ],
                ),
                for (var sectionIndex = 0; sectionIndex < template.sections.length; sectionIndex++) ...[
                  TextFormField(
                    controller: _sectionTitleControllers[sectionIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Section title',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final field in template.sections[sectionIndex].fields) ...[
                    if (field.isList)
                      DynamicListField(
                        label: field.label,
                        initialItems:
                            ((_getFieldValue(field.key) as List?) ?? const [])
                                .whereType<String>()
                                .toList(),
                        onChanged: (value) => _setFieldValue(field.key, value),
                      )
                    else if (field.isListObject)
                      DynamicListObjectField(
                        label: field.label,
                        itemFields: field.objectFields,
                        initialItems:
                            ((_getFieldValue(field.key) as List?) ?? const [])
                                .whereType<Map>()
                                .map(
                                  (item) => item.map(
                                    (key, value) => MapEntry(
                                      key.toString(),
                                      value?.toString() ?? '',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => _setFieldValue(field.key, value),
                      )
                    else
                      TextFormField(
                        controller: _controllers[field.key],
                        decoration: InputDecoration(labelText: field.label),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '${field.label} is required';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: createState.isLoading ? null : _submit,
                    child: createState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Resume'),
                  ),
                ),
                if (createState.error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    createState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
