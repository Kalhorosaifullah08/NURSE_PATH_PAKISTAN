import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

enum SemesterAvailability { planned, generating, review, published }

class SemesterStatus {
  const SemesterStatus({
    required this.semester,
    required this.status,
    required this.packageVersion,
    required this.packageUrl,
    required this.itemCount,
    required this.updatedAt,
  });

  factory SemesterStatus.fromJson(Map<String, dynamic> json) => SemesterStatus(
    semester: json['semester'] as int,
    status: SemesterAvailability.values.byName(json['status'] as String),
    packageVersion: json['packageVersion'] as String?,
    packageUrl: json['packageUrl'] as String?,
    itemCount: json['itemCount'] as int? ?? 0,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  final int semester;
  final SemesterAvailability status;
  final String? packageVersion;
  final String? packageUrl;
  final int itemCount;
  final DateTime? updatedAt;
}

class GeneratedContentItem {
  const GeneratedContentItem({
    required this.id,
    required this.courseId,
    required this.type,
    required this.body,
    required this.sourceIds,
    required this.risk,
  });

  factory GeneratedContentItem.fromJson(Map<String, dynamic> json) =>
      GeneratedContentItem(
        id: json['id'] as String,
        courseId: json['courseId'] as String? ?? '',
        type: json['contentType'] as String? ?? 'unknown',
        body: Map<String, dynamic>.from(json['body'] as Map? ?? const {}),
        sourceIds: List<String>.from(json['sourceIds'] as List? ?? const []),
        risk: json['risk'] as String? ?? 'academic',
      );

  final String id;
  final String courseId;
  final String type;
  final Map<String, dynamic> body;
  final List<String> sourceIds;
  final String risk;
}

class SemesterPackage {
  const SemesterPackage({
    required this.semester,
    required this.version,
    required this.items,
  });

  factory SemesterPackage.fromJson(Map<String, dynamic> json) =>
      SemesterPackage(
        semester: json['semester'] as int,
        version:
            json['packageVersion'] as String? ??
            json['exportedAt'] as String? ??
            '1',
        items: (json['items'] as List? ?? const [])
            .map(
              (item) => GeneratedContentItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );

  final int semester;
  final String version;
  final List<GeneratedContentItem> items;

  List<GeneratedContentItem> forCourse(String courseId) =>
      items.where((item) => item.courseId == courseId).toList(growable: false);
}

class ContentRepository {
  ContentRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  List<SemesterStatus>? _manifestCache;
  final Map<int, SemesterPackage> _packageCache = {};

  Uri _remote(String path) => kIsWeb
      ? Uri.base.resolve(path)
      : Uri.parse('https://deft-reporter-485519-i1.web.app/$path');

  Future<List<SemesterStatus>> manifest({bool refresh = false}) async {
    if (!refresh && _manifestCache != null) return _manifestCache!;
    try {
      final response = await _client.get(_remote('content/manifest.json'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        _manifestCache = (decoded['semesters'] as List)
            .map(
              (item) => SemesterStatus.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
        return _manifestCache!;
      }
    } catch (_) {
      // The bundled manifest keeps the app usable offline.
    }
    final bundled = await rootBundle.loadString('assets/content/manifest.json');
    final decoded = jsonDecode(bundled) as Map<String, dynamic>;
    return _manifestCache = (decoded['semesters'] as List)
        .map(
          (item) =>
              SemesterStatus.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<SemesterPackage?> packageFor(
    int semester, {
    bool refresh = false,
  }) async {
    if (!refresh && _packageCache.containsKey(semester)) {
      return _packageCache[semester];
    }
    final statuses = await manifest(refresh: refresh);
    final status = statuses
        .where((item) => item.semester == semester)
        .firstOrNull;
    if (status == null ||
        status.status != SemesterAvailability.published ||
        status.packageUrl == null) {
      return null;
    }
    try {
      final response = await _client.get(_remote(status.packageUrl!));
      if (response.statusCode != 200) return null;
      final package = SemesterPackage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _packageCache[semester] = package;
      return package;
    } catch (_) {
      return null;
    }
  }
}

final contentRepository = ContentRepository();
