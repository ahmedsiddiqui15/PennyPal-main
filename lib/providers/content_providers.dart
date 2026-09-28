import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_enums.dart';
import '../models/ai_message_model.dart';
import '../models/app_notification_model.dart';
import '../models/learning_model.dart';
import '../models/support_model.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/repository.dart';
import 'auth_providers.dart';
import 'finance_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

class LearningController extends StateNotifier<AsyncValue<List<LearningModel>>> {
  LearningController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  AppRepository get _repo => _ref.read(repositoryProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final bool isAdmin = _ref.read(isAdminProvider);
      state = AsyncValue.data(
        await _repo.fetchLearning(includeUnpublished: isAdmin),
      );
    } catch (e, st) {
      state = AsyncValue.error(FirestoreService.describeError(e), st);
    }
  }

  Future<String?> save(LearningModel article) async {
    try {
      await _repo.saveLearning(article);
      await load();
      return null;
    } catch (e) {
      return 'Could not save the article.';
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repo.deleteLearning(id);
      await load();
      return null;
    } catch (e) {
      return 'Could not delete the article.';
    }
  }

  Future<String?> togglePublished(LearningModel article) =>
      save(article.copyWith(published: !article.published));
}

final learningProvider =
    StateNotifierProvider<LearningController, AsyncValue<List<LearningModel>>>(
  (ref) => LearningController(ref),
);

final learningCategoriesProvider = Provider<List<String>>((ref) {
  final List<LearningModel>? articles = ref.watch(learningProvider).valueOrNull;
  if (articles == null) return const [];
  final Set<String> categories = articles.map((a) => a.category).toSet();
  return categories.toList()..sort();
});

class SupportController extends StateNotifier<AsyncValue<List<SupportModel>>> {
  SupportController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  AppRepository get _repo => _ref.read(repositoryProvider);

  
  
  bool _mineOnly = true;

  bool get mineOnly => _mineOnly;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final String userId = _ref.read(currentUserIdProvider);
      state = AsyncValue.data(
        await _repo.fetchSupport(userId: _mineOnly ? userId : null),
      );
    } catch (e, st) {
      state = AsyncValue.error(FirestoreService.describeError(e), st);
    }
  }

  void setMineOnly(bool value) {
    if (_mineOnly == value) return;
    _mineOnly = value;
    load();
  }

  Future<String?> submit(SupportModel query) async {
    try {
      await _repo.submitSupport(query);
      await load();
      return null;
    } catch (e) {
      return 'Could not send your message. Please try again.';
    }
  }

  Future<String?> updateStatus(
    SupportModel query,
    SupportStatus status, {
    String? response,
  }) async {
    try {
      await _repo.updateSupport(
        query.copyWith(
          status: status,
          response: response,
          updatedAt: DateTime.now(),
        ),
      );
      await load();
      return null;
    } catch (e) {
      return 'Could not update the query.';
    }
  }
}

final supportProvider =
    StateNotifierProvider<SupportController, AsyncValue<List<SupportModel>>>(
  (ref) => SupportController(ref),
);

final openQueryCountProvider = Provider<int>((ref) {
  final List<SupportModel>? queries = ref.watch(supportProvider).valueOrNull;
  if (queries == null) return 0;
  return queries.where((q) => q.status != SupportStatus.resolved).length;
});

class NotificationsController
    extends StateNotifier<AsyncValue<List<AppNotificationModel>>> {
  NotificationsController(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<String>(
      currentUserIdProvider,
      (previous, next) {
        if (previous != next) load();
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  AppRepository get _repo => _ref.read(repositoryProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  Future<void> load() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.fetchNotifications(_userId));
    } catch (e, st) {
      state = AsyncValue.error(FirestoreService.describeError(e), st);
    }
  }

  Future<void> markRead(AppNotificationModel notification) async {
    if (notification.read) return;
    await _repo.markNotificationRead(_userId, notification.id, true);
    await load();
  }

  Future<void> markAllRead() async {
    await _repo.markAllNotificationsRead(_userId);
    await load();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsController,
    AsyncValue<List<AppNotificationModel>>>(
  (ref) => NotificationsController(ref),
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final List<AppNotificationModel>? items =
      ref.watch(notificationsProvider).valueOrNull;
  if (items == null) return 0;
  return items.where((n) => !n.read).length;
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._ref) : super([]) {
    _seed();
  }

  final Ref _ref;

  void _seed() {
    state = [
      ChatMessage(
        role: ChatRole.assistant,
        text: 'Hi! I am Penny 🪙 your personal finance coach.\n\n'
            'Ask me anything — where your money goes, how to save more, or what '
            'next month might cost.',
      ),
    ];
  }

  Future<void> send(String message) async {
    final String trimmed = message.trim();
    if (trimmed.isEmpty) return;

    state = [
      ...state,
      ChatMessage(role: ChatRole.user, text: trimmed),
      ChatMessage.typing(),
    ];

    final AiService ai = _ref.read(aiServiceProvider);
    final String symbol = _ref.read(currencySymbolProvider);
    final String apiKey = _ref.read(effectiveAiApiKeyProvider);
    final String model = _ref.read(effectiveAiModelProvider);

    
    final snapshot = _ref.read(snapshotProvider);

    final String reply = await ai.ask(
      trimmed,
      snapshot,
      symbol: symbol,
      geminiApiKey: apiKey,
      model: model,
    );

    
    final List<ChatMessage> next = [...state];
    if (next.isNotEmpty && next.last.isTyping) {
      next.removeLast();
    }
    next.add(ChatMessage(role: ChatRole.assistant, text: reply));
    state = next;
  }

  void clear() => _seed();

  void reset() => _seed();
}

final chatProvider = StateNotifierProvider<ChatController, List<ChatMessage>>(
  (ref) => ChatController(ref),
);
