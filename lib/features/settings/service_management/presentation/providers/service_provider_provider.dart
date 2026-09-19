// lib/features/settings/service_management/presentation/providers/service_provider_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/service_provider_remote_datasource.dart';
import '../../data/models/provider_question_model.dart';
import '../../data/models/service_provider_model.dart';
import '../../data/repositories/service_provider_repository_impl.dart';
import '../../domain/repositories/service_provider_repository.dart';
import '../../domain/usecases/create_provider.dart';
import '../../domain/usecases/delete_provider.dart';
import '../../domain/usecases/get_provider_detail.dart';
import '../../domain/usecases/get_providers.dart';
import '../../domain/usecases/reload_provider_balance.dart';
import '../../domain/usecases/update_provider.dart';

import 'service_management_provider.dart';

// ─────────────────────────────────────────────────────────────
// Dependency wiring
// ─────────────────────────────────────────────────────────────

final _providerHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
);

final serviceProviderRemoteSourceProvider =
    Provider<ServiceProviderRemoteDataSource>((ref) {
      return ServiceProviderRemoteDataSource(
        client: ref.watch(_providerHttpClientProvider),
      );
    });

final serviceProviderRepositoryProvider = Provider<ServiceProviderRepository>((
  ref,
) {
  return ServiceProviderRepositoryImpl(
    ref.watch(serviceProviderRemoteSourceProvider),
  );
});

// ─────────────────────────────────────────────────────────────
// Usecases
// ─────────────────────────────────────────────────────────────

final _getProvidersProvider = Provider(
  (ref) => GetProviders(ref.watch(serviceProviderRepositoryProvider)),
);

final _getProviderDetailProvider = Provider(
  (ref) => GetProviderDetail(ref.watch(serviceProviderRepositoryProvider)),
);

final _createProviderProvider = Provider(
  (ref) => CreateProvider(ref.watch(serviceProviderRepositoryProvider)),
);

final _updateProviderProvider = Provider(
  (ref) => UpdateProvider(ref.watch(serviceProviderRepositoryProvider)),
);

final _deleteProviderProvider = Provider(
  (ref) => DeleteProvider(ref.watch(serviceProviderRepositoryProvider)),
);

final _reloadProviderBalanceProvider = Provider(
  (ref) => ReloadProviderBalance(ref.watch(serviceProviderRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────
// Provider lists
// ─────────────────────────────────────────────────────────────

/// Every provider.
final allProvidersProvider = FutureProvider<List<ServiceProviderModel>>((
  ref,
) async {
  return ref.read(_getProvidersProvider).call();
});

/// Providers belonging to one category.
final providersByCategoryProvider =
    FutureProvider.family<List<ServiceProviderModel>, int?>((
      ref,
      categoryId,
    ) async {
      return ref.read(_getProvidersProvider).call(categoryId: categoryId);
    });

// ─────────────────────────────────────────────────────────────
// Provider detail
// ─────────────────────────────────────────────────────────────

final providerDetailProvider = FutureProvider.family<ServiceProviderModel, int>(
  (ref, id) async {
    return ref.read(_getProviderDetailProvider).call(id);
  },
);

// ─────────────────────────────────────────────────────────────
// Provider operations
// ─────────────────────────────────────────────────────────────

class ProviderOperations extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ProviderOperations(this.ref) : super(const AsyncValue.data(null));

  // ───────────────────────────────────────────────────────────
  // Refresh provider-related data
  // ───────────────────────────────────────────────────────────

  Future<void> _refreshAll([int? providerId]) async {
    ref.invalidate(allProvidersProvider);
    ref.invalidate(providersByCategoryProvider);

    // Category tiles display provider counts.
    await ref.read(serviceCategoriesProvider.notifier).load();

    if (providerId != null) {
      ref.invalidate(providerDetailProvider(providerId));
    }
  }

  // ───────────────────────────────────────────────────────────
  // Create provider
  // ───────────────────────────────────────────────────────────

  Future<ServiceProviderModel?> saveNewProvider(
    ServiceProviderModel provider,
  ) async {
    state = const AsyncValue.loading();

    try {
      final saved = await ref.read(_createProviderProvider).call(provider);

      await _refreshAll(saved.id);

      state = const AsyncValue.data(null);

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Update provider
  // ───────────────────────────────────────────────────────────

  Future<ServiceProviderModel?> saveExistingProvider(
    ServiceProviderModel provider,
  ) async {
    state = const AsyncValue.loading();

    try {
      final saved = await ref.read(_updateProviderProvider).call(provider);

      await _refreshAll(saved.id);

      state = const AsyncValue.data(null);

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Delete provider
  // ───────────────────────────────────────────────────────────

  Future<bool> removeProvider(int id) async {
    try {
      final ok = await ref.read(_deleteProviderProvider).call(id);

      if (!ok) {
        return false;
      }

      await _refreshAll(id);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Reload provider balance
  // ───────────────────────────────────────────────────────────

  Future<ServiceProviderModel?> reloadBalance(
    int id,
    double amount, {
    String? note,
  }) async {
    state = const AsyncValue.loading();

    try {
      final updated = await ref
          .read(_reloadProviderBalanceProvider)
          .call(id, amount, note: note);

      await _refreshAll(id);

      state = const AsyncValue.data(null);

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Provider operations provider
// ─────────────────────────────────────────────────────────────

final providerOperationsProvider =
    StateNotifierProvider<ProviderOperations, AsyncValue<void>>(
      (ref) => ProviderOperations(ref),
    );

// ─────────────────────────────────────────────────────────────
// Provider draft
// ─────────────────────────────────────────────────────────────

class ProviderDraftState {
  final String name;
  final int? categoryId;
  final String categoryName;
  final String description;
  final double initialLoadAmount;
  final List<ProviderQuestionModel> questions;

  const ProviderDraftState({
    this.name = '',
    this.categoryId,
    this.categoryName = '',
    this.description = '',
    this.initialLoadAmount = 0.0,
    this.questions = const [],
  });

  ProviderDraftState copyWith({
    String? name,
    int? categoryId,
    String? categoryName,
    String? description,
    double? initialLoadAmount,
    List<ProviderQuestionModel>? questions,
  }) {
    return ProviderDraftState(
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      initialLoadAmount: initialLoadAmount ?? this.initialLoadAmount,
      questions: questions ?? this.questions,
    );
  }
}
