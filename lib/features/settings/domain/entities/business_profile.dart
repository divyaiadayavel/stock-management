class BusinessProfile {
  const BusinessProfile({
    this.storeName = '',
    this.tagline = '',
    this.logoPath = '',
    this.businessAddress = '',
    this.phoneNumber = '',
    this.emailAddress = '',
    this.gstNumber = '',
    this.taxRegistrationType = 'Regular',
  });

  final String storeName;
  final String tagline;
  final String logoPath;
  final String businessAddress;
  final String phoneNumber;
  final String emailAddress;
  final String gstNumber;
  final String taxRegistrationType;

  BusinessProfile copyWith({
    String? storeName,
    String? tagline,
    String? logoPath,
    String? businessAddress,
    String? phoneNumber,
    String? emailAddress,
    String? gstNumber,
    String? taxRegistrationType,
  }) {
    return BusinessProfile(
      storeName: storeName ?? this.storeName,
      tagline: tagline ?? this.tagline,
      logoPath: logoPath ?? this.logoPath,
      businessAddress: businessAddress ?? this.businessAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      gstNumber: gstNumber ?? this.gstNumber,
      taxRegistrationType: taxRegistrationType ?? this.taxRegistrationType,
    );
  }

  Map<String, dynamic> toMap() {
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
}
