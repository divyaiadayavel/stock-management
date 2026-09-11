import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'barcode_scanner_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_config.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../providers/add_product_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../../../../core/utils/validators.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  // ─── Controllers ───────────────────────────────────────────
  final nameController = TextEditingController();
  final lslController = TextEditingController();
  final sgstController = TextEditingController();
  final cgstController = TextEditingController();
  final hsnController = TextEditingController();
  final productcodeController = TextEditingController();
  final discountController = TextEditingController();
  final purchaseController = TextEditingController();
  final sellingController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final descriptionController = TextEditingController();
  final expiryController = TextEditingController();

  // ─── State ──────────────────────────────────────────────────
  int _currentStep = 0;
  final List<String> _stepLabels = [
    "Basic info",
    "Stock & supplier",
    "Pricing",
  ];

  double? _originalPurchasePrice;
  double? _originalSellingPrice;
  int _originalQuantity = 0;
  bool _isSaving = false;
  bool _isInitializing = true;

  // ─── Dirty tracking ────────────────────────────────────────
  bool _hasChanges = false;
  bool _barcodeDuplicate = false;
  bool _imageRemoved = false;

  // ─── Duplicate Barcode Check ────────────────────────────────
  bool _checkDuplicateBarcode(String barcode) {
    if (barcode.trim().isEmpty) return false;

    final allProducts = ref.read(productListProvider).items;

    for (var p in allProducts) {
      if (p.barcode.trim() == barcode.trim()) {
        if (widget.product != null && widget.product!.id == p.id) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  // ─── FIX: Expiry Date Format Helpers ───────────────────────
  String _serverDateToDisplay(String serverDate) {
    final trimmed = serverDate.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split('-');
    if (parts.length != 3) return trimmed;

    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    return '$day/$month/$year';
  }

  String _displayDateToServer(String displayDate) {
    final trimmed = displayDate.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split('/');
    if (parts.length != 3) return trimmed;

    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  @override
  void initState() {
    super.initState();

    // NOTE: We intentionally do NOT invalidate productListProvider here.
    // Invalidating it reset the shared product list to empty as soon as
    // this screen opened, and nothing re-triggered loadProducts() on the
    // fresh provider instance. That meant ProductScreen showed an empty
    // list whenever you returned from here without result == true (e.g.
    // scanning a barcode, removing the image, or just going back).
    // The duplicate-barcode check below reads the already-loaded product
    // list via ref.read(productListProvider), which is enough — it
    // doesn't need a forced refetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(categoriesProvider);
      ref.invalidate(unitsProvider);
    });

    _addListeners();

    purchaseController.addListener(calculateProfit);
    sellingController.addListener(calculateProfit);

    if (widget.product != null) {
      nameController.text = widget.product!.name;
      productcodeController.text = widget.product!.barcode;
      expiryController.text = _serverDateToDisplay(widget.product!.expiryDate);
      purchaseController.text = widget.product!.purchasePrice > 0
          ? widget.product!.purchasePrice.toStringAsFixed(0)
          : "";
      sellingController.text = widget.product!.sellingPrice > 0
          ? widget.product!.sellingPrice.toStringAsFixed(0)
          : "";
      quantityController.text = widget.product!.quantity.toString();
      descriptionController.text = widget.product!.description;
      hsnController.text = widget.product!.hsnCode;
      unitController.text = widget.product!.unit;
      lslController.text = widget.product!.lsl.toString();

      _originalPurchasePrice = widget.product!.purchasePrice;
      _originalSellingPrice = widget.product!.sellingPrice;
      _originalQuantity = widget.product!.quantity;

      sgstController.text = widget.product!.sgst > 0
          ? widget.product!.sgst.toStringAsFixed(0)
          : "";
      cgstController.text = widget.product!.cgst > 0
          ? widget.product!.cgst.toStringAsFixed(0)
          : "";
      discountController.text = widget.product!.discount > 0
          ? widget.product!.discount.toStringAsFixed(0)
          : "";

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryIdProvider.notifier).state =
            widget.product!.categoryId;
        ref.read(selectedUnitIdProvider.notifier).state =
            widget.product!.unitId;
        ref.read(selectedCategoryProvider.notifier).state =
            widget.product!.category;
        ref
            .read(selectedSupplierProvider.notifier)
            .state = widget.product!.supplier.isNotEmpty
            ? widget.product!.supplier
            : null;
        ref.read(selectedSupplierIdProvider.notifier).state =
            widget.product!.supplierId;
        ref.read(showGstProvider.notifier).state =
            hsnController.text.isNotEmpty;

        calculateProfit();

        if (widget.product!.imagePath.isNotEmpty) {
          final localFile = File(widget.product!.imagePath);
          if (localFile.existsSync()) {
            ref.read(imageProvider.notifier).state = localFile;
          }
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(imageProvider.notifier).state = null;
        ref.read(selectedCategoryProvider.notifier).state = "General";
        ref.read(selectedCategoryIdProvider.notifier).state = null;
        ref.read(selectedUnitIdProvider.notifier).state = null;
        ref.read(selectedSupplierProvider.notifier).state = null;
        ref.read(selectedSupplierIdProvider.notifier).state = null;
        ref.read(showGstProvider.notifier).state = false;
        ref.read(profitMarginProvider.notifier).state = 0;
      });
    }
    _isInitializing = false;
  }

  void _addListeners() {
    final controllers = [
      nameController,
      lslController,
      sgstController,
      cgstController,
      hsnController,
      productcodeController,
      discountController,
      purchaseController,
      sellingController,
      quantityController,
      unitController,
      descriptionController,
      expiryController,
    ];

    for (var c in controllers) {
      c.addListener(() {
        if (!_isInitializing) {
          _hasChanges = true;
        }
      });
    }
  }

  @override
  void dispose() {
    purchaseController.removeListener(calculateProfit);
    sellingController.removeListener(calculateProfit);

    nameController.dispose();
    lslController.dispose();
    sgstController.dispose();
    cgstController.dispose();
    hsnController.dispose();
    productcodeController.dispose();
    discountController.dispose();
    purchaseController.dispose();
    sellingController.dispose();
    quantityController.dispose();
    unitController.dispose();
    descriptionController.dispose();
    expiryController.dispose();
    super.dispose();
  }

  // ─── Discard Dialog ────────────────────────────────────────
  Future<bool> _showDiscardDialog() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard changes?"),
        content: const Text(
          "You have unsaved changes. Are you sure you want to leave?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Editing"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Discard"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Navigation helpers ────────────────────────────────────
  void _goBack() async {
    if (_currentStep == 0) {
      final shouldPop = await _showDiscardDialog();
      if (shouldPop && mounted) Navigator.pop(context);
    } else {
      setState(() => _currentStep--);
    }
  }

  void _goNext() {
    if (_isSaving) return;

    // Validate the current step (Step 1) strictly
    final isValid = _validateCurrentStep();

    // If Step 1 contains a duplicate barcode or invalid field, block navigation
    if (!isValid) {
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  // ─── Validation ─────────────────────────────────────────────
  bool _validateCurrentStep() {
    // ============================================================
    // STEP 1 - BASIC INFORMATION
    // ============================================================
    if (_currentStep == 0) {
      // 1. Validate Image
      final image = ref.read(imageProvider);
      if (image == null &&
          (widget.product == null ||
              widget.product!.imagePath.trim().isEmpty)) {
        _showMissingFieldSnack("Product Image: Please select a product image.");
        return false;
      }

      // 2. Validate Name
      final nameError = Validators.validateProductName(
        nameController.text,
        fieldName: 'Product name',
      );
      if (nameError != null) {
        _showMissingFieldSnack(nameError);
        return false;
      }

      // 3. Validate Product Code Format
      final productCodeError = Validators.validateProductCode(
        productcodeController.text,
      );
      if (productCodeError != null) {
        _showMissingFieldSnack(productCodeError);
        return false;
      }

      // 4. Validate Category
      final normalizedBarcode = Validators.normalizeSubmittedValue(
        productcodeController.text,
      );

      if (_checkDuplicateBarcode(normalizedBarcode)) {
        setState(() {
          _barcodeDuplicate = true;
        });

        _showMissingFieldSnack(
          "Product Code: Product with this barcode already exists.",
        );

        return false;
      }

      setState(() {
        _barcodeDuplicate = false;
      });

      return true;
    }

    // ============================================================
    // STEP 2 - STOCK & SUPPLIER
    // ============================================================
    if (_currentStep == 1) {
      final quantityError = Validators.validateRequiredInteger(
        quantityController.text,
        fieldName: 'Quantity',
        min: 0,
      );

      if (quantityError != null) {
        _showMissingFieldSnack(quantityError);
        return false;
      }

      final lslError = Validators.validateRequiredInteger(
        lslController.text,
        fieldName: 'Low Stock Limit',
        min: 0,
      );

      if (lslError != null) {
        _showMissingFieldSnack(lslError);
        return false;
      }

      final unitId = ref.read(selectedUnitIdProvider);

      if (unitId == null || unitId <= 0) {
        _showMissingFieldSnack("Unit: Please select a unit.");
        return false;
      }

      final descriptionError = Validators.validateMaxLength(
        descriptionController.text,
        max: 1000,
        fieldName: 'Description',
      );

      if (descriptionError != null) {
        _showMissingFieldSnack(descriptionError);
        return false;
      }

      final expiryError = Validators.validateFutureDate(
        expiryController.text,
        fieldName: 'Expiry date',
      );

      if (expiryError != null) {
        _showMissingFieldSnack(expiryError);
        return false;
      }

      final showGstFields = ref.read(showGstProvider);

      if (showGstFields) {
        final hsnError = Validators.validateHsn(hsnController.text);

        if (hsnError != null) {
          _showMissingFieldSnack(hsnError);
          return false;
        }

        final sgstError = Validators.validatePercentage(
          sgstController.text,
          fieldName: 'SGST',
        );

        if (sgstError != null) {
          _showMissingFieldSnack(sgstError);
          return false;
        }

        final cgstError = Validators.validatePercentage(
          cgstController.text,
          fieldName: 'CGST',
        );

        if (cgstError != null) {
          _showMissingFieldSnack(cgstError);
          return false;
        }

        final discountError = Validators.validatePercentage(
          discountController.text,
          fieldName: 'Discount',
        );

        if (discountError != null) {
          _showMissingFieldSnack(discountError);
          return false;
        }
      }

      return true;
    }

    // ============================================================
    // STEP 3 - PRICING
    // ============================================================
    if (_currentStep == 2) {
      final purchaseError = Validators.validateRequiredDecimal(
        purchaseController.text,
        fieldName: 'Purchase price',
        min: 0,
      );

      if (purchaseError != null) {
        _showMissingFieldSnack(purchaseError);
        return false;
      }

      final sellingError = Validators.validateRequiredDecimal(
        sellingController.text,
        fieldName: 'Selling price',
        min: 0,
      );

      if (sellingError != null) {
        _showMissingFieldSnack(sellingError);
        return false;
      }

      return true;
    }

    return false;
  }

  bool _validateAllFields() {
    final originalStep = _currentStep;

    _currentStep = 0;

    if (!_validateCurrentStep()) {
      if (mounted) {
        setState(() {});
      }
      return false;
    }

    _currentStep = 1;

    if (!_validateCurrentStep()) {
      if (mounted) {
        setState(() {});
      }
      return false;
    }

    _currentStep = 2;

    if (!_validateCurrentStep()) {
      if (mounted) {
        setState(() {});
      }
      return false;
    }

    _currentStep = originalStep;

    if (mounted) {
      setState(() {});
    }

    return true;
  }

  void _showMissingFieldSnack(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    String cleanMessage = message;
    if (message.contains("1062 Duplicate entry") ||
        message.contains("uk_product_barcode") ||
        message.contains("Duplicate entry")) {
      cleanMessage = "Product Code: Product with this barcode already exists.";
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cleanMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ─── CRUD Operations ──────────────────────────────────────
  void updateProduct() async {
    if (_isSaving) return;

    if (!_validateAllFields()) {
      return;
    }

    final normalizedBarcode = Validators.normalizeSubmittedValue(
      productcodeController.text,
    );

    if (_checkDuplicateBarcode(normalizedBarcode)) {
      setState(() => _currentStep = 0);
      _showMissingFieldSnack(
        "Product Code: Product with this barcode already exists.",
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      final validData = await _ensureValidIds();
      final category = validData.category;
      final unit = validData.unit;

      final categoryName = category['category_name'].toString();
      final unitName = unit['unit_name']?.toString() ?? 'piece';
      final selectedCategoryId = category['id'] as int;
      final selectedUnitId = unit['id'] as int;

      final showGstFields = ref.read(showGstProvider);
      final productName = Validators.normalizeName(nameController.text);
      final updatedStock = int.tryParse(quantityController.text) ?? 0;

      final updatedProductInstance = Product(
        id: widget.product!.id,
        name: productName,
        category: categoryName,
        categoryId: selectedCategoryId,
        hsnCode: showGstFields
            ? Validators.normalizeDigits(hsnController.text)
            : "",
        purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0.0,
        quantity: updatedStock,
        unit: unitName,
        unitId: selectedUnitId,
        description: Validators.normalizeSubmittedValue(
          descriptionController.text,
        ),
        imagePath:
            ref.read(imageProvider)?.path ??
            (_imageRemoved ? "" : widget.product!.imagePath),
        barcode: Validators.normalizeSubmittedValue(productcodeController.text),
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0.0 : 0.0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0.0 : 0.0,
        discount: double.tryParse(discountController.text) ?? 0.0,
        expiryDate: _displayDateToServer(expiryController.text),
        supplierId: ref.read(selectedSupplierIdProvider),
        supplier: ref.read(selectedSupplierProvider) ?? "",
        lsl: int.tryParse(lslController.text) ?? 10,
      );

      final success = await ref
          .read(productOperationsProvider.notifier)
          .modifyProduct(updatedProductInstance);

      if (success && mounted) {
        // Trigger Notification for Product Details Edit
        try {
          await http.post(
            Uri.parse(ApiConfig.triggerStockStatus),
            headers: ApiConfig.jsonHeaders,
            body: jsonEncode({
              "user_id": 1,
              "product_id": widget.product!.id,
              "action_type": "update",
              "change_qty": updatedStock,
            }),
          );
        } catch (e) {
          debugPrint("Update product notification trigger failed: $e");
        }

        Navigator.pop(context, true);
      } else if (mounted) {
        final operationError = ref.read(productOperationsProvider);

        final message = operationError.maybeWhen(
          error: (error, _) => error.toString().replaceFirst("Exception: ", ""),
          orElse: () => "Unable to update product.",
        );

        if (message.contains("Duplicate entry") ||
            message.contains("barcode")) {
          setState(() => _currentStep = 0);
        }
        _showMissingFieldSnack(message);
      }
    } catch (e) {
      debugPrint("MVP EDIT MUTATION FAILURE: $e");
      if (mounted) {
        _showMissingFieldSnack(e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void saveProduct() async {
    if (_isSaving) return;

    if (!_validateAllFields()) {
      return;
    }

    final normalizedBarcode = Validators.normalizeSubmittedValue(
      productcodeController.text,
    );

    if (_checkDuplicateBarcode(normalizedBarcode)) {
      setState(() => _currentStep = 0);
      _showMissingFieldSnack(
        "Product Code: Product with this barcode already exists.",
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final validData = await _ensureValidIds();
      final category = validData.category;
      final unit = validData.unit;

      final categoryName = category['category_name'].toString();
      final unitName = unit['unit_name']?.toString() ?? 'piece';
      final selectedCategoryId = category['id'] as int;
      final selectedUnitId = unit['id'] as int;

      final image = ref.read(imageProvider);
      final showGstFields = ref.read(showGstProvider);
      final productName = Validators.normalizeName(nameController.text);
      final initialStock = int.tryParse(quantityController.text) ?? 0;

      final newProductInstance = Product(
        name: productName,
        category: categoryName,
        categoryId: selectedCategoryId,
        hsnCode: showGstFields
            ? Validators.normalizeDigits(hsnController.text)
            : "",
        purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0.0,
        quantity: initialStock,
        unit: unitName,
        unitId: selectedUnitId,
        description: Validators.normalizeSubmittedValue(
          descriptionController.text,
        ),
        imagePath: image?.path ?? "",
        barcode: Validators.normalizeSubmittedValue(productcodeController.text),
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0.0 : 0.0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0.0 : 0.0,
        discount: double.tryParse(discountController.text) ?? 0.0,
        expiryDate: _displayDateToServer(expiryController.text),
        supplierId: ref.read(selectedSupplierIdProvider),
        supplier: ref.read(selectedSupplierProvider) ?? "",
        lsl: int.tryParse(lslController.text) ?? 10,
      );

      final success = await ref
          .read(productOperationsProvider.notifier)
          .addProduct(newProductInstance);

      if (success && mounted) {
        // Trigger Notification for New Product Creation
        try {
          await http.post(
            Uri.parse(ApiConfig.triggerStockStatus),
            headers: ApiConfig.jsonHeaders,
            body: jsonEncode({
              "user_id": 1,
              "product_id": newProductInstance.id ?? 1,
              "action_type": "add",
              "change_qty": initialStock,
            }),
          );
        } catch (e) {
          debugPrint("Add product notification trigger failed: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product Added successfully.")),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        final operationError = ref.read(productOperationsProvider);

        final message = operationError.maybeWhen(
          error: (error, _) => error.toString().replaceFirst("Exception: ", ""),
          orElse: () => "Unable to add product.",
        );

        if (message.contains("Duplicate entry") ||
            message.contains("barcode")) {
          setState(() => _currentStep = 0);
        }
        _showMissingFieldSnack(message);
      }
    } catch (e) {
      debugPrint("MVP WRITE TRANSACTION ERROR: $e");
      if (mounted) {
        _showMissingFieldSnack(e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<({Map<String, dynamic> category, Map<String, dynamic> unit})>
  _ensureValidIds() async {
    final categories = await ref.read(categoriesProvider.future);
    final units = await ref.read(unitsProvider.future);

    if (categories.isEmpty) {
      throw Exception("No active categories found.");
    }

    if (units.isEmpty) {
      throw Exception("No active units found.");
    }

    final categoryId = ref.read(selectedCategoryIdProvider);

    if (categoryId == null || categoryId <= 0) {
      throw Exception("Category: Please select a category.");
    }

    Map<String, dynamic>? selectedCategory;

    for (final category in categories) {
      final id = int.tryParse(category['id']?.toString() ?? '');

      if (id == categoryId) {
        selectedCategory = category;
        break;
      }
    }

    if (selectedCategory == null) {
      throw Exception("Category: Selected category is no longer available.");
    }

    final unitId = ref.read(selectedUnitIdProvider);

    if (unitId == null || unitId <= 0) {
      throw Exception("Unit: Please select a unit.");
    }

    Map<String, dynamic>? selectedUnit;

    for (final unit in units) {
      final id = int.tryParse(unit['id']?.toString() ?? '');

      if (id == unitId) {
        selectedUnit = unit;
        break;
      }
    }

    if (selectedUnit == null) {
      throw Exception("Unit: Selected unit is no longer available.");
    }

    return (category: selectedCategory, unit: selectedUnit);
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      _hasChanges = true;
      ref.read(imageProvider.notifier).state = File(picked.path);
    }
  }

  Future<void> _confirmRemoveImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Image?"),
        content: const Text(
          "Are you sure you want to remove the selected product image?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _hasChanges = true;
      setState(() => _imageRemoved = true);
      ref.read(imageProvider.notifier).state = null;
    }
  }

  void calculateProfit() {
    double purchase = double.tryParse(purchaseController.text) ?? 0;
    double selling = double.tryParse(sellingController.text) ?? 0;
    if (purchase > 0) {
      ref.read(profitMarginProvider.notifier).state =
          ((selling - purchase) / purchase) * 100;
    } else {
      ref.read(profitMarginProvider.notifier).state = 0;
    }
  }

  Widget inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool requiredField = false,
    TextInputType? keyboard,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: R.fs(context, 13),
            ),
            children: requiredField
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.black),
                    ),
                  ]
                : [],
          ),
        ),
        SizedBox(height: R.sp(context, 8)),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: (val) {
            _hasChanges = true;
            if (onChanged != null) onChanged(val);
          },
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s+'))],
          style: TextStyle(fontSize: R.fs(context, 14)),
          decoration: InputDecoration(
            hintText: "Enter $label",
            prefixIcon: Icon(
              icon,
              color: Colors.grey.shade500,
              size: R.icon(context, 20),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: R.fluid(context, 14, 18),
              vertical: R.fluid(context, 14, 18),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        title,
        style: TextStyle(
          fontSize: R.fs(context, 18),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    final today = DateTime.now();

    final currentExpiry = expiryController.text.trim();

    DateTime initialDate = today;

    if (currentExpiry.isNotEmpty) {
      final parts = currentExpiry.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          final existingDate = DateTime(year, month, day);

          if (!existingDate.isBefore(
            DateTime(today.year, today.month, today.day),
          )) {
            initialDate = existingDate;
          }
        }
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _hasChanges = true;

      final day = pickedDate.day.toString().padLeft(2, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');

      expiryController.text = "$day/$month/${pickedDate.year}";
    }
  }

  bool _isPriceChangedFromOriginal() {
    if (widget.product == null) return false;
    final p = double.tryParse(purchaseController.text) ?? 0;
    final s = double.tryParse(sellingController.text) ?? 0;
    return p != (_originalPurchasePrice ?? 0) ||
        s != (_originalSellingPrice ?? 0);
  }

  String _resolveImageUrl(String path) {
    String trimmed = path.trim();
    if (trimmed.contains('ngrok') || trimmed.contains('localhost')) {
      if (trimmed.contains('uploads/')) {
        trimmed = 'uploads/' + trimmed.split('uploads/').last;
      }
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('/')) trimmed = trimmed.substring(1);
      trimmed = '${ApiConfig.baseUrl}/$trimmed';
    }
    return trimmed;
  }

  // ─── Build Steps ────────────────────────────────────────────
  Widget _buildStep1BasicInfo({
    required File? image,
    required String? selectedCategory,
  }) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "1. Product Media",
                style: TextStyle(
                  fontSize: R.fs(context, 18),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (image != null ||
                  (!_imageRemoved &&
                      widget.product != null &&
                      widget.product!.imagePath.trim().isNotEmpty))
                GestureDetector(
                  onTap: _confirmRemoveImage,
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: R.icon(context, 22),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: R.fluid(context, 180, 320),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(image, fit: BoxFit.cover),
                )
              : (!_imageRemoved &&
                        widget.product != null &&
                        widget.product!.imagePath.trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: _resolveImageUrl(widget.product!.imagePath),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Failed to load image",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Product Image",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      )),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => pickImage(ImageSource.gallery),
                child: Container(
                  height: R.fluid(context, 85, 110),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text(
                        "Gallery",
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => pickImage(ImageSource.camera),
                child: Container(
                  height: R.fluid(context, 85, 110),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text(
                        "Camera",
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );

                  if (result != null && result.toString().isNotEmpty) {
                    final scannedBarcode = Validators.normalizeSubmittedValue(
                      result.toString(),
                    );

                    // Perform duplicate check immediately on Step 1
                    final isDuplicate = _checkDuplicateBarcode(scannedBarcode);
                    setState(() => _barcodeDuplicate = isDuplicate);

                    if (isDuplicate) {
                      _showMissingFieldSnack(
                        "Product Code: Product with this barcode already exists.",
                      );
                    } else {
                      _hasChanges = true;
                      productcodeController.text = scannedBarcode;
                    }
                  }
                },
                child: Container(
                  height: R.fluid(context, 85, 110),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text(
                        "Scan Barcode",
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        sectionTitle("2. Basic Information"),
        inputField(
          label: "Product Name",
          controller: nameController,
          icon: Icons.inventory_2_outlined,
          requiredField: true,
        ),
        const SizedBox(height: 20),
        inputField(
          label: "Product Code",
          controller: productcodeController,
          icon: Icons.qr_code,
          onChanged: (val) {
            final normalizedBarcode = Validators.normalizeSubmittedValue(val);
            final isDuplicate = _checkDuplicateBarcode(normalizedBarcode);
            setState(() => _barcodeDuplicate = isDuplicate);
            if (isDuplicate) {
              _showMissingFieldSnack(
                "Product Code: Product with this barcode already exists.",
              );
            }
          },
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Category",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: R.fs(context, 14),
                ),
                children: const [
                  TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                // ==========================================================
                // NORMALIZE + DEDUPLICATE CATEGORY IDS
                // ==========================================================

                final uniqueCategories = <int, Map<String, dynamic>>{};

                for (final category in categories) {
                  final id = int.tryParse(category['id']?.toString() ?? '');

                  if (id != null && id > 0) {
                    uniqueCategories[id] = category;
                  }
                }

                final categoryItems = uniqueCategories.values.toList();

                // ==========================================================
                // SAFE SELECTED VALUE
                //
                // DropdownButton requires the selected value to exist
                // exactly once in the items list.
                // ==========================================================

                final safeCategoryId =
                    uniqueCategories.containsKey(selectedCategoryId)
                    ? selectedCategoryId
                    : null;

                return DropdownButtonFormField<int>(
                  value: safeCategoryId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  dropdownColor: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    hintText: "Select category",
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),

                  // ========================================================
                  // UNIQUE CATEGORY ITEMS
                  // ========================================================
                  items: categoryItems.map((category) {
                    final id = int.parse(category['id'].toString());

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(category['category_name']?.toString() ?? ''),
                    );
                  }).toList(),

                  // ========================================================
                  // CATEGORY CHANGE
                  // ========================================================
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    final selectedCategory = uniqueCategories[value];

                    if (selectedCategory == null) {
                      return;
                    }

                    _hasChanges = true;

                    ref.read(selectedCategoryIdProvider.notifier).state = value;

                    ref.read(selectedCategoryProvider.notifier).state =
                        selectedCategory['category_name']?.toString() ??
                        'General';
                  },
                );
              },

              loading: () => const CircularProgressIndicator(),

              error: (err, stack) => Text('Error loading categories: $err'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2StockSupplier({
    required bool showGstFields,
    required List<Map<String, dynamic>> supplierData,
  }) {
    final unitsAsync = ref.watch(unitsProvider);
    final selectedUnitId = ref.watch(selectedUnitIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("3. Stock Details"),
        Row(
          children: [
            Expanded(
              child: inputField(
                label: "Quantity",
                controller: quantityController,
                icon: Icons.production_quantity_limits,
                keyboard: TextInputType.number,
                requiredField: true,
              ),
            ),
            SizedBox(width: R.sp(context, 14)),
            Expanded(
              child: inputField(
                label: "Low Stock Limit",
                controller: lslController,
                icon: Icons.warning_amber_rounded,
                keyboard: TextInputType.number,
                requiredField: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Unit",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: R.fs(context, 14),
                ),
                children: const [
                  TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            unitsAsync.when(
              data: (units) {
                // ==========================================================
                // NORMALIZE + DEDUPLICATE UNIT IDS
                // ==========================================================

                final uniqueUnits = <int, Map<String, dynamic>>{};

                for (final unit in units) {
                  final id = int.tryParse(unit['id']?.toString() ?? '');

                  if (id != null && id > 0) {
                    uniqueUnits[id] = unit;
                  }
                }

                final unitItems = uniqueUnits.values.toList();

                // ==========================================================
                // SAFE SELECTED VALUE
                // ==========================================================

                final safeUnitId = uniqueUnits.containsKey(selectedUnitId)
                    ? selectedUnitId
                    : null;

                return DropdownButtonFormField<int>(
                  value: safeUnitId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  dropdownColor: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    hintText: "Select Unit",
                    prefixIcon: Icon(
                      Icons.straighten,
                      color: Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),

                  // ========================================================
                  // UNIQUE UNIT ITEMS
                  // ========================================================
                  items: unitItems.map((unit) {
                    final id = int.parse(unit['id'].toString());

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(unit['unit_name']?.toString() ?? ''),
                    );
                  }).toList(),

                  // ========================================================
                  // UNIT CHANGE
                  // ========================================================
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    final selectedUnit = uniqueUnits[value];

                    if (selectedUnit == null) {
                      return;
                    }

                    _hasChanges = true;

                    ref.read(selectedUnitIdProvider.notifier).state = value;

                    unitController.text =
                        selectedUnit['unit_name']?.toString() ?? '';
                  },
                );
              },

              loading: () => const CircularProgressIndicator(),

              error: (err, stack) => Text('Error loading units: $err'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        inputField(
          label: "Description",
          controller: descriptionController,
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 32),
        sectionTitle("4. GST, Supplier & Expiry"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Add GST and Discount",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Switch(
              value: showGstFields,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {
                _hasChanges = true;
                ref.read(showGstProvider.notifier).state = value;
                if (!value) {
                  sgstController.clear();
                  cgstController.clear();
                  hsnController.clear();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (showGstFields) ...[
          Row(
            children: [
              Expanded(
                child: inputField(
                  label: "SGST %",
                  controller: sgstController,
                  icon: Icons.percent,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(width: R.sp(context, 14)),
              Expanded(
                child: inputField(
                  label: "CGST %",
                  controller: cgstController,
                  icon: Icons.percent,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          inputField(
            label: "HSN Code",
            controller: hsnController,
            icon: Icons.numbers,
          ),
          const SizedBox(height: 20),
          inputField(
            label: "Discount %",
            controller: discountController,
            icon: Icons.discount_outlined,
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 20),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Supplier",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSupplierScreen(),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(supplierListProvider);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Supplier"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: ref.watch(selectedSupplierIdProvider),
              isExpanded: true,
              menuMaxHeight: 250,
              dropdownColor: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(16),
              decoration: InputDecoration(
                hintText: "Select supplier",
                prefixIcon: Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              items: supplierData.map((supplier) {
                return DropdownMenuItem<int>(
                  value: supplier['id'] as int,
                  child: Text(supplier['supplier_name']),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;

                final supplier = supplierData.firstWhere((e) => e['id'] == id);

                _hasChanges = true;

                ref.read(selectedSupplierIdProvider.notifier).state = id;

                ref.read(selectedSupplierProvider.notifier).state =
                    supplier['supplier_name'];
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        inputField(
          label: "Expiry Date",
          icon: Icons.calendar_month_outlined,
          controller: expiryController,
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_month),
          onTap: pickDate,
        ),
      ],
    );
  }

  Widget _buildStep3Pricing({required double profitMargin}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("5. Pricing"),
        Row(
          children: [
            Expanded(
              child: inputField(
                label: "Purchase Price",
                controller: purchaseController,
                icon: Icons.currency_rupee,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                requiredField: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: inputField(
                label: "Selling Price",
                controller: sellingController,
                icon: Icons.sell_outlined,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                requiredField: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(R.sp(context, 20)),
          decoration: BoxDecoration(
            color: profitMargin >= 0
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LIVE MARGIN",
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                    "₹${((double.tryParse(sellingController.text) ?? 0) - (double.tryParse(purchaseController.text) ?? 0)).toStringAsFixed(0)} / unit",
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                "${profitMargin.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: R.fs(context, 26),
                  fontWeight: FontWeight.w700,
                  color: profitMargin >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: R.sp(context, 8)),
        Text(
          "Updates as you type — no button needed.",
          style: TextStyle(
            fontSize: R.fs(context, 12),
            color: Colors.grey.shade500,
          ),
        ),
        if (_isPriceChangedFromOriginal())
          Container(
            margin: EdgeInsets.only(top: R.sp(context, 14)),
            padding: EdgeInsets.all(R.sp(context, 14)),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                SizedBox(width: R.sp(context, 10)),
                Expanded(
                  child: Text(
                    "Price changed. This will start a new stock batch at the updated price. Your existing $_originalQuantity units at the old price of ₹${(_originalPurchasePrice ?? 0).toStringAsFixed(0)} stay untouched and sell first — new stock you add now joins the next batch.",
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Main Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final image = ref.watch(imageProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final profitMargin = ref.watch(profitMarginProvider);
    final showGstFields = ref.watch(showGstProvider);
    final suppliersAsync = ref.watch(supplierListProvider);

    ref.watch(productListProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // ─── Top bar ──────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: _goBack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product == null ? "Add product" : "Edit product",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // ─── Steps indicator ──────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    R.fluid(context, 16, 20),
                    R.sp(context, 8),
                    R.fluid(context, 16, 20),
                    R.sp(context, 4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step ${_currentStep + 1} of 3",
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _stepLabels[_currentStep],
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.fluid(context, 16, 20),
                  ),
                  child: Row(
                    children: List.generate(3, (i) {
                      final active = i <= _currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: R.sp(context, 3),
                          ),
                          height: R.sp(context, 4),
                          decoration: BoxDecoration(
                            gradient: active ? AppColors.brandGradient : null,
                            color: active ? null : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: R.sp(context, 12)),
                // ─── Content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: R.hPad(context, base: 18),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: R.sp(context, 8)),
                      padding: EdgeInsets.all(R.sp(context, 18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: _currentStep == 0
                          ? _buildStep1BasicInfo(
                              image: image,
                              selectedCategory: selectedCategory,
                            )
                          : _currentStep == 1
                          ? suppliersAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) =>
                                  Center(child: Text(e.toString())),
                              data: (supplierData) {
                                return _buildStep2StockSupplier(
                                  showGstFields: showGstFields,
                                  supplierData: supplierData,
                                );
                              },
                            )
                          : _buildStep3Pricing(profitMargin: profitMargin),
                    ),
                  ),
                ),
                // ─── Bottom buttons ──────────────────────────
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      R.fluid(context, 16, 20),
                      R.sp(context, 8),
                      R.fluid(context, 16, 20),
                      R.sp(context, 12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: R.btnH(context),
                            child: OutlinedButton(
                              onPressed: _goBack,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(context, 14),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Back",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: R.fs(context, 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: R.sp(context, 12)),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: R.btnH(context),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 14),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, 14),
                                ),
                                onTap:
                                    (_isSaving ||
                                        (_currentStep == 0 &&
                                            _barcodeDuplicate))
                                    ? null
                                    : () {
                                        if (_currentStep < 2) {
                                          _goNext();
                                        } else {
                                          widget.product == null
                                              ? saveProduct()
                                              : updateProduct();
                                        }
                                      },
                                child: Center(
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _currentStep < 2
                                              ? "Next"
                                              : (widget.product == null
                                                    ? "Save Product"
                                                    : "Update Product"),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: R.fs(context, 15),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
