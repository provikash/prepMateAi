class UserPreferences {
  const UserPreferences({
    this.notificationOptimization = true,
    this.notificationAiTasks = true,
    this.notificationBilling = true,
    this.notificationSecurity = true,
    this.notificationTips = false,
    this.theme = 'system',
    this.language = 'en',
    this.pdfPageSize = 'a4',
    this.dataUsage = 'standard',
    this.accessibility = 'standard',
  });

  final bool notificationOptimization;
  final bool notificationAiTasks;
  final bool notificationBilling;
  final bool notificationSecurity;
  final bool notificationTips;
  final String theme;
  final String language;
  final String pdfPageSize;
  final String dataUsage;
  final String accessibility;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationOptimization: json['notification_optimization'] ?? true,
      notificationAiTasks: json['notification_ai_tasks'] ?? true,
      notificationBilling: json['notification_billing'] ?? true,
      notificationSecurity: json['notification_security'] ?? true,
      notificationTips: json['notification_tips'] ?? false,
      theme: json['theme']?.toString() ?? 'system',
      language: json['language']?.toString() ?? 'en',
      pdfPageSize: json['pdf_page_size']?.toString() ?? 'a4',
      dataUsage: json['data_usage']?.toString() ?? 'standard',
      accessibility: json['accessibility']?.toString() ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() => {
        'notification_optimization': notificationOptimization,
        'notification_ai_tasks': notificationAiTasks,
        'notification_billing': notificationBilling,
        'notification_security': notificationSecurity,
        'notification_tips': notificationTips,
        'theme': theme,
        'language': language,
        'pdf_page_size': pdfPageSize,
        'data_usage': dataUsage,
        'accessibility': accessibility,
      };

  UserPreferences copyWith({
    bool? notificationOptimization,
    bool? notificationAiTasks,
    bool? notificationBilling,
    bool? notificationSecurity,
    bool? notificationTips,
    String? theme,
    String? language,
    String? pdfPageSize,
    String? dataUsage,
    String? accessibility,
  }) {
    return UserPreferences(
      notificationOptimization:
          notificationOptimization ?? this.notificationOptimization,
      notificationAiTasks: notificationAiTasks ?? this.notificationAiTasks,
      notificationBilling: notificationBilling ?? this.notificationBilling,
      notificationSecurity: notificationSecurity ?? this.notificationSecurity,
      notificationTips: notificationTips ?? this.notificationTips,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      pdfPageSize: pdfPageSize ?? this.pdfPageSize,
      dataUsage: dataUsage ?? this.dataUsage,
      accessibility: accessibility ?? this.accessibility,
    );
  }
}

class DataExportStatus {
  const DataExportStatus({
    required this.status,
    this.requestedAt,
    this.readyAt,
    this.expiresAt,
    this.downloadUrl,
  });

  final String status;
  final DateTime? requestedAt;
  final DateTime? readyAt;
  final DateTime? expiresAt;
  final String? downloadUrl;

  bool get isReady => status == 'ready';
  bool get isPreparing => status == 'preparing';
  bool get isExpired => status == 'expired';

  factory DataExportStatus.fromJson(Map<String, dynamic> json) {
    return DataExportStatus(
      status: json['status']?.toString() ?? 'not_requested',
      requestedAt: json['requested_at'] == null
          ? null
          : DateTime.tryParse(json['requested_at'].toString()),
      readyAt: json['ready_at'] == null
          ? null
          : DateTime.tryParse(json['ready_at'].toString()),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse(json['expires_at'].toString()),
      downloadUrl: json['download_url']?.toString(),
    );
  }
}

class AccountDeletionStatus {
  const AccountDeletionStatus({
    required this.isScheduled,
    this.scheduledAt,
    this.effectiveDate,
    this.recoveryDaysRemaining,
    this.activeSubscription = false,
    this.reservedCredits = 0,
    this.pendingOrders = 0,
    this.activeAiJobs = 0,
    this.consequences = const [],
    this.legallyRetained = const [],
  });

  final bool isScheduled;
  final DateTime? scheduledAt;
  final DateTime? effectiveDate;
  final int? recoveryDaysRemaining;
  final bool activeSubscription;
  final int reservedCredits;
  final int pendingOrders;
  final int activeAiJobs;
  final List<String> consequences;
  final List<String> legallyRetained;

  factory AccountDeletionStatus.fromJson(Map<String, dynamic> json) {
    return AccountDeletionStatus(
      isScheduled: json['is_scheduled'] == true,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.tryParse(json['scheduled_at'].toString()),
      effectiveDate: json['effective_date'] == null
          ? null
          : DateTime.tryParse(json['effective_date'].toString()),
      recoveryDaysRemaining: json['recovery_days_remaining'] is num
          ? (json['recovery_days_remaining'] as num).toInt()
          : null,
      activeSubscription: json['active_subscription'] == true,
      reservedCredits: (json['reserved_credits'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pending_orders'] as num?)?.toInt() ?? 0,
      activeAiJobs: (json['active_ai_jobs'] as num?)?.toInt() ?? 0,
      consequences: (json['consequences'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      legallyRetained: (json['legally_retained'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CachedValue<T> {
  const CachedValue({
    required this.value,
    required this.updatedAt,
    this.isStale = false,
    this.isOffline = false,
  });

  final T value;
  final DateTime updatedAt;
  final bool isStale;
  final bool isOffline;
}

class CountryOption {
  const CountryOption({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String code;
  final String dialCode;
  final String flag;

  factory CountryOption.fromJson(Map<String, dynamic> json) => CountryOption(
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        dialCode: json['dial_code']?.toString() ?? '',
        flag: json['flag']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'dial_code': dialCode,
        'flag': flag,
      };
}

class IndustryOption {
  const IndustryOption({
    required this.name,
    required this.category,
  });

  final String name;
  final String category;

  factory IndustryOption.fromJson(Map<String, dynamic> json) => IndustryOption(
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
      };
}

class TimeZoneOption {
  const TimeZoneOption({
    required this.name,
    required this.id,
  });

  final String name;
  final String id;

  factory TimeZoneOption.fromJson(Map<String, dynamic> json) => TimeZoneOption(
        name: json['name']?.toString() ?? '',
        id: json['id']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
      };
}

class ProfileMetadata {
  const ProfileMetadata({
    this.countries = const [],
    this.industries = const [],
    this.timeZones = const [],
  });

  final List<CountryOption> countries;
  final List<IndustryOption> industries;
  final List<TimeZoneOption> timeZones;

  factory ProfileMetadata.fromJson(Map<String, dynamic> json) => ProfileMetadata(
        countries: (json['countries'] as List? ?? const [])
            .map((e) => CountryOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        industries: (json['industries'] as List? ?? const [])
            .map((e) => IndustryOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        timeZones: (json['time_zones'] as List? ?? const [])
            .map((e) => TimeZoneOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class OfflineDraftItem {
  const OfflineDraftItem({
    required this.field,
    required this.label,
    required this.displayValue,
    required this.timestamp,
  });

  final String field;
  final String label;
  final String displayValue;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'field': field,
        'label': label,
        'displayValue': displayValue,
        'timestamp': timestamp.toIso8601String(),
      };

  factory OfflineDraftItem.fromJson(Map<String, dynamic> json) => OfflineDraftItem(
        field: json['field']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        displayValue: json['displayValue']?.toString() ?? '',
        timestamp: json['timestamp'] == null
            ? DateTime.now()
            : DateTime.parse(json['timestamp']),
      );
}

class ProfileConflictException implements Exception {
  const ProfileConflictException({
    required this.message,
    required this.serverVersion,
    required this.serverData,
  });

  final String message;
  final int serverVersion;
  final Map<String, dynamic> serverData;

  @override
  String toString() => message;
}

class CascadeResumesResult {
  const CascadeResumesResult({
    required this.updatedCount,
    required this.message,
    this.resumes = const [],
  });

  final int updatedCount;
  final String message;
  final List<Map<String, dynamic>> resumes;

  factory CascadeResumesResult.fromJson(Map<String, dynamic> json) =>
      CascadeResumesResult(
        updatedCount: (json['updated_count'] as num?)?.toInt() ?? 0,
        message: json['message']?.toString() ?? '',
        resumes: (json['resumes'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

