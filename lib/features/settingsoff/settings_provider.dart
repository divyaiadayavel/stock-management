import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeNameProvider = StateProvider<String>((ref) => "");

final taglineProvider = StateProvider<String>((ref) => "");

final logoPathProvider = StateProvider<String?>((ref) => null);
