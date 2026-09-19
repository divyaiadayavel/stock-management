// lib/features/services/presentation/providers/services_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/domain/enums/service_category_type.dart';
import '../../../settings/service_management/data/models/service_model.dart';
import '../../data/datasources/services_remote_datasource.dart';
import '../../data/models/service_request_model.dart';
import '../../data/repositories/services_repository_impl.dart';
import '../../domain/repositories/services_repository.dart';
import '../../domain/usecases/get_service_categories.dart';
import '../../domain/usecases/get_service_details.dart';
import '../../domain/usecases/get_services_by_category.dart';
import '../../domain/usecases/submit_service_request.dart';

// ─── Dependency wiring ──────────────────────────────────────
final _servicesHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
);

final servicesRemoteSourceProvider = Provider<ServicesRemoteDataSource>((ref) {
  return ServicesRemoteDataSource(
    client: ref.watch(_servicesHttpClientProvider),
  );
});

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(ref.watch(servicesRemoteSourceProvider));
});

final _getServiceCategoriesProvider = Provider(
  (ref) => GetServiceCategories(ref.watch(servicesRepositoryProvider)),
);
final _getServicesByCategoryProvider = Provider(
  (ref) => GetServicesByCategory(ref.watch(servicesRepositoryProvider)),
);
final _getServiceDetailsProvider = Provider(
  (ref) => GetServiceDetails(ref.watch(servicesRepositoryProvider)),
);
final _submitServiceRequestProvider = Provider(
  (ref) => SubmitServiceRequest(ref.watch(servicesRepositoryProvider)),
);

// ─── Browse: categories -> services -> service detail (with questions) ──
final userServiceCategoriesProvider =
    FutureProvider<List<ServiceCategoryModel>>((ref) {
      return ref.read(_getServiceCategoriesProvider).call();
    });

/// Categories on the Service tab only — same split as the admin
/// Services & Categories screen.
final userServiceTypeCategoriesProvider =
    Provider<AsyncValue<List<ServiceCategoryModel>>>((ref) {
  return ref.watch(userServiceCategoriesProvider).whenData(
        (categories) => categories
            .where((c) => c.type == ServiceCategoryType.service)
            .toList(),
      );
});

/// Categories on the Provider tab only.
final userProviderTypeCategoriesProvider =
    Provider<AsyncValue<List<ServiceCategoryModel>>>((ref) {
  return ref.watch(userServiceCategoriesProvider).whenData(
        (categories) => categories
            .where((c) => c.type == ServiceCategoryType.provider)
            .toList(),
      );
});

final servicesForCategoryProvider =
    FutureProvider.family<List<ServiceModel>, int>((ref, categoryId) {
  if (categoryId <= 0) {
    throw Exception('Invalid service category.');
  }

  return ref.read(_getServicesByCategoryProvider).call(categoryId);
});

final userServiceDetailProvider =
    FutureProvider.autoDispose.family<ServiceModel, int>((ref, serviceId) {
      return ref.read(_getServiceDetailsProvider).call(serviceId);
    });

// ─── In-progress form answers, keyed by question id ──────────
class ServiceFormAnswersNotifier extends StateNotifier<Map<int, Object?>> {
  ServiceFormAnswersNotifier() : super({});

  void setAnswer(int questionId, Object? value) {
    state = {...state, questionId: value};
  }

  void reset() => state = {};
}

final serviceFormAnswersProvider =
    StateNotifierProvider<ServiceFormAnswersNotifier, Map<int, Object?>>(
      (ref) => ServiceFormAnswersNotifier(),
    );

// ─── Submit operation (Non-autoDispose to prevent premature disposal) ───
class ServiceSubmitNotifier
    extends StateNotifier<AsyncValue<ServiceRequestModel?>> {
  final Ref ref;
  ServiceSubmitNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<ServiceRequestModel?> submit(ServiceRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref
          .read(_submitServiceRequestProvider)
          .call(request);
      if (mounted) {
        state = AsyncValue.data(result);
      }
      return result;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      return null;
    }
  }
}

final serviceSubmitProvider =
    StateNotifierProvider<
      ServiceSubmitNotifier,
      AsyncValue<ServiceRequestModel?>
    >((ref) => ServiceSubmitNotifier(ref));
