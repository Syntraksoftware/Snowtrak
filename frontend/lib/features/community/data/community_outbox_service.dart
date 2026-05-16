import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CommunityOutboxOperation {
  CommunityOutboxOperation({
    required this.id,
    required this.type,
    required this.payload,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  CommunityOutboxOperation copyWith({
    int? retryCount,
  }) {
    return CommunityOutboxOperation(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  static CommunityOutboxOperation fromJson(Map<String, dynamic> json) {
    return CommunityOutboxOperation(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityOutboxService {
  static const String _key = 'community_outbox_v1';

  Future<List<CommunityOutboxOperation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((e) => CommunityOutboxOperation.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<void> save(List<CommunityOutboxOperation> operations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(operations.map((o) => o.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> enqueue(CommunityOutboxOperation operation) async {
    final current = await load();
    current.add(operation);
    await save(current);
  }

  Future<void> removeById(String id) async {
    final current = await load();
    current.removeWhere((o) => o.id == id);
    await save(current);
  }

  Future<void> replaceAll(List<CommunityOutboxOperation> operations) async {
    await save(operations);
  }
}
