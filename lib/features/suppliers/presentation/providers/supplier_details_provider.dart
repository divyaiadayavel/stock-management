import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/db_helper.dart';

final supplierDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
      return await DBHelper.getSupplierById(id);
    });
