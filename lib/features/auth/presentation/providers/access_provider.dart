import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/access_policy.dart';
import '../controllers/auth_controller.dart';

final roleAccessProvider = Provider<RoleAccessSnapshot>((ref) {
  final authState = ref.watch(authControllerProvider);
  final role = authState.currentRole;

  return RoleAccessSnapshot(
    role: role,
    displayName: authState.displayName,
    isLoggedIn: authState.isLoggedIn,
    isTemporaryAllAccess: RoleAccessPolicy.allowAllRolesTemporarily,
    allowedFeatures: RoleAccessPolicy.allowedFeatures(role),
  );
});

final canAccessFeatureProvider = Provider.family<bool, AppFeature>((
  ref,
  feature,
) {
  return ref.watch(roleAccessProvider).canAccess(feature);
});

class RoleAccessSnapshot {
  const RoleAccessSnapshot({
    required this.role,
    required this.displayName,
    required this.isLoggedIn,
    required this.isTemporaryAllAccess,
    required this.allowedFeatures,
  });

  final String role;
  final String displayName;
  final bool isLoggedIn;
  final bool isTemporaryAllAccess;
  final Set<AppFeature> allowedFeatures;

  bool canAccess(AppFeature feature) {
    return allowedFeatures.contains(feature);
  }

  List<String> get allowedFeatureLabels {
    return allowedFeatures.map(RoleAccessPolicy.featureLabel).toList();
  }
}
