import '../../domain/entities/business_profile.dart';

class BusinessProfileModel extends BusinessProfile {
  const BusinessProfileModel({
    super.storeName,
    super.tagline,
    super.logoPath,
    super.businessAddress,
    super.phoneNumber,
    super.emailAddress,
    super.gstNumber,
    super.taxRegistrationType,
  });

  factory BusinessProfileModel.fromEntity(BusinessProfile profile) {
    return BusinessProfileModel(
      storeName: profile.storeName,
      tagline: profile.tagline,
      logoPath: profile.logoPath,
      businessAddress: profile.businessAddress,
      phoneNumber: profile.phoneNumber,
      emailAddress: profile.emailAddress,
      gstNumber: profile.gstNumber,
      taxRegistrationType: profile.taxRegistrationType,
    );
  }

  factory BusinessProfileModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};

    return BusinessProfileModel(
      storeName: _readString(data, 'storeName', alternateKey: 'store_name'),
      tagline: _readString(data, 'tagline'),
      logoPath: _readString(
        data,
        'logoPath',
        alternateKey: 'logo_url',
        thirdKey: 'logo_path',
      ),
      businessAddress: _readString(
        data,
        'businessAddress',
        alternateKey: 'business_address',
      ),
      phoneNumber: _readString(
        data,
        'phoneNumber',
        alternateKey: 'phone_number',
      ),
      emailAddress: _readString(
        data,
        'emailAddress',
        alternateKey: 'email_address',
      ),
      gstNumber: _readString(data, 'gstNumber', alternateKey: 'gst_number'),
      taxRegistrationType: _readString(
        data,
        'taxRegistrationType',
        alternateKey: 'tax_registration_type',
        fallback: 'Regular',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'tagline': tagline,
      'logoPath': logoPath,
      'businessAddress': businessAddress,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'gstNumber': gstNumber,
      'taxRegistrationType': taxRegistrationType,
    };
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String? alternateKey,
    String? thirdKey,
    String fallback = '',
  }) {
    final value = json[key] ?? json[alternateKey] ?? json[thirdKey];
    if (value == null) return fallback;
    return value.toString();
  }
}
