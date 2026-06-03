import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedFilterProvider = StateProvider<String>((ref) => "All");

final searchQueryProvider = StateProvider<String>((ref) => "");
