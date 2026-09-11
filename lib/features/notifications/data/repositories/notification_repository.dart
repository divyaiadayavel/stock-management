import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepository implements INotificationRepository {
  final NotificationRemoteDatasource datasource;

  NotificationRepository(this.datasource);

  @override
  Future<List<AppNotification>> getNotifications(int userId) async {
    final rawList = await datasource.fetchUserNotifications(userId);
    return rawList.map((json) => AppNotification.fromJson(json)).toList();
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    return await datasource.markRead(notificationId: notificationId);
  }

  @override
  Future<bool> markAllAsRead(int userId) async {
    return await datasource.markRead(userId: userId);
  }

  @override
  Future<bool> triggerCheckLowStock(int userId) async {
    return await datasource.triggerCheckLowStock(userId);
  }

  @override
  Future<Map<String, dynamic>> sendTestNotification(int userId) async {
    return await datasource.sendTestPushNotification(userId);
  }
}