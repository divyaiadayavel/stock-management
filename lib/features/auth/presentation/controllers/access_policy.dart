enum AppFeature { dashboard, products, billing, suppliers, settings }

class RoleAccessPolicy {
  const RoleAccessPolicy._();

  // ─── FLIP THIS TO false WHEN READY TO ENFORCE ROLES ───────────
  static const bool allowAllRolesTemporarily = false;
  // ──────────────────────────────────────────────────────────────

  static const Set<AppFeature> allFeatures = {
    AppFeature.dashboard,
    AppFeature.products,
    AppFeature.billing,
    AppFeature.suppliers,
    AppFeature.settings,
  };

  static const Map<String, Set<AppFeature>> _roleFeatureMap = {
    'admin': allFeatures,
    'manager': allFeatures,
    'cashier': {
      AppFeature.dashboard,
      AppFeature.billing,
    },
    'salesperson': {
      AppFeature.dashboard,
      AppFeature.billing,
    },
    'inventory staff': {
      AppFeature.dashboard,
      AppFeature.products,
      AppFeature.suppliers,
    },
  };

  static bool canAccess({required String role, required AppFeature feature}) {
    return allowedFeatures(role).contains(feature);
  }

  static Set<AppFeature> allowedFeatures(String role) {
    if (allowAllRolesTemporarily) return allFeatures;
    return _roleFeatureMap[normalizeRole(role)] ?? const <AppFeature>{};
  }

  static String normalizeRole(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String featureLabel(AppFeature feature) {
    switch (feature) {
      case AppFeature.dashboard:
        return 'Dashboard';
      case AppFeature.products:
        return 'Products';
      case AppFeature.billing:
        return 'Billing';
      case AppFeature.suppliers:
        return 'Suppliers';
      case AppFeature.settings:
        return 'Settings';
    }
  }

  static List<String> allowedFeatureLabels(String role) {
    return allowedFeatures(role).map(featureLabel).toList();
  }

  static String accessSummary(String role) {
    if (allowAllRolesTemporarily) return 'Current access: all screens.';
    final labels = allowedFeatureLabels(role);
    if (labels.isEmpty) return 'Current access: no screens assigned.';
    return 'Current access: ${labels.join(', ')}.';
  }
}