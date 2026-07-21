import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/update_supplier.dart';
import '../../domain/usecases/upload_supplier_image.dart';
import 'supplier_provider.dart';

final createSupplierUseCaseProvider = Provider((ref) => CreateSupplier(ref.watch(supplierRepositoryProvider)));
final updateSupplierUseCaseProvider = Provider((ref) => UpdateSupplier(ref.watch(supplierRepositoryProvider)));
final uploadSupplierImageUseCaseProvider = Provider((ref) => UploadSupplierImage(ref.watch(supplierRepositoryProvider)));

final dbCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final remoteDS = ref.watch(supplierRemoteDatasourceProvider);
  return await remoteDS.fetchDatabaseCategories();
});

class AddSupplierState {
  final bool isSaving;
  final File? selectedImage;
  final String errorMessage;

  AddSupplierState({
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
      isSaving: isSaving ?? this.isSaving,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AddSupplierNotifier extends StateNotifier<AddSupplierState> {
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
        super(AddSupplierState(isSaving: false, errorMessage: ''));

  void setImage(File file) => state = state.copyWith(selectedImage: file);
  void clearImage() => state = state.copyWith(clearImage: true);

  Future<bool> saveSupplier(Supplier supplier) async {
    state = state.copyWith(isSaving: true, errorMessage: '');
    try {
      if (supplier.id == 0) {
        final newId = await _createSupplier(supplier);
        if (state.selectedImage != null) {
          await _uploadSupplierImage(newId, state.selectedImage!);
        }
      } else {
        await _updateSupplier(supplier);
        if (state.selectedImage != null) {
          await _uploadSupplierImage(supplier.id, state.selectedImage!);
        }
      }
      state = state.copyWith(isSaving: false, clearImage: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final addSupplierNotifierProvider = StateNotifierProvider<AddSupplierNotifier, AddSupplierState>((ref) {
  return AddSupplierNotifier(
    createSupplier: ref.watch(createSupplierUseCaseProvider),
    updateSupplier: ref.watch(updateSupplierUseCaseProvider),
    uploadSupplierImage: ref.watch(uploadSupplierImageUseCaseProvider),
  );
});