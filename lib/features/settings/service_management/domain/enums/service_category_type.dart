// lib/features/settings/service_management/domain/enums/service_category_type.dart

/// Which tab a category belongs to on the Services & Categories screen.
///
/// A category lives in exactly one tab. Categories created before the
/// split are SERVICE, which is what the backend defaults to, so nothing
/// existing moves.
enum ServiceCategoryType {
  service,
  provider,
}

extension ServiceCategoryTypeX on ServiceCategoryType {
  /// Value stored in `service_categories.type`.
  String get apiValue {
    switch (this) {
      case ServiceCategoryType.service:
        return 'SERVICE';
      case ServiceCategoryType.provider:
        return 'PROVIDER';
    }
  }

  /// Tab label.
  String get tabLabel {
    switch (this) {
      case ServiceCategoryType.service:
        return 'Service';
      case ServiceCategoryType.provider:
        return 'Provider';
    }
  }

  /// Singular noun for the thing this category holds.
  String get itemLabel {
    switch (this) {
      case ServiceCategoryType.service:
        return 'Service';
      case ServiceCategoryType.provider:
        return 'Provider';
    }
  }

  /// Plural noun, used in the "3 Services" / "3 Providers" count line.
  String get itemLabelPlural {
    switch (this) {
      case ServiceCategoryType.service:
        return 'Services';
      case ServiceCategoryType.provider:
        return 'Providers';
    }
  }

  bool get isProvider => this == ServiceCategoryType.provider;

  static ServiceCategoryType fromApiValue(String? value) {
    switch (value?.toUpperCase().trim()) {
      case 'PROVIDER':
        return ServiceCategoryType.provider;
      case 'SERVICE':
      default:
        return ServiceCategoryType.service;
    }
  }
}
