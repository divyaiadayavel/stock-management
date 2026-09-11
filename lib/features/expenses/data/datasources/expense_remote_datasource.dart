import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stock_management/core/network/api_config.dart';
import 'package:stock_management/features/expenses/data/models/expense_model.dart';

/// Remote data source for Expenses.
///
/// Single backend endpoint:
///
/// GET    /api/expenses/expense.php
/// POST   /api/expenses/expense.php
/// PUT    /api/expenses/expense.php
/// DELETE /api/expenses/expense.php?id={id}
class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource._();

  static const Duration _requestTimeout =
      Duration(seconds: 30);

  // ==========================================================
  // Common helpers
  // ==========================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'Invalid response received from expense server '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid expense API response format '
        '(HTTP ${response.statusCode}).',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  static String _apiMessage(
    Map<String, dynamic> json,
    String fallback,
  ) {
    final message = json['message'];

    if (message != null &&
        message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return fallback;
  }

  static Map<String, dynamic> _requireDataObject(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];

    if (data is! Map) {
      throw Exception(
        'Expense data is missing from API response.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ==========================================================
  // GET EXPENSES
  // ==========================================================

  static Future<List<ExpenseModel>> getExpenses() async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.expenses),
          headers: ApiConfig.jsonHeaders,
        )
        .timeout(_requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to load expenses '
          '(HTTP ${response.statusCode}).',
        ),
      );
    }

    if (json['success'] != true) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to load expenses.',
        ),
      );
    }

    final data = json['data'];

    if (data == null) {
      return const [];
    }

    if (data is! List) {
      throw Exception(
        'Invalid expenses list received from server.',
      );
    }

    return data.map<ExpenseModel>((item) {
      if (item is! Map) {
        throw Exception(
          'Invalid expense item received from server.',
        );
      }

      return ExpenseModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // ==========================================================
  // ADD EXPENSE
  // ==========================================================

  static Future<ExpenseModel> addExpense(
    ExpenseModel expense,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.expenses),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode(
            expense.toJson(),
          ),
        )
        .timeout(_requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to add expense '
          '(HTTP ${response.statusCode}).',
        ),
      );
    }

    if (json['success'] != true) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to add expense.',
        ),
      );
    }

    final data =
        _requireDataObject(json);

    return ExpenseModel.fromJson(data);
  }

  // ==========================================================
  // UPDATE EXPENSE
  // ==========================================================

  static Future<ExpenseModel> updateExpense(
    ExpenseModel expense,
  ) async {
    if (expense.id.trim().isEmpty) {
      throw Exception(
        'Expense ID is required for update.',
      );
    }

    final response = await http
        .put(
          Uri.parse(ApiConfig.expenses),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode(
            expense.toJson(),
          ),
        )
        .timeout(_requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to update expense '
          '(HTTP ${response.statusCode}).',
        ),
      );
    }

    if (json['success'] != true) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to update expense.',
        ),
      );
    }

    final data =
        _requireDataObject(json);

    return ExpenseModel.fromJson(data);
  }

  // ==========================================================
  // SOFT DELETE EXPENSE
  // ==========================================================

  static Future<void> deleteExpense(
    String id,
  ) async {
    if (id.trim().isEmpty) {
      throw Exception(
        'Expense ID is required for deletion.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.expenses}'
      '?id=${Uri.encodeQueryComponent(id)}',
    );

    final response = await http
        .delete(
          uri,
          headers: ApiConfig.jsonHeaders,
        )
        .timeout(_requestTimeout);

    final json = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to delete expense '
          '(HTTP ${response.statusCode}).',
        ),
      );
    }

    if (json['success'] != true) {
      throw Exception(
        _apiMessage(
          json,
          'Failed to delete expense.',
        ),
      );
    }
  }
}