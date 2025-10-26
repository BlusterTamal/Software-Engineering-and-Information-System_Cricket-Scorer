// lib\features\cricket_scoring\services\notification_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'admin_service.dart';
import '../api/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {

    print('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return false;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cricket_notifications',
      'Cricket Notifications',
      channelDescription: 'Notifications for cricket scoring app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> showMatchNotification({
    required String matchId,
    required String teamA,
    required String teamB,
    required DateTime matchTime,
  }) async {
    final title = 'New Match Created!';
    final body = '$teamA vs $teamB at ${_formatTime(matchTime)}';

    await showNotification(
      id: matchId.hashCode,
      title: title,
      body: body,
      payload: 'match:$matchId',
    );
  }

  static Future<void> showMatchUpdateNotification({
    required String matchId,
    required String teamA,
    required String teamB,
    required String update,
  }) async {
    final title = 'Match Update';
    final body = '$teamA vs $teamB: $update';

    await showNotification(
      id: '${matchId}_update'.hashCode,
      title: title,
      body: body,
      payload: 'match_update:$matchId',
    );
  }

  static Future<void> showAdminNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

}

class AppNotificationManager {
  late final AdminService _adminService;
  Timer? _notificationTimer;
  String? _currentUserId;

  AppNotificationManager() {
    _adminService = AdminService(Client()
      ..setEndpoint(AppwriteConstants.endPoint)
      ..setProject(AppwriteConstants.projectId));
  }

  void startNotificationCheck(String userId) {
    _currentUserId = userId;
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewNotifications();
    });
  }

  void stopNotificationCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  Future<void> _checkForNewNotifications() async {
    if (_currentUserId == null) return;

    try {
      final notifications = await _adminService.getUserNotifications(_currentUserId!);
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {

        await NotificationService.showNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.message,
          payload: 'notification:${notification.id}',
        );

        await _adminService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    required String type,
    String? data,
  }) async {
    try {
      await _adminService.sendNotificationToAllUsers(title, message, type, data: data);
    } catch (e) {
      print('Error sending notification to all users: $e');
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? data,
  }) async {
    try {
      await _adminService.sendNotification(userId, title, message, type, data: data);
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }
}