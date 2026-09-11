import '../models/app_notification.dart';

abstract class INotificationRepository {
  Future<List<AppNotification>> getNotifications(int userId);
  Future<bool> markAsRead(String notificationId);
  Future<bool> markAllAsRead(int userId);
  Future<bool> triggerCheckLowStock(int userId);
  Future<Map<String, dynamic>> sendTestNotification(int userId);
}