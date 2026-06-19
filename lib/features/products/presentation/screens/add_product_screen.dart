import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/storage/db_helper.dart';
import 'barcode_scanner_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../providers/add_product_provider.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/utils/responsive_helper.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Map? product; // Add this line
  const AddProductScreen({super.key, this.product}); // Update this line

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  // =====================================================
  // 🔹 CONTROLLERS
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

      // 🔹 FIX 1: Load GST values so they don't reset to 0
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

  void updateProduct() async {
    final image = ref.read(imageProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);
    final selectedSupplier = ref.read(selectedSupplierProvider);
    final showGstFields = ref.read(showGstProvider);
    try {
      // 🔹 FIX 2: Logic for Image Persistence
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
        expiryDate: expiryController.text
            .trim(), // Holds old date if not changed
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
  // 🔹 PROFIT MARGIN
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

      // DBHelper.addProduct(...)
      // ✅ SAVE PRODUCT
      await DBHelper.addProduct(
        name: nameController.text.trim(),

        category: selectedCategory,

        // GST
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

      // ✅ SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully")),
      );

      // ✅ BACK TO PRODUCT SCREEN
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("SAVE PRODUCT ERROR : $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  // =====================================================
  // 🔹 INPUT FIELD
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
  // 🔹 SECTION TITLE
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
  // 🔹 DATE PICKER
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
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.product == null
              ? "Add Products"
              : "Edit Product", // Dynamic Title
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: AppColors.primary,

        child: ClipRRect(
          borderRadius: AppCurve.top(context),

          child: Container(
            color: Colors.grey.shade100,

            child: SingleChildScrollView(
              padding: R.hPad(context, base: 18),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: R.sp(context, 18)),
                padding: EdgeInsets.all(R.sp(context, 18)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(context, 18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // 🔹 PRODUCT MEDIA
                    // =====================================================
                    sectionTitle("1. Product Media"),

                    // 🔹 IMAGE
                    Container(
                      height: R.fluid(context, 180, 320),
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: image == null
                          ? Column(
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
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(image!, fit: BoxFit.cover),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 MEDIA BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _mediaButton(
                            icon: Icons.photo_library,
                            title: "Gallery",

                            onTap: () {
                              pickImage(ImageSource.gallery);
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _mediaButton(
                            icon: Icons.camera_alt,
                            title: "Camera",

                            onTap: () {
                              pickImage(ImageSource.camera);
                            },
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

                    // =====================================================
                    // 🔹 BASIC INFORMATION
                    // =====================================================
                    sectionTitle("2. Basic Information"),

                    inputField(
                      label: "Product Name",
                      controller: nameController,
                      icon: Icons.inventory_2_outlined,
                      requiredField: true,
                    ),
                    inputField(
                      label: "Product Code",
                      controller: productcodeController,
                      icon: Icons.qr_code,
                    ),

                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: R.fs(context, 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          menuMaxHeight: 250,

                          // -- Kept Dropdown Menu Styling (Popup only) --
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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 10),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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
                          items: categories.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            ref.read(selectedCategoryProvider.notifier).state =
                                value!;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🔹 ADD GST BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add GST and Discount",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Switch(
                          value: showGstFields,
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

                    // 🔹 GST FIELDS
                    if (showGstFields)
                      Column(
                        children: [
                          inputField(
                            label: "State GST (SGST) %",
                            controller: sgstController,
                            icon: Icons.percent,
                            keyboard: TextInputType.number,
                          ),

                          const SizedBox(height: 20),

                          inputField(
                            label: "Central GST (CGST) %",
                            controller: cgstController,
                            icon: Icons.percent,
                            keyboard: TextInputType.number,
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

                    // 🔹 SUPPLIER
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Supplier",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddSupplierScreen(),
                                  ),
                                );

                                // 🔹 Refresh supplier list after adding
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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 10),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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

                          items: suppliers.map((supplier) {
                            return DropdownMenuItem(
                              value: supplier,
                              child: Text(
                                supplier,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: (value) {
                            ref.read(selectedSupplierProvider.notifier).state =
                                value;

                            supplierController.text = value!;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔹 EXPIRY DATE
                    inputField(
                      label: "Expiry Date",
                      icon: Icons.calendar_month_outlined,
                      controller: expiryController,
                      readOnly: true,

                      suffixIcon: const Icon(Icons.calendar_month),

                      onTap: pickDate,
                    ),

                    const SizedBox(height: 32),
                    // =====================================================
                    // 🔹 STOCK DETAILS
                    // =====================================================
                    sectionTitle("3. Stock Details"),

                    Row(
                      children: [
                        // Quantity wrapped in Expanded
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

                        // Low Stock Limit wrapped in Expanded
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

                    // 🔹 UNIT DROPDOWN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Unit",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: unitController.text.isEmpty
                              ? null
                              : unitController.text,

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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 10),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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
                          items: ["Kg", "gram", "litre", "piece", "box"].map((
                            unit,
                          ) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: (value) {
                            unitController.text = value!;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    inputField(
                      label: "Description",
                      controller: descriptionController,
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),

                    // =====================================================
                    // 🔹 PRICING
                    // =====================================================
                    sectionTitle("4. Pricing"),

                    Row(
                      children: [
                        // Purchase Price wrapped in Expanded
                        Expanded(
                          child: inputField(
                            label: "Purchase Price",
                            controller: purchaseController,
                            icon: Icons.currency_rupee,
                            keyboard: TextInputType.number,
                            requiredField: true,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Selling Price wrapped in Expanded
                        Expanded(
                          child: inputField(
                            label: "Selling Price",
                            controller: sellingController,
                            icon: Icons.sell_outlined,
                            keyboard: TextInputType.number,
                            requiredField: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 🔹 PROFIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: R.btnH(context),

                      child: ElevatedButton(
                        onPressed: calculateProfit,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        child: const Text(
                          "Calculate Profit Margin",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 🔹 PROFIT CARD
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(R.sp(context, 22)),

                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: Column(
                        children: [
                          const Text(
                            "Profit Margin",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "${profitMargin.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: R.fs(context, 34),
                              fontWeight: FontWeight.w500,
                              color: profitMargin > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // =====================================================
                    // 🔹 SAVE BUTTON
                    // =====================================================
                    SizedBox(
                      width: double.infinity,
                      height: R.btnH(context),

                      child: ElevatedButton(
                        onPressed: widget.product == null
                            ? saveProduct
                            : updateProduct, // Dynamic Function
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.product == null
                              ? Colors.blue
                              : Colors.orange, // Optional color change
                        ),
                        child: Text(
                          widget.product == null
                              ? "Save Product"
                              : "Update Product", // Dynamic Text
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: R.fs(context, 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🔹 MEDIA BUTTON
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
