import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

final notificationDatasourceProvider = Provider((ref) {
  return NotificationRemoteDatasource();
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationDatasourceProvider));
});

final notificationProvider = StateNotifierProvider<NotificationController,
    AsyncValue<List<AppNotification>>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationController(repo);
});

class NotificationController
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final INotificationRepository repository;

  NotificationController(this.repository) : super(const AsyncValue.loading());

  Future<void> fetchNotifications(int userId) async {
    state = const AsyncValue.loading();
    try {
      final list = await repository.getNotifications(userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    await repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(int userId) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.map((n) => n.copyWith(isRead: true)).toList(),
    );
    await repository.markAllAsRead(userId);
  }
}