import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../models/app_notification_model.dart';
import '../models/financial_snapshot.dart';

class NotificationService {
  NotificationService();

  final StreamController<RemoteMessage> _foreground =
      StreamController<RemoteMessage>.broadcast();

  bool _initialised = false;
  String? _token;

  
  Stream<RemoteMessage> get foregroundMessages => _foreground.stream;

  String? get token => _token;

  Future<void> initialize() async {
    if (_initialised || !AppConfig.firebaseReady) return;
    _initialised = true;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await messaging.getToken();

      FirebaseMessaging.onMessage.listen(_foreground.add);
      FirebaseMessaging.onMessageOpenedApp.listen((_) {});
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.initialize failed: $e');
    }
  }

  
  Future<void> subscribe(String topic) async {
    if (!AppConfig.firebaseReady) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.subscribe failed: $e');
    }
  }

  Future<void> unsubscribe(String topic) async {
    if (!AppConfig.firebaseReady) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.unsubscribe failed: $e');
    }
  }

  
  
  List<AppNotificationModel> buildSmartNotifications(
    String userId,
    FinancialSnapshot snapshot, {
    String symbol = 'Rs.',
  }) {
    final List<AppNotificationModel> out = [];
    final DateTime now = DateTime.now();

    
    for (final entry in snapshot.budgets) {
      if (!entry.isMaster && entry.limit > 0) {
        final double spent = snapshot.monthByCategory[entry.category] ?? 0;
        final double ratio = spent / entry.limit;
        if (ratio >= 0.8) {
          out.add(AppNotificationModel(
            id: 'notif-budget-${entry.id}',
            userId: userId,
            title: ratio >= 1
                ? '${entry.categoryLabel} budget exceeded'
                : '${entry.categoryLabel} budget at ${(ratio * 100).round()}%',
            body: ratio >= 1
                ? 'You have spent $symbol${spent.round()} of '
                    '$symbol${entry.limit.round()} on ${entry.categoryLabel}.'
                : 'Careful — ${entry.categoryLabel} is nearly used up.',
            type: AppNotificationType.budget,
            createdAt: now,
          ));
        }
      }
    }

    
    final double remainingToSave =
        (snapshot.totalGoalTarget - snapshot.totalSaved).clamp(0, double.infinity);
    if (remainingToSave > 0) {
      out.add(AppNotificationModel(
        id: 'notif-saving-${now.year}${now.month}${now.day}',
        userId: userId,
        title: 'Saving reminder',
        body: 'You are $symbol${remainingToSave.round()} away from your goals. '
            'A small top-up today keeps you on track.',
        type: AppNotificationType.saving,
        createdAt: now,
      ));
    }

    
    const List<String> tips = [
      'Pay yourself first — save before you spend.',
      'Use the 24-hour rule before any non-essential purchase.',
      'Track every rupee for a week; awareness alone cuts spending.',
      'Cancel one subscription you have not used in 30 days.',
      'Set a daily spend cap and check it every evening.',
    ];
    out.add(AppNotificationModel(
      id: 'notif-tip-${now.year}${now.month}${now.day}',
      userId: userId,
      title: 'Financial tip',
      body: tips[now.day % tips.length],
      type: AppNotificationType.tip,
      createdAt: now,
    ));

    return out;
  }

  void dispose() {
    _foreground.close();
  }
}
