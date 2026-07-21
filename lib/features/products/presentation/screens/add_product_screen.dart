import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'barcode_scanner_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../providers/add_product_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';

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
  final List<String> _stepLabels = ["Basic info", "Stock & supplier", "Pricing"];

  double? _originalPurchasePrice;
  double? _originalSellingPrice;
  int _originalQuantity = 0;
  bool _isSaving = false;

  // ─── Dirty tracking ────────────────────────────────────────
  bool _hasChanges = false;

  // ─── Helper to set default category/unit when data loads ──
  void _setDefaultSelection() {
    final categories = ref.read(categoriesProvider).value;
    final units = ref.read(unitsProvider).value;

    if (categories != null && categories.isNotEmpty) {
      final currentCategoryId = ref.read(selectedCategoryIdProvider);
      if (currentCategoryId == null) {
        final firstId = categories.first['id'] as int;
        ref.read(selectedCategoryIdProvider.notifier).state = firstId;
        ref.read(selectedCategoryProvider.notifier).state = categories.first['category_name'] ?? 'General';
      }
    }

    if (units != null && units.isNotEmpty) {
      final currentUnitId = ref.read(selectedUnitIdProvider);
      if (currentUnitId == null) {
        final firstId = units.first['id'] as int;
        ref.read(selectedUnitIdProvider.notifier).state = firstId;
        unitController.text = units.first['unit_name'] ?? 'piece';
      }
    }
  }

  @override
  void initState() {
    super.initState();
  

    // Listen to all controllers to mark changes
    _addListeners();

purchaseController.addListener(calculateProfit);
sellingController.addListener(calculateProfit);

    if (widget.product != null) {
      
      // Populate fields
      nameController.text = widget.product!.name;
      productcodeController.text = widget.product!.barcode;
      expiryController.text = widget.product!.expiryDate;
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
        // Set category and unit IDs from product (if available)
        ref.read(selectedCategoryIdProvider.notifier).state = widget.product!.categoryId;
        ref.read(selectedUnitIdProvider.notifier).state = widget.product!.unitId;
        ref.read(selectedCategoryProvider.notifier).state = widget.product!.category;
        ref.read(selectedSupplierProvider.notifier).state =
            widget.product!.supplier.isNotEmpty ? widget.product!.supplier : null;
        ref.read(selectedSupplierIdProvider.notifier).state =
            widget.product!.supplierId;
        ref.read(showGstProvider.notifier).state = hsnController.text.isNotEmpty;

        calculateProfit();
        if (widget.product!.imagePath.isNotEmpty &&
            !widget.product!.imagePath.startsWith('http')) {
          ref.read(imageProvider.notifier).state = File(widget.product!.imagePath);
        }

        // After categories/units load, ensure we have a selection
        _setDefaultSelection();
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

        // After categories/units load, set defaults
        _setDefaultSelection();
      });
    }
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
        if (c.text.isNotEmpty) _hasChanges = true;
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
        content: const Text("You have unsaved changes. Are you sure you want to leave?"),
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
    if (!_validateCurrentStep()) return;
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  // ─── Validation ─────────────────────────────────────────────
  bool _validateCurrentStep() {
    final image = ref.read(imageProvider);
    if (_currentStep == 0) {
      if (image == null && widget.product == null) {
        _showMissingFieldSnack("Please select a product image");
        return false;
      }
      if (nameController.text.trim().isEmpty) {
        _showMissingFieldSnack("Product Name is required");
        return false;
      }
      return true;
    }
    if (_currentStep == 1) {
      if (quantityController.text.trim().isEmpty) {
        _showMissingFieldSnack("Quantity is required");
        return false;
      }
      if (lslController.text.trim().isEmpty) {
        _showMissingFieldSnack("Low Stock Limit is required");
        return false;
      }
      if (unitController.text.trim().isEmpty) {
        _showMissingFieldSnack("Please select a Unit");
        return false;
      }
      return true;
    }
    return true;
  }

  void _showMissingFieldSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── CRUD Operations ──────────────────────────────────────
  void updateProduct() async {
    // Ensure we have valid IDs (fallback to first available)
    _ensureValidIds();

    final selectedCategoryId = ref.read(selectedCategoryIdProvider);
    final selectedUnitId = ref.read(selectedUnitIdProvider);
    final showGstFields = ref.read(showGstProvider);

    final categories = ref.read(categoriesProvider).value ?? [];
    final units = ref.read(unitsProvider).value ?? [];
    final category = categories.cast<Map<String, dynamic>>().firstWhere(
  (e) => e['id'] == selectedCategoryId,
  orElse: () => categories.first,
);

final categoryName = category['category_name'];
    final unitName = units.firstWhere((u) => u['id'] == selectedUnitId)['unit_name'] ?? 'piece';

    try {
      final updatedProductInstance = Product(
        id: widget.product!.id,
        name: nameController.text.trim(),
        category: categoryName,
        categoryId: selectedCategoryId,
        hsnCode: showGstFields ? hsnController.text.trim() : "",
        purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0.0,
        quantity: int.tryParse(quantityController.text) ?? 0,
        unit: unitName,
        unitId: selectedUnitId,
        description: descriptionController.text.trim(),
        imagePath: ref.read(imageProvider)?.path ?? widget.product!.imagePath,
        barcode: productcodeController.text.trim(),
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0.0 : 0.0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0.0 : 0.0,
        discount: double.tryParse(discountController.text) ?? 0.0,
        expiryDate: expiryController.text.trim(),
        supplierId: ref.read(selectedSupplierIdProvider),
        supplier: ref.read(selectedSupplierProvider) ?? "",
        lsl: int.tryParse(lslController.text) ?? 10,
      );

      final success = await ref.read(productOperationsProvider.notifier)
          .modifyProduct(updatedProductInstance);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update product.")),
        );
      }
    } catch (e) {
      debugPrint("MVP EDIT MUTATION FAILURE: $e");
    }
  }

  void saveProduct() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Ensure we have valid IDs
      _ensureValidIds();

      final image = ref.read(imageProvider);
      final selectedCategoryId = ref.read(selectedCategoryIdProvider);
      final selectedUnitId = ref.read(selectedUnitIdProvider);
      final showGstFields = ref.read(showGstProvider);

      final categories = ref.read(categoriesProvider).value ?? [];
      final units = ref.read(unitsProvider).value ?? [];
      final category = categories.cast<Map<String, dynamic>>().firstWhere(
  (e) => e['id'] == selectedCategoryId,
  orElse: () => categories.first,
);

final categoryName = category['category_name'];
      final unitName = units.firstWhere((u) => u['id'] == selectedUnitId)['unit_name'] ?? 'piece';

      if (nameController.text.trim().isEmpty ||
          quantityController.text.trim().isEmpty ||
          lslController.text.trim().isEmpty ||
          unitController.text.trim().isEmpty ||
          purchaseController.text.trim().isEmpty ||
          sellingController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields.")),
        );
        return;
      }

      final newProductInstance = Product(
        name: nameController.text.trim(),
        category: categoryName,
        categoryId: selectedCategoryId,
        hsnCode: showGstFields ? hsnController.text.trim() : "",
        purchasePrice: double.tryParse(purchaseController.text) ?? 0.0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0.0,
        quantity: int.tryParse(quantityController.text) ?? 0,
        unit: unitName,
        unitId: selectedUnitId,
        description: descriptionController.text.trim(),
        imagePath: image?.path ?? "",
        barcode: productcodeController.text.trim(),
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0.0 : 0.0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0.0 : 0.0,
        discount: double.tryParse(discountController.text) ?? 0.0,
        supplierId: ref.read(selectedSupplierIdProvider),
        supplier: ref.read(selectedSupplierProvider) ?? "",
        lsl: int.tryParse(lslController.text) ?? 10,
      );

      final success = await ref.read(productOperationsProvider.notifier)
          .addProduct(newProductInstance);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product Added successfully.")),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add product.")),
        );
      }
    } catch (e) {
      debugPrint("MVP WRITE TRANSACTION ERROR: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Helper to ensure we have valid category/unit IDs ──
  void _ensureValidIds() {
    final categories = ref.read(categoriesProvider).value ?? [];
    final units = ref.read(unitsProvider).value ?? [];

    final currentCatId = ref.read(selectedCategoryIdProvider);
    if (currentCatId == null || currentCatId <= 0) {
      final firstId = categories.isNotEmpty ? categories.first['id'] as int : 1;
      ref.read(selectedCategoryIdProvider.notifier).state = firstId;
    }

    final currentUnitId = ref.read(selectedUnitIdProvider);
    if (currentUnitId == null || currentUnitId <= 0) {
      final firstId = units.isNotEmpty ? units.first['id'] as int : 1;
      ref.read(selectedUnitIdProvider.notifier).state = firstId;
    }
  }

  // ─── Image picker ──────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      _hasChanges = true;
      ref.read(imageProvider.notifier).state = File(picked.path);
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

  // ─── UI Helpers ─────────────────────────────────────────────
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
                fontSize: R.fs(context, 13)),
            children: requiredField
                ? const [TextSpan(text: " *", style: TextStyle(color: Colors.black))]
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
          onChanged: (_) => _hasChanges = true,
          style: TextStyle(fontSize: R.fs(context, 14)),
          decoration: InputDecoration(
            hintText: "Enter $label",
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: R.icon(context, 20)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
                horizontal: R.fluid(context, 14, 18),
                vertical: R.fluid(context, 14, 18)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, 10)),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, 10)),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, 10)),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(title,
          style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.w500)),
    );
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _hasChanges = true;
      expiryController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  bool _isPriceChangedFromOriginal() {
    if (widget.product == null) return false;
    final p = double.tryParse(purchaseController.text) ?? 0;
    final s = double.tryParse(sellingController.text) ?? 0;
    return p != (_originalPurchasePrice ?? 0) || s != (_originalSellingPrice ?? 0);
  }

  // ─── Build Steps ────────────────────────────────────────────
  Widget _buildStep1BasicInfo({required File? image, required String? selectedCategory}) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("1. Product Media"),
        Container(
          height: R.fluid(context, 180, 320),
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200)),
          child: image == null
              ? (widget.product != null &&
                      widget.product!.imagePath.isNotEmpty &&
                      widget.product!.imagePath.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.product!.imagePath,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("Product Image",
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(image, fit: BoxFit.cover),
                ),
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
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text("Gallery",
                          style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w500)),
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
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text("Camera",
                          style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w500)),
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
                          builder: (_) => const BarcodeScannerScreen()));
                  if (result != null) {
                    _hasChanges = true;
                    productcodeController.text = result;
                  }
                },
                child: Container(
                  height: R.fluid(context, 85, 110),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: R.icon(context, 30)),
                      const SizedBox(height: 8),
                      Text("Scan Barcode",
                          style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w500)),
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
            requiredField: true),
        const SizedBox(height: 20),
        inputField(
            label: "Product Code",
            controller: productcodeController,
            icon: Icons.qr_code),
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
                    fontSize: R.fs(context, 14)),
                children: const [TextSpan(text: " *", style: TextStyle(color: Colors.black))],
              ),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  dropdownColor: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    hintText: "Select category",
                    prefixIcon: Icon(Icons.category_outlined, color: Colors.grey.shade500),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat['id'] as int,
                      child: Text(cat['category_name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _hasChanges = true;
                      ref.read(selectedCategoryIdProvider.notifier).state = value;
                      final selectedCat = categories.firstWhere((c) => c['id'] == value);
                      ref.read(selectedCategoryProvider.notifier).state = selectedCat['category_name'] ?? 'General';
                    }
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
    required List<Map<String,dynamic>> supplierData,
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
                    requiredField: true)),
            SizedBox(width: R.sp(context, 14)),
            Expanded(
                child: inputField(
                    label: "Low Stock Limit",
                    controller: lslController,
                    icon: Icons.warning_amber_rounded,
                    keyboard: TextInputType.number,
                    requiredField: true)),
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
                    fontSize: R.fs(context, 14)),
                children: const [TextSpan(text: " *", style: TextStyle(color: Colors.black))],
              ),
            ),
            const SizedBox(height: 8),
            unitsAsync.when(
              data: (units) {
                return DropdownButtonFormField<int>(
                  value: selectedUnitId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  dropdownColor: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    hintText: "Select Unit",
                    prefixIcon: Icon(Icons.straighten, color: Colors.grey.shade500),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: units.map((unit) {
                    return DropdownMenuItem<int>(
                      value: unit['id'] as int,
                      child: Text(unit['unit_name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _hasChanges = true;
                      ref.read(selectedUnitIdProvider.notifier).state = value;
                      final selectedUnit = units.firstWhere((u) => u['id'] == value);
                      unitController.text = selectedUnit['unit_name'] ?? '';
                    }
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
            maxLines: 3),
        const SizedBox(height: 32),
        sectionTitle("4. GST, Supplier & Expiry"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Add GST and Discount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      keyboard: TextInputType.number)),
              SizedBox(width: R.sp(context, 14)),
              Expanded(
                  child: inputField(
                      label: "CGST %",
                      controller: cgstController,
                      icon: Icons.percent,
                      keyboard: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 20),
          inputField(
              label: "HSN Code",
              controller: hsnController,
              icon: Icons.numbers),
          const SizedBox(height: 20),
          inputField(
              label: "Discount %",
              controller: discountController,
              icon: Icons.discount_outlined,
              keyboard: TextInputType.number),
          const SizedBox(height: 20),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Supplier",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddSupplierScreen()));
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
                prefixIcon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
items: supplierData.map((supplier) {
  return DropdownMenuItem<int>(
    value: supplier['id'] as int,
    child: Text(
      supplier['supplier_name'],
    ),
  );
}).toList(),
onChanged: (id) {

    if(id==null) return;

    final supplier = supplierData.firstWhere(
      (e)=>e['id']==id,
    );

    ref.read(selectedSupplierIdProvider.notifier).state=id;

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
                    requiredField: true)),
            const SizedBox(width: 14),
            Expanded(
                child: inputField(
                    label: "Selling Price",
                    controller: sellingController,
                    icon: Icons.sell_outlined,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                    requiredField: true)),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(R.sp(context, 20)),
          decoration: BoxDecoration(
            color: profitMargin >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("LIVE MARGIN",
                      style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5)),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                      "₹${((double.tryParse(sellingController.text) ?? 0) - (double.tryParse(purchaseController.text) ?? 0)).toStringAsFixed(0)} / unit",
                      style: TextStyle(
                          fontSize: R.fs(context, 13),
                          color: Colors.grey.shade600)),
                ],
              ),
              Text(
                "${profitMargin.toStringAsFixed(1)}%",
                style: TextStyle(
                    fontSize: R.fs(context, 26),
                    fontWeight: FontWeight.w700,
                    color: profitMargin >= 0 ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: R.sp(context, 8)),
        Text("Updates as you type — no button needed.",
            style:
                TextStyle(fontSize: R.fs(context, 12), color: Colors.grey.shade500)),
        if (_isPriceChangedFromOriginal())
          Container(
            margin: EdgeInsets.only(top: R.sp(context, 14)),
            padding: EdgeInsets.all(R.sp(context, 14)),
            decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade200)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: Colors.amber.shade800, size: 20),
                SizedBox(width: R.sp(context, 10)),
                Expanded(
                  child: Text(
                    "Price changed. This will start a new stock batch at the updated price. Your existing $_originalQuantity units at the old price of ₹${(_originalPurchasePrice ?? 0).toStringAsFixed(0)} stay untouched and sell first — new stock you add now joins the next batch.",
                    style: TextStyle(
                        fontSize: R.fs(context, 12),
                        color: Colors.amber.shade900,
                        height: 1.4),
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
    // 🔥 Move listeners here – allowed inside build method
    ref.listen(categoriesProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultSelection());
    });
    ref.listen(unitsProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultSelection());
    });

    final image = ref.watch(imageProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final profitMargin = ref.watch(profitMarginProvider);
    final showGstFields = ref.watch(showGstProvider);
    final suppliersAsync = ref.watch(supplierListProvider);

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: _goBack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product == null ? "Add product" : "Edit product",
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontSize: 20),
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
                      R.sp(context, 4)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Step ${_currentStep + 1} of 3",
                          style: TextStyle(
                              fontSize: R.fs(context, 13),
                              color: Colors.grey.shade600)),
                      Text(_stepLabels[_currentStep],
                          style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: R.fluid(context, 16, 20)),
                  child: Row(
                    children: List.generate(3, (i) {
                      final active = i <= _currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: R.sp(context, 3)),
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
                        borderRadius: BorderRadius.circular(R.radius(context, 18)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
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
            error: (e, _) => Center(
              child: Text(e.toString()),
            ),
            data: (supplierData) {
return _buildStep2StockSupplier(
    showGstFields: showGstFields,
    supplierData: supplierData,
);
            },
          )
        : _buildStep3Pricing(
            profitMargin: profitMargin,
          ),
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
                        R.sp(context, 12)),
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
                                    borderRadius:
                                        BorderRadius.circular(R.radius(context, 14))),
                              ),
                              child: Text("Back",
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: R.fs(context, 15))),
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
                                borderRadius:
                                    BorderRadius.circular(R.radius(context, 14))),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(R.radius(context, 14)),
                                onTap: _isSaving
                                    ? null
                                    : () {
                                        if (_currentStep < 2) {
                                          _goNext();
                                        } else {
                                          if (!_validateCurrentStep()) return;
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