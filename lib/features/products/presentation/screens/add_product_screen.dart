import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/storage/db_helper.dart';
import 'barcode_scanner_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../providers/add_product_provider.dart';
import '../../../../core/utils/responsive_helper.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Map? product;
  const AddProductScreen({super.key, this.product});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  // =====================================================
  // 🔹 CONTROLLERS  (unchanged)
  // =====================================================

  final nameController = TextEditingController();
  final TextEditingController lslController = TextEditingController();
  final TextEditingController sgstController = TextEditingController();
  final TextEditingController cgstController = TextEditingController();
  final TextEditingController hsnController = TextEditingController();
  final TextEditingController productcodeController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  final purchaseController = TextEditingController();
  final sellingController = TextEditingController();

  final quantityController = TextEditingController();
  final unitController = TextEditingController();

  final descriptionController = TextEditingController();
  final supplierController = TextEditingController();
  final expiryController = TextEditingController();

  // 🆕 wizard state — which step (0,1,2) is currently shown
  int _currentStep = 0;
  final List<String> _stepLabels = [
    "Basic info",
    "Stock & supplier",
    "Pricing",
  ];

  final List<String> categories = [
    "Electronics",
    "Mobile",
    "Accessories",
    "Fashion",
    "Grocery",
    "Stationery",
    "Food",
    "Beauty",
    "Furniture",
    "Medical",
    "Sports",
    "Hardware",
    "Home Appliances",
    "Books",
    "Toys",
    "Footwear",
  ];

  @override
  void initState() {
    super.initState();
    loadSuppliers();

    // 🆕 live profit margin — recalculates automatically as the user types,
    // no button needed (matches reference image's "Live margin")
    purchaseController.addListener(calculateProfit);
    sellingController.addListener(calculateProfit);

    if (widget.product != null) {
      // --- Load existing data into controllers ---
      nameController.text = widget.product!['name'] ?? "";
      productcodeController.text = widget.product!['barcode'] ?? "";
      expiryController.text = widget.product!['expiry_date'] ?? "";
      purchaseController.text =
          widget.product!['purchase_price']?.toString() ?? "";
      sellingController.text =
          widget.product!['selling_price']?.toString() ?? "";
      quantityController.text = widget.product!['quantity']?.toString() ?? "";
      descriptionController.text = widget.product!['description'] ?? "";
      hsnController.text = widget.product!['hsn_code'] ?? "";
      unitController.text = widget.product!['unit'] ?? "";
      lslController.text = widget.product!['lsl']?.toString() ?? "10";

      sgstController.text = widget.product!['sgst']?.toString() ?? "";
      cgstController.text = widget.product!['cgst']?.toString() ?? "";
      discountController.text = widget.product!['discount']?.toString() ?? "";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryProvider.notifier).state =
            widget.product!['category'] ?? "Electronics";

        ref.read(selectedSupplierProvider.notifier).state =
            widget.product!['supplier'];

        ref.read(showGstProvider.notifier).state =
            hsnController.text.isNotEmpty;
        calculateProfit();
        if (widget.product!['image_path'] != null &&
            widget.product!['image_path'].toString().isNotEmpty) {
          ref.read(imageProvider.notifier).state = File(
            widget.product!['image_path'],
          );
        }
      });
    }
  }

  @override
  void dispose() {
    purchaseController.removeListener(calculateProfit);
    sellingController.removeListener(calculateProfit);
    super.dispose();
  }

  void updateProduct() async {
    final image = ref.read(imageProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);
    final selectedSupplier = ref.read(selectedSupplierProvider);
    final showGstFields = ref.read(showGstProvider);
    try {
      String finalImagePath =
          image?.path ?? widget.product!['image_path'] ?? "";

      await DBHelper.updateProduct(
        id: widget.product!['id'],
        name: nameController.text.trim(),
        category: selectedCategory,
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0 : 0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0 : 0,
        hsnCode: hsnController.text.trim(),
        supplier: selectedSupplier ?? "",
        expiryDate: expiryController.text.trim(),
        purchasePrice: double.tryParse(purchaseController.text) ?? 0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0,
        quantity: int.tryParse(quantityController.text) ?? 0,
        lsl: int.tryParse(lslController.text) ?? 10,
        unit: unitController.text.trim(),
        description: descriptionController.text.trim(),
        barcode: productcodeController.text.trim(),
        imagePath: finalImagePath,
        discount: double.tryParse(discountController.text) ?? 0,
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
    }
  }

  // =====================================================
  // 🔹 IMAGE PICKER
  // =====================================================

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);

    if (picked != null) {
      ref.read(imageProvider.notifier).state = File(picked.path);
    }
  }

  Future<void> loadSuppliers() async {
    final data = await DBHelper.getSuppliers();

    ref.read(suppliersProvider.notifier).state = data
        .map((e) => e["supplierName"].toString())
        .toList();
  }

  // =====================================================
  // 🔹 PROFIT MARGIN  (now called live via controller listeners)
  // =====================================================

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

  // =====================================================
  // 🔹 SAVE PRODUCT
  // =====================================================

  void saveProduct() async {
    final image = ref.read(imageProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);
    final showGstFields = ref.read(showGstProvider);

    try {
      if (image == null ||
          nameController.text.trim().isEmpty ||
          quantityController.text.trim().isEmpty ||
          lslController.text.trim().isEmpty ||
          unitController.text.trim().isEmpty ||
          purchaseController.text.trim().isEmpty ||
          sellingController.text.trim().isEmpty ||
          selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please fill all required fields and select a product image",
            ),
          ),
        );
        return;
      }

      await DBHelper.addProduct(
        name: nameController.text.trim(),
        category: selectedCategory,
        sgst: showGstFields ? double.tryParse(sgstController.text) ?? 0 : 0,
        cgst: showGstFields ? double.tryParse(cgstController.text) ?? 0 : 0,
        hsnCode: showGstFields ? hsnController.text.trim() : "",
        supplier: supplierController.text.trim(),
        expiryDate: expiryController.text.trim(),
        purchasePrice: double.tryParse(purchaseController.text) ?? 0,
        sellingPrice: double.tryParse(sellingController.text) ?? 0,
        quantity: int.tryParse(quantityController.text) ?? 0,
        lsl: int.tryParse(lslController.text) ?? 10,
        unit: unitController.text.trim(),
        description: descriptionController.text.trim(),
        barcode: productcodeController.text.trim(),
        imagePath: image?.path ?? "",
        discount: double.tryParse(discountController.text) ?? 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE PRODUCT ERROR : $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // =====================================================
  // 🔹 INPUT FIELD  (unchanged)
  // =====================================================

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

  // =====================================================
  // 🔹 SECTION TITLE  (unchanged)
  // =====================================================

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

  // =====================================================
  // 🔹 DATE PICKER  (unchanged)
  // =====================================================

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      expiryController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  // =====================================================
  // 🆕 STEP VALIDATION — required (★) fields must be filled
  //    before the user can move to the next step
  // =====================================================
  bool _validateCurrentStep() {
    final image = ref.read(imageProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);

    if (_currentStep == 0) {
      if (image == null) {
        _showMissingFieldSnack("Please select a product image");
        return false;
      }
      if (nameController.text.trim().isEmpty) {
        _showMissingFieldSnack("Product Name is required");
        return false;
      }
      // if (selectedCategory == null) {
      //   _showMissingFieldSnack("Please select a category");
      //   return false;
      // }
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

    // step 2 (Pricing) — checked at save time, no "next" step after it
    return true;
  }

  void _showMissingFieldSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🆕 step navigation helpers
  void _goNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _currentStep--);
    }
  }

  // =====================================================
  // 🔹 BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final image = ref.watch(imageProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSupplier = ref.watch(selectedSupplierProvider);
    final profitMargin = ref.watch(profitMarginProvider);
    final showGstFields = ref.watch(showGstProvider);
    final suppliers = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar is completely removed!

      // Wrapped in SafeArea so your new header doesn't hit the phone notch
      body: SafeArea(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // ── Custom Header (Replaces the AppBar) ──
              Container(
                color: Colors.white, // Matches your old AppBar color
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
                        fontSize: 20, // Standard AppBar title size
                      ),
                    ),
                  ],
                ),
              ),

              // ── Step progress header (matches reference image) ──
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

              // ── Step body ──
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
                          color: Colors.black.withOpacity(0.05),
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
                        ? _buildStep2StockSupplier(
                            showGstFields: showGstFields,
                            selectedSupplier: selectedSupplier,
                            suppliers: suppliers,
                          )
                        : _buildStep3Pricing(profitMargin: profitMargin),
                  ),
                ),
              ),

              // ── Bottom nav buttons: Back / Next / Save (gradient) ──
              SafeArea(
                top:
                    false, // Don't apply top safe area here since it's on the main body
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
                              onTap: () {
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
                                child: Text(
                                  _currentStep < 2
                                      ? "Next"
                                      : (widget.product == null
                                            ? "Save product"
                                            : "Update product"),
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
    );
  }

  // =====================================================
  // 🔹 STEP 1 — Product Media + core identity fields
  //    (Name*, Code, Category*)
  // =====================================================
  Widget _buildStep1BasicInfo({
    required File? image,
    required String? selectedCategory,
  }) {
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
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      "Product Image",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(image, fit: BoxFit.cover),
                ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _mediaButton(
                icon: Icons.photo_library,
                title: "Gallery",
                onTap: () => pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mediaButton(
                icon: Icons.camera_alt,
                title: "Camera",
                onTap: () => pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mediaButton(
                icon: Icons.qr_code_scanner,
                title: "Scan Barcode",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (result != null) {
                    productcodeController.text = result;
                  }
                },
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
            DropdownButtonFormField<String>(
              value: selectedCategory,
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
              items: categories.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(selectedCategoryProvider.notifier).state = value!;
              },
            ),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // 🔹 STEP 2 — Stock Details + GST/Discount + Supplier + Expiry
  //    (Quantity*, Low Stock Limit*, Unit*)
  // =====================================================
  Widget _buildStep2StockSupplier({
    required bool showGstFields,
    required String? selectedSupplier,
    required List<String> suppliers,
  }) {
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
            DropdownButtonFormField<String>(
              value: unitController.text.isEmpty ? null : unitController.text,
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              items: ["Kg", "gram", "litre", "piece", "box"].map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => unitController.text = value!);
              },
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
              activeColor: AppColors.primary,
              onChanged: (value) {
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

        if (showGstFields)
          Column(
            children: [
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
          ),

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
                      loadSuppliers();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Supplier"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSupplier,
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
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(selectedSupplierProvider.notifier).state = value;
                supplierController.text = value!;
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

  // =====================================================
  // 🔹 STEP 3 — Pricing
  //    (Purchase*, Selling* + auto-calculated LIVE margin card,
  //    no button — updates as you type, matches reference image)
  // =====================================================
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

        // 🆕 LIVE MARGIN card — no button, recalculates automatically
        // every time purchase/selling controllers change
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
      ],
    );
  }

  // =====================================================
  // 🔹 MEDIA BUTTON  (unchanged)
  // =====================================================
  Widget _mediaButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, size: R.icon(context, 30)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
