import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/therapist_rules.dart';

abstract class TherapistRulesCloudRepository {
  Future<TherapistRules?> load(String parentId);

  Future<void> save(String parentId, TherapistRules rules);
}

class NoopTherapistRulesCloudRepository
    implements TherapistRulesCloudRepository {
  @override
  Future<TherapistRules?> load(String parentId) async => null;

  @override
  Future<void> save(String parentId, TherapistRules rules) async {}
}

class SupabaseTherapistRulesRepository
    implements TherapistRulesCloudRepository {
  SupabaseTherapistRulesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TherapistRules?> load(String parentId) async {
    final row = await _client
        .from('therapist_rules')
        .select('rules')
        .eq('parent_id', parentId)
        .maybeSingle();
    if (row == null) return null;
    return TherapistRules(
      rules: List<String>.from(row['rules'] as List? ?? const []),
    );
  }

  @override
  Future<void> save(String parentId, TherapistRules rules) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Terapist kurallarını kaydetmek için giriş yapın.');
    }
    await _client.from('therapist_rules').upsert({
      'parent_id': parentId,
      'rules': rules.rules,
      'updated_by': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
