import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardFilterProvider = StateProvider<String>((ref) => "Day");

final graphVisibilityProvider = StateProvider<bool>((ref) => true);
