// lib/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a new notification
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _client.from('notifications').insert(notification.toMap());
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Send task assignment notification
  Future<void> sendTaskAssignmentNotification({
    required int staffId,
    required String requestTitle,
    required int requestId,
    required String urgency,
  }) async {
    final notification = AppNotification(
      recipientId: staffId.toString(),
      senderId: 'admin',
      type: urgency == 'High' ? 'urgent' : 'task_assigned',
      title: 'New Task Assigned',
      message: urgency == 'High'
          ? '🔴 URGENT: You have been assigned a high-priority task: $requestTitle'
          : 'You have been assigned a new task: $requestTitle',
      relatedRequestId: requestId.toString(),
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send task status update notification
  Future<void> sendTaskUpdateNotification({
    required String recipientId,
    required String requestTitle,
    required String newStatus,
    required int requestId,
  }) async {
    final notification = AppNotification(
      recipientId: recipientId,
      senderId: 'system',
      type: 'task_update',
      title: 'Task Status Updated',
      message: 'Task "$requestTitle" has been updated to: $newStatus',
      relatedRequestId: requestId.toString(),
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Send message notification
  Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
  }) async {
    final notification = AppNotification(
      recipientId: recipientId,
      senderId: 'system',
      type: 'message',
      title: 'New Message from $senderName',
      message: messagePreview.length > 50
          ? '${messagePreview.substring(0, 50)}...'
          : messagePreview,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Get all notifications for a user
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('recipientid', userId)
          .order('createdat', ascending: false)
          .limit(50);

      return (data as List)
          .map((m) => AppNotification.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _client
          .from('notifications')
          .select()
          .eq('recipientid', userId)
          .eq('isread', 0);

      return (data as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'isread': 1})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'isread': 1})
          .eq('recipientid', userId);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all read notifications
  Future<void> clearReadNotifications(String userId) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('recipientid', userId)
          .eq('isread', 1);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
