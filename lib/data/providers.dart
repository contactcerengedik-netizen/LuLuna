import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import 'ai/decision_engine.dart';
import 'ai/prompt_builder.dart';
import 'hardware/background_monitor_service.dart';
import 'hardware/ble_audio_output.dart';
import 'hardware/hardware_monitor.dart';
import 'models/achievement_badge.dart';
import 'models/assistant_log.dart';
import 'models/auth_session.dart';
import 'models/child_profile.dart';
import 'models/crisis_state.dart';
import 'models/device_status.dart';
import 'models/pairing_link.dart';
import 'models/report_stats.dart';
import 'models/therapist_rules.dart';
import 'models/user_role.dart';
import 'repositories/assistant_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/badge_repository.dart';
import 'repositories/device_repository.dart';
import 'repositories/log_queue_repository.dart';
import 'repositories/pairing_repository.dart';
import 'repositories/parent_voice_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/supabase_auth_repository.dart';
import 'repositories/supabase_pairing_repository.dart';
import 'repositories/therapist_rules_repository.dart';
import 'services/connectivity_service.dart';
import 'services/crisis_audio_service.dart';
import 'services/offline_fallback_service.dart';
import 'services/permissions_service.dart';
import 'services/remote_log_client.dart';
import 'services/speech_service.dart';
import 'services/sync_service.dart';

/// main() içinde gerçek instance ile override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
);

/// Supabase client. `Env.hasSupabase` false ise null (yerel demo).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.hasSupabase) return null;
  return Supabase.instance.client;
});

/// Oturum açan kullanıcıya göre ayrılmış profil deposu.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s?.userId));
  return ProfileRepository(
    ref.watch(sharedPreferencesProvider),
    userId: userId,
  );
});

/// Supabase anahtarı varsa gerçek Auth, yoksa yerel demo.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseAuthRepository(prefs, client);
  return LocalAuthRepository(prefs);
});

/// Supabase varsa kodlar bulutta (çok cihazlı eşleşme), yoksa yerel demo.
final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(authStateProvider.select((s) => s?.userId));
  if (client != null) return SupabasePairingRepository(prefs, client);
  return LocalPairingRepository(prefs, userId: userId);
});

final parentVoiceRepositoryProvider = Provider<ParentVoiceRepository>(
  (ref) => ParentVoiceRepository(ref.watch(sharedPreferencesProvider)),
);

final therapistRulesCloudRepositoryProvider =
    Provider<TherapistRulesCloudRepository>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return client == null
          ? NoopTherapistRulesCloudRepository()
          : SupabaseTherapistRulesRepository(client);
    });

final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s?.userId));
  return PermissionsService(
    ref.watch(sharedPreferencesProvider),
    userId: userId,
  );
});

final badgeRepositoryProvider = Provider<BadgeRepository>(
  (ref) => BadgeRepository(ref.watch(sharedPreferencesProvider)),
);

final logQueueRepositoryProvider = Provider<LogQueueRepository>((ref) {
  final repo = LogQueueRepository();
  ref.onDispose(repo.close);
  return repo;
});

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

final remoteLogClientProvider = Provider<RemoteLogClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseRemoteLogClient(client);
  if (Env.hasSyncEndpoint) {
    return DioRemoteLogClient(endpoint: Env.syncEndpoint);
  }
  return InMemoryRemoteLogClient();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    queue: ref.watch(logQueueRepositoryProvider),
    remote: ref.watch(remoteLogClientProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

final pendingSyncCountProvider = StreamProvider<int>((ref) async* {
  final sync = ref.watch(syncServiceProvider);
  yield await sync.pendingCount;
  yield* sync.pendingCountStream;
});

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityServiceProvider);
  yield await connectivity.isOnline;
  yield* connectivity.onStatusChanged;
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = FlutterTtsSpeechService();
  final tone = ref.watch(appStateProvider.select((s) => s.profile?.voiceTone));
  if (tone != null) service.configureTone(tone);
  return service;
});

final crisisAudioServiceProvider = Provider<CrisisAudioService>(
  (ref) => AudioPlayersCrisisService(
    parentVoicePathResolver: () =>
        ref.read(parentVoiceRepositoryProvider).loadPath(),
  ),
);

final offlineFallbackServiceProvider = Provider<OfflineFallbackService>(
  (ref) =>
      AssetOfflineFallbackService(speech: ref.watch(speechServiceProvider)),
);

final decisionEngineProvider = Provider<DecisionEngine>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return SupabaseGeminiDecisionEngine(client);
  }
  if (kDebugMode && Env.hasGeminiKey) {
    return GeminiDecisionEngine(
      apiKey: Env.geminiApiKey,
      model: Env.geminiModel,
    );
  }
  throw StateError('Güvenli AI servisi yapılandırılmadı.');
});

/// Supabase varsa Gemini güvenli Edge Function üzerinden çağrılır. Doğrudan
/// API anahtarı yalnızca debug geliştirmede kullanılabilir.
final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  final speech = ref.watch(speechServiceProvider);
  final offline = ref.watch(offlineFallbackServiceProvider);
  bool isMuted() => ref.read(crisisModeProvider).active;
  Future<bool> isOnline() => ref.read(connectivityServiceProvider).isOnline;

  final hasSecureAi = ref.watch(supabaseClientProvider) != null;
  final AssistantRepository repo =
      (hasSecureAi || (kDebugMode && Env.hasGeminiKey))
      ? GeminiAssistantRepository(
          engine: ref.watch(decisionEngineProvider),
          speech: speech,
          systemPrompt: () => ref.read(systemPromptProvider),
          isMuted: isMuted,
          isOnline: isOnline,
          offlineFallback: offline,
        )
      : MockAssistantRepository(
          speech: speech,
          isMuted: isMuted,
          isOnline: isOnline,
          offlineFallback: offline,
        );
  ref.onDispose(repo.dispose);
  return repo;
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final repo = Esp32DeviceRepository(
    prefs: ref.watch(sharedPreferencesProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final bleAudioOutputProvider = Provider<BleAudioOutput>(
  (ref) => LocalBleAudioOutput(ref.watch(speechServiceProvider)),
);

final backgroundMonitorServiceProvider = Provider<BackgroundMonitorService>(
  (ref) => BackgroundMonitorService(),
);

class HardwareMonitorState {
  const HardwareMonitorState({this.mode = MonitorMode.idle});

  final MonitorMode mode;

  bool get isRunning => mode != MonitorMode.idle;
}

class HardwareMonitorNotifier extends Notifier<HardwareMonitorState> {
  HardwareMonitor? _monitor;

  @override
  HardwareMonitorState build() {
    ref.onDispose(() {
      _monitor?.dispose();
    });
    return const HardwareMonitorState();
  }

  HardwareMonitor _ensureMonitor() {
    return _monitor ??= HardwareMonitor(
      assistant: ref.read(assistantRepositoryProvider),
      bleAudio: ref.read(bleAudioOutputProvider),
    );
  }

  Future<void> startMock() async {
    await _ensureMonitor().startMock();
    await ref
        .read(backgroundMonitorServiceProvider)
        .start(title: 'Luluna izliyor (mock)');
    state = const HardwareMonitorState(mode: MonitorMode.mock);
  }

  Future<void> startLive(String baseUrl) async {
    await _ensureMonitor().startLive(baseUrl);
    await ref.read(backgroundMonitorServiceProvider).start();
    state = const HardwareMonitorState(mode: MonitorMode.live);
  }

  Future<void> stop() async {
    await _monitor?.stop();
    await ref.read(backgroundMonitorServiceProvider).stop();
    state = const HardwareMonitorState();
  }
}

final hardwareMonitorProvider =
    NotifierProvider<HardwareMonitorNotifier, HardwareMonitorState>(
      HardwareMonitorNotifier.new,
    );

final promptBuilderProvider = Provider<PromptBuilder>(
  (ref) => const PromptBuilder(),
);

final deviceStatusProvider = StreamProvider<DeviceStatus>(
  (ref) => ref.watch(deviceRepositoryProvider).watchStatus(),
);

/// Asistan loglarını en yenisi başta olacak şekilde biriktirir.
final assistantLogsProvider = StreamProvider<List<AssistantLog>>((ref) {
  final logs = <AssistantLog>[];
  return ref.watch(assistantRepositoryProvider).watchLogs().map((log) {
    logs.insert(0, log);
    return List<AssistantLog>.unmodifiable(logs);
  });
});

/// Supabase geçmişi: veli kendi loglarını, terapist ise RLS sayesinde yalnızca
/// eşleştiği velinin loglarını görür.
final remoteAssistantLogsProvider =
    FutureProvider.autoDispose<List<AssistantLog>>((ref) async {
      final client = ref.watch(supabaseClientProvider);
      final auth = ref.watch(authStateProvider);
      final role = ref.watch(appStateProvider.select((state) => state.role));
      final pairing = ref.watch(pairingStateProvider);
      if (client == null || auth == null) return const [];
      if (role == UserRole.therapist && !pairing.hasTherapistLink) {
        return const [];
      }
      return ref.watch(remoteLogClientProvider).fetchRecent();
    });

/// Canlı ve uzak loglardan üretilen rapor istatistikleri.
final reportStatsProvider = Provider<ReportStats>((ref) {
  final local = ref.watch(assistantLogsProvider).value ?? const [];
  final remote = ref.watch(remoteAssistantLogsProvider).value ?? const [];
  return buildReportStats(mergeAssistantLogs(local, remote));
});

/// Her logu SQLite kuyruğuna yazar; praise → rozet köprüsü.
/// HomeShell tarafından watch edilir.
final logPersistenceBridgeProvider = Provider<void>((ref) {
  // SyncService'i ayakta tut.
  ref.watch(syncServiceProvider);

  ref.listen(assistantLogsProvider, (previous, next) {
    final logs = next.asData?.value;
    if (logs == null || logs.isEmpty) return;
    final newest = logs.first;

    final prev = previous?.asData?.value;
    final alreadySeen =
        prev != null &&
        prev.isNotEmpty &&
        prev.first.timestamp == newest.timestamp &&
        prev.first.message == newest.message;
    if (alreadySeen) return;

    ref.read(syncServiceProvider).enqueue(newest);

    if (newest.type == LogType.praise) {
      ref.read(badgesProvider.notifier).awardFromPraise(newest.message);
    }
  });
});

/// Geriye dönük alias — praiseBadgeBridge eski adı.
final praiseBadgeBridgeProvider = logPersistenceBridgeProvider;

class AuthStateNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => ref.watch(authRepositoryProvider).loadSession();

  Future<void> registerEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .registerEmail(
          email: email,
          password: password,
          displayName: displayName,
        );
    // Kayıt oturum açmaz.
    state = null;
  }

  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    state = await ref
        .read(authRepositoryProvider)
        .signInEmail(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    state = await ref.read(authRepositoryProvider).signInWithGoogle();
  }

  Future<void> updateKvkk(KvkkConsent kvkk) async {
    await ref.read(authRepositoryProvider).updateKvkk(kvkk);
    state = ref.read(authRepositoryProvider).loadSession();
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = null;
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthSession?>(
  AuthStateNotifier.new,
);

class PairingState {
  const PairingState({
    this.myInviteCode,
    this.linkedCode,
    this.linkedChildName,
  });

  final String? myInviteCode;
  final String? linkedCode;
  final String? linkedChildName;

  bool get hasTherapistLink => linkedCode != null;
}

class PairingStateNotifier extends Notifier<PairingState> {
  @override
  PairingState build() {
    final repo = ref.watch(pairingRepositoryProvider);
    final linked = repo.loadLinkedLink();
    return PairingState(
      myInviteCode: repo.loadMyInviteCode(),
      linkedCode: repo.loadLinkedCode(),
      linkedChildName: linked?.childName,
    );
  }

  Future<PairingLink> createInvite({
    required ChildProfile profile,
    String? parentEmail,
  }) async {
    final link = await ref
        .read(pairingRepositoryProvider)
        .createOrRefreshInvite(profile: profile, parentEmail: parentEmail);
    state = PairingState(
      myInviteCode: link.code,
      linkedCode: state.linkedCode,
      linkedChildName: state.linkedChildName,
    );
    return link;
  }

  Future<PairingLink> joinAsTherapist(String code) async {
    final link = await ref.read(pairingRepositoryProvider).joinWithCode(code);
    final profile = ChildProfile.fromJson(link.profileJson);
    await ref.read(appStateProvider.notifier).saveProfile(profile);
    state = PairingState(
      myInviteCode: state.myInviteCode,
      linkedCode: link.code,
      linkedChildName: link.childName,
    );
    return link;
  }

  Future<void> clearTherapistLink() async {
    await ref.read(pairingRepositoryProvider).clearTherapistLink();
    state = PairingState(myInviteCode: state.myInviteCode);
  }
}

final pairingStateProvider =
    NotifierProvider<PairingStateNotifier, PairingState>(
      PairingStateNotifier.new,
    );

class ParentVoicePathNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(parentVoiceRepositoryProvider).loadPath();

  Future<void> save(String path) async {
    await ref.read(parentVoiceRepositoryProvider).savePath(path);
    state = path;
  }

  Future<void> clear() async {
    await ref.read(parentVoiceRepositoryProvider).clear();
    state = null;
  }
}

final parentVoicePathProvider =
    NotifierProvider<ParentVoicePathNotifier, String?>(
      ParentVoicePathNotifier.new,
    );

class AppState {
  const AppState({
    this.role,
    this.profile,
    this.therapistRules = const TherapistRules(),
  });

  final UserRole? role;
  final ChildProfile? profile;
  final TherapistRules therapistRules;

  bool get onboardingComplete => role != null && profile != null;
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final repo = ref.watch(profileRepositoryProvider);
    return AppState(
      role: repo.loadRole(),
      profile: repo.loadProfile(),
      therapistRules: repo.loadTherapistRules(),
    );
  }

  Future<void> selectRole(UserRole role) async {
    await ref.read(profileRepositoryProvider).saveRole(role);
    // Supabase varsa rolü profiles tablosuna da yaz (best-effort).
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        await client.from('profiles').upsert({'id': userId, 'role': role.name});
      } catch (_) {
        // Çevrimdışıysa yerel rol yeterli; sonraki girişte tazelenir.
      }
    }
    state = AppState(
      role: role,
      profile: state.profile,
      therapistRules: state.therapistRules,
    );
  }

  /// Eşleşme / profil tamamlanmadan rol seçimine dönüş için.
  Future<void> clearRole() async {
    await ref.read(profileRepositoryProvider).clearRole();
    state = AppState(
      profile: state.profile,
      therapistRules: state.therapistRules,
    );
  }

  Future<void> saveProfile(ChildProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    await ref.read(pairingRepositoryProvider).syncInviteProfile(profile);
    state = AppState(
      role: state.role,
      profile: profile,
      therapistRules: state.therapistRules,
    );
  }

  Future<void> saveTherapistRules(TherapistRules rules) async {
    if (state.role != UserRole.therapist) {
      throw StateError('Kuralları yalnızca terapist güncelleyebilir.');
    }
    final parentId = _rulesParentId();
    if (ref.read(supabaseClientProvider) != null && parentId == null) {
      throw StateError('Önce bir veli hesabıyla eşleşin.');
    }
    if (parentId != null) {
      await ref
          .read(therapistRulesCloudRepositoryProvider)
          .save(parentId, rules);
    }
    await ref.read(profileRepositoryProvider).saveTherapistRules(rules);
    state = AppState(
      role: state.role,
      profile: state.profile,
      therapistRules: rules,
    );
  }

  Future<void> refreshTherapistRules() async {
    final parentId = _rulesParentId();
    if (parentId == null || ref.read(supabaseClientProvider) == null) return;
    final remote = await ref
        .read(therapistRulesCloudRepositoryProvider)
        .load(parentId);
    if (remote == null) return;
    await ref.read(profileRepositoryProvider).saveTherapistRules(remote);
    state = AppState(
      role: state.role,
      profile: state.profile,
      therapistRules: remote,
    );
  }

  String? _rulesParentId() {
    if (state.role == UserRole.parent) {
      return ref.read(authStateProvider)?.userId;
    }
    if (state.role == UserRole.therapist) {
      return ref.read(pairingRepositoryProvider).loadLinkedLink()?.parentId;
    }
    return null;
  }

  Future<void> reset() async {
    await ref.read(hardwareMonitorProvider.notifier).stop();
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(badgeRepositoryProvider).clear();
    await ref.read(logQueueRepositoryProvider).clear();
    await ref.read(pairingRepositoryProvider).clearAll();
    await ref.read(parentVoiceRepositoryProvider).clear();
    await ref.read(deviceRepositoryProvider).saveEsp32BaseUrl(null);
    ref.read(badgesProvider.notifier).reload();
    ref.invalidate(parentVoicePathProvider);
    ref.invalidate(pairingStateProvider);
    state = const AppState();
  }

  /// KVKK veri taşınabilirliği: yerel profil, kurallar ve bulut log özeti.
  Future<Map<String, dynamic>> exportPersonalData() async {
    final auth = ref.read(authStateProvider);
    final app = state;
    final pairing = ref.read(pairingStateProvider);
    final remoteLogs = await ref
        .read(remoteLogClientProvider)
        .fetchRecent(limit: 200);
    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'account': {
        'userId': auth?.userId,
        'email': auth?.email,
        'displayName': auth?.displayName,
        'provider': auth?.provider.name,
        'kvkk': auth?.kvkk.toMap(),
      },
      'role': app.role?.name,
      'profile': app.profile?.toMap(),
      'therapistRules': app.therapistRules.toMap(),
      'pairing': {
        'myInviteCode': pairing.myInviteCode,
        'linkedCode': pairing.linkedCode,
        'linkedChildName': pairing.linkedChildName,
      },
      'assistantLogs': [
        for (final log in remoteLogs)
          {
            'timestamp': log.timestamp.toUtc().toIso8601String(),
            'type': log.type.name,
            'message': log.message,
          },
      ],
    };
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

/// Gemini'ye gidecek güncel system prompt. Profil veya terapist kuralları
/// değişince otomatik yeniden üretilir.
final systemPromptProvider = Provider<String?>((ref) {
  final profile = ref.watch(appStateProvider).profile;
  if (profile == null) return null;
  final rules = ref.watch(appStateProvider).therapistRules;
  return ref
      .watch(promptBuilderProvider)
      .build(profile: profile, therapistRules: rules);
});

class CrisisModeNotifier extends Notifier<CrisisState> {
  @override
  CrisisState build() => const CrisisState();

  Future<void> activate() async {
    await ref.read(speechServiceProvider).stop();
    state = const CrisisState(active: true);
  }

  Future<void> playSource(CrisisAudioSource source) async {
    if (!state.active) return;
    await ref.read(crisisAudioServiceProvider).play(source);
    state = state.copyWith(playing: source);
  }

  Future<void> deactivate() async {
    await ref.read(crisisAudioServiceProvider).stop();
    state = const CrisisState();
  }
}

final crisisModeProvider = NotifierProvider<CrisisModeNotifier, CrisisState>(
  CrisisModeNotifier.new,
);

class BadgesNotifier extends Notifier<List<AchievementBadge>> {
  @override
  List<AchievementBadge> build() => ref.watch(badgeRepositoryProvider).load();

  void reload() {
    state = ref.read(badgeRepositoryProvider).load();
  }

  Future<void> awardFromPraise(String message) async {
    final title = _titleFromPraise(message);
    // Aynı saniyede tekrarlayan mock praise spam'ini engelle.
    if (state.any(
      (b) =>
          b.title == title &&
          DateTime.now().difference(b.earnedAt) < const Duration(seconds: 30),
    )) {
      return;
    }

    final badge = AchievementBadge(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      earnedAt: DateTime.now(),
    );
    final next = [badge, ...state];
    await ref.read(badgeRepositoryProvider).save(next);
    state = next;
  }

  static String _titleFromPraise(String message) {
    if (message.toLowerCase().contains('sakin')) return 'Sakin Kahraman';
    if (message.toLowerCase().contains('harika')) return 'Harika An';
    return 'Başarı Rozeti';
  }
}

final badgesProvider = NotifierProvider<BadgesNotifier, List<AchievementBadge>>(
  BadgesNotifier.new,
);
