import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/update_supplier.dart';
import '../../domain/usecases/upload_supplier_image.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'supplier_provider.dart';

// ============================================================
// USE CASE PROVIDERS
// ============================================================

final createSupplierUseCaseProvider =
    Provider<CreateSupplier>((ref) {
  return CreateSupplier(
    ref.watch(supplierRepositoryProvider),
  );
});

final updateSupplierUseCaseProvider =
    Provider<UpdateSupplier>((ref) {
  return UpdateSupplier(
    ref.watch(supplierRepositoryProvider),
  );
});

final uploadSupplierImageUseCaseProvider =
    Provider<UploadSupplierImage>((ref) {
  return UploadSupplierImage(
    ref.watch(supplierRepositoryProvider),
  );
});

// ============================================================
// DATABASE CATEGORIES
//
// Returns BOTH:
// {
//   "id": 1,
//   "name": "Electronics"
// }
//
// Do not return only the category name.
// The ID is required when saving the supplier-category
// relationship in suppliers.php.
// ============================================================

final dbCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final settingsRepo =
      ref.watch(settingsRepositoryProvider);

  final categories =
      await settingsRepo.getCategories();

  return categories
      .map(_normalizeSupplierCategory)
      .whereType<Map<String, dynamic>>()
      .toList();
});

Map<String, dynamic>? _normalizeSupplierCategory(
  Map<String, dynamic> category,
) {
  final id =
      int.tryParse(
        category['id']?.toString() ?? '',
      ) ??
      0;

  final name = (category['category_name'] ??
          category['name'] ??
          '')
      .toString()
      .trim();

  if (id <= 0 || name.isEmpty) {
    return null;
  }

  final status =
      category['status']?.toString().trim().toUpperCase();

  if (status != null &&
      status.isNotEmpty &&
      status != 'ACTIVE') {
    return null;
  }

  return {
    'id': id,
    'name': name,
  };
}

// ============================================================
// STATE
// ============================================================

class AddSupplierState {
  final bool isSaving;
  final File? selectedImage;
  final String errorMessage;

  const AddSupplierState({
    required this.isSaving,
    this.selectedImage,
    required this.errorMessage,
  });

  AddSupplierState copyWith({
    bool? isSaving,
    File? selectedImage,
    String? errorMessage,
    bool clearImage = false,
  }) {
    return AddSupplierState(
      isSaving:
          isSaving ?? this.isSaving,

      selectedImage:
          clearImage
              ? null
              : selectedImage ?? this.selectedImage,

      errorMessage:
          errorMessage ?? this.errorMessage,
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class AddSupplierNotifier
    extends StateNotifier<AddSupplierState> {
  final CreateSupplier _createSupplier;
  final UpdateSupplier _updateSupplier;
  final UploadSupplierImage _uploadSupplierImage;

  AddSupplierNotifier({
    required CreateSupplier createSupplier,
    required UpdateSupplier updateSupplier,
    required UploadSupplierImage uploadSupplierImage,
  })  : _createSupplier = createSupplier,
        _updateSupplier = updateSupplier,
        _uploadSupplierImage = uploadSupplierImage,
        super(
          const AddSupplierState(
            isSaving: false,
            errorMessage: '',
          ),
        );

  // ==========================================================
  // IMAGE
  // ==========================================================

  void setImage(File file) {
    state = state.copyWith(
      selectedImage: file,
      errorMessage: '',
    );
  }

  void clearImage() {
    state = state.copyWith(
      clearImage: true,
    );
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<bool> saveSupplier(
    Supplier supplier,
  ) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: '',
    );

    try {
      // ========================================================
      // CREATE
      // ========================================================

      if (supplier.id == 0) {
        final newId =
            await _createSupplier(
          supplier,
        );

        // Capture image BEFORE changing state.
        final image =
            state.selectedImage;

        // Supplier must be created first because the
        // image-upload API requires supplier_id.
        if (image != null) {
          await _uploadSupplierImage(
            newId,
            image,
          );
        }
      }

      // ========================================================
      // UPDATE
      // ========================================================

      else {
        await _updateSupplier(
          supplier,
        );

        final image =
            state.selectedImage;

        if (image != null) {
          await _uploadSupplierImage(
            supplier.id,
            image,
          );
        }
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      state = state.copyWith(
        isSaving: false,
        clearImage: true,
        errorMessage: '',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            _cleanErrorMessage(e),
      );

      return false;
    }
  }

  // ==========================================================
  // CLEAN ERROR
  // ==========================================================

  String _cleanErrorMessage(
    Object error,
  ) {
    var message =
        error.toString().trim();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(
        'Exception: '.length,
      );
    }

    if (message.isEmpty) {
      return 'Unable to save supplier. Please try again.';
    }

    if (
      message.contains(
        'SocketException',
      ) ||
      message.contains(
        'ClientException',
      ) ||
      message.contains(
        'FormatException',
      ) ||
      message.contains(
        'HandshakeException',
      )
    ) {
      return 'Unable to connect to the server. Please check your connection and try again.';
    }

    return message;
  }
}

// ============================================================
// PROVIDER
// ============================================================

final addSupplierNotifierProvider =
    StateNotifierProvider<
        AddSupplierNotifier,
        AddSupplierState>(
  (ref) {
    return AddSupplierNotifier(
      createSupplier:
          ref.watch(
        createSupplierUseCaseProvider,
      ),
      updateSupplier:
          ref.watch(
        updateSupplierUseCaseProvider,
      ),
      uploadSupplierImage:
          ref.watch(
        uploadSupplierImageUseCaseProvider,
      ),
    );
  },
);
