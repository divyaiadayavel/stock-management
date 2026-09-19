// lib/features/settings/service_management/presentation/providers/service_management_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/service_management_remote_datasource.dart';
import '../../data/models/service_category_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/service_question_model.dart';
import '../../data/repositories/service_management_repository_impl.dart';
import '../../domain/enums/service_category_type.dart';
import '../../domain/repositories/service_management_repository.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/create_service.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/delete_service.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_service_details.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/update_service.dart';

// ─────────────────────────────────────────────────────────────
// Dependency wiring
// ─────────────────────────────────────────────────────────────

final _serviceManagementHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
);

final serviceManagementRemoteSourceProvider =
    Provider<ServiceManagementRemoteDataSource>((ref) {
      return ServiceManagementRemoteDataSource(
        client: ref.watch(_serviceManagementHttpClientProvider),
      );
    });

final serviceManagementRepositoryProvider =
    Provider<ServiceManagementRepository>((ref) {
      return ServiceManagementRepositoryImpl(
        ref.watch(serviceManagementRemoteSourceProvider),
      );
    });

// ─────────────────────────────────────────────────────────────
// Usecases
// ─────────────────────────────────────────────────────────────

final _getCategoriesProvider = Provider(
  (ref) => GetCategories(ref.watch(serviceManagementRepositoryProvider)),
);

final _createCategoryProvider = Provider(
  (ref) => CreateCategory(ref.watch(serviceManagementRepositoryProvider)),
);

final _deleteCategoryProvider = Provider(
  (ref) => DeleteCategory(ref.watch(serviceManagementRepositoryProvider)),
);

final _getServicesProvider = Provider(
  (ref) => GetServices(ref.watch(serviceManagementRepositoryProvider)),
);

final _getServiceDetailsProvider = Provider(
  (ref) => GetServiceDetails(ref.watch(serviceManagementRepositoryProvider)),
);

final _createServiceProvider = Provider(
  (ref) => CreateService(ref.watch(serviceManagementRepositoryProvider)),
);

final _updateServiceProvider = Provider(
  (ref) => UpdateService(ref.watch(serviceManagementRepositoryProvider)),
);

final _deleteServiceProvider = Provider(
  (ref) => DeleteService(ref.watch(serviceManagementRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────

class ServiceCategoriesNotifier
    extends StateNotifier<AsyncValue<List<ServiceCategoryModel>>> {
  final Ref ref;

  ServiceCategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  // ───────────────────────────────────────────────────────────
  // Load categories
  // ───────────────────────────────────────────────────────────

  Future<void> load() async {
    state = const AsyncValue.loading();

    try {
      final categories = await ref.read(_getCategoriesProvider).call();

      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ───────────────────────────────────────────────────────────
  // Add category
  // ───────────────────────────────────────────────────────────

  Future<bool> addCategory(
    String name, {
    ServiceCategoryType type = ServiceCategoryType.service,
    String? description,
  }) async {
    try {
      final id = await ref
          .read(_createCategoryProvider)
          .call(name, type: type, description: description);

      if (id <= 0) {
        return false;
      }

      await load();

      return true;
    } catch (e, st) {
      debugPrint('Add category failed: $e\n$st');

      return false;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Delete category
  // ───────────────────────────────────────────────────────────

  Future<bool> removeCategory(int id) async {
    try {
      debugPrint('Removing category ID: $id');

      final ok = await ref.read(_deleteCategoryProvider).call(id);

      if (!ok) {
        return false;
      }

      // Refresh category list after successful deletion.
      await load();

      // Category deletion can affect service counts.
      ref.invalidate(allServicesProvider);

      ref.invalidate(servicesByCategoryProvider);

      debugPrint('Category $id removed successfully.');

      return true;
    } catch (e, st) {
      debugPrint('Remove category failed: $e\n$st');

      // IMPORTANT:
      // Re-throw instead of returning false.
      //
      // This allows the UI to display the actual server
      // message returned by categories.php.
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Main categories provider
// ─────────────────────────────────────────────────────────────

final serviceCategoriesProvider =
    StateNotifierProvider<
      ServiceCategoriesNotifier,
      AsyncValue<List<ServiceCategoryModel>>
    >((ref) => ServiceCategoriesNotifier(ref));

// ─────────────────────────────────────────────────────────────
// Service categories only
// ─────────────────────────────────────────────────────────────

final serviceTypeCategoriesProvider =
    Provider<AsyncValue<List<ServiceCategoryModel>>>((ref) {
      return ref
          .watch(serviceCategoriesProvider)
          .whenData(
            (categories) => categories
                .where((c) => c.type == ServiceCategoryType.service)
                .toList(),
          );
    });

// ─────────────────────────────────────────────────────────────
// Provider categories only
// ─────────────────────────────────────────────────────────────

final providerTypeCategoriesProvider =
    Provider<AsyncValue<List<ServiceCategoryModel>>>((ref) {
      return ref
          .watch(serviceCategoriesProvider)
          .whenData(
            (categories) => categories
                .where((c) => c.type == ServiceCategoryType.provider)
                .toList(),
          );
    });

// ─────────────────────────────────────────────────────────────
// Services by category
// ─────────────────────────────────────────────────────────────

final servicesByCategoryProvider =
    FutureProvider.family<List<ServiceModel>, int?>((ref, categoryId) async {
      return ref.read(_getServicesProvider).call(categoryId: categoryId);
    });

// ─────────────────────────────────────────────────────────────
// All services
// ─────────────────────────────────────────────────────────────

final allServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.read(_getServicesProvider).call();
});

// ─────────────────────────────────────────────────────────────
// Service detail
// ─────────────────────────────────────────────────────────────

final serviceDetailProvider = FutureProvider.family<ServiceModel, int>((
  ref,
  id,
) async {
  return ref.read(_getServiceDetailsProvider).call(id);
});

// ─────────────────────────────────────────────────────────────
// Service operations
// ─────────────────────────────────────────────────────────────

class ServiceOperations extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ServiceOperations(this.ref) : super(const AsyncValue.data(null));

  // ───────────────────────────────────────────────────────────
  // Create service
  // ───────────────────────────────────────────────────────────

  Future<int?> saveNewService(ServiceModel service) async {
    state = const AsyncValue.loading();

    try {
      final id = await ref.read(_createServiceProvider).call(service);

      if (id <= 0) {
        throw Exception('Unable to save service.');
      }

      ref.invalidate(allServicesProvider);

      ref.invalidate(servicesByCategoryProvider);

      await ref.read(serviceCategoriesProvider.notifier).load();

      state = const AsyncValue.data(null);

      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return null;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Update service
  // ───────────────────────────────────────────────────────────

  Future<bool> saveExistingService(ServiceModel service) async {
    state = const AsyncValue.loading();

    try {
      final ok = await ref.read(_updateServiceProvider).call(service);

      if (!ok) {
        throw Exception('Unable to update service.');
      }

      ref.invalidate(allServicesProvider);

      ref.invalidate(servicesByCategoryProvider);

      if (service.id != null) {
        ref.invalidate(serviceDetailProvider(service.id!));
      }

      await ref.read(serviceCategoriesProvider.notifier).load();

      state = const AsyncValue.data(null);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return false;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Delete service
  // ───────────────────────────────────────────────────────────

  Future<bool> removeService(int id) async {
    try {
      final ok = await ref.read(_deleteServiceProvider).call(id);

      if (!ok) {
        return false;
      }

      ref.invalidate(allServicesProvider);

      ref.invalidate(servicesByCategoryProvider);

      await ref.read(serviceCategoriesProvider.notifier).load();

      return true;
    } catch (e, st) {
      debugPrint('Remove service failed: $e\n$st');

      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Service operations provider
// ─────────────────────────────────────────────────────────────

final serviceOperationsProvider =
    StateNotifierProvider<ServiceOperations, AsyncValue<void>>(
      (ref) => ServiceOperations(ref),
    );

// ─────────────────────────────────────────────────────────────
// Service draft state
// ─────────────────────────────────────────────────────────────

class ServiceDraftState {
  final String name;
  final int? categoryId;
  final String categoryName;
  final List<ServiceQuestionModel> questions;

  /// Admin controls whether the user must enter
  /// a service charge.
  final bool chargeEnabled;

  const ServiceDraftState({
    this.name = '',
    this.categoryId,
    this.categoryName = '',
    this.questions = const [],
    this.chargeEnabled = true,
  });

  ServiceDraftState copyWith({
    String? name,
    int? categoryId,
    String? categoryName,
    List<ServiceQuestionModel>? questions,
    bool? chargeEnabled,
  }) {
    return ServiceDraftState(
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      questions: questions ?? this.questions,
      chargeEnabled: chargeEnabled ?? this.chargeEnabled,
    );
  }
}
