import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// Address model for both user profile and company
@freezed
class Address with _$Address {
  const factory Address({
    @Default('') String country,
    @Default('') String city,
    @Default('') String street,
    @Default('') String postalCode,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

/// Social media links
@freezed
class SocialLinks with _$SocialLinks {
  const factory SocialLinks({
    @Default('') String website,
    @Default('') String facebook,
  }) = _SocialLinks;

  factory SocialLinks.fromJson(Map<String, dynamic> json) =>
      _$SocialLinksFromJson(json);
}

/// Company details for property owners
@freezed
class CompanyDetails with _$CompanyDetails {
  const CompanyDetails._();

  const factory CompanyDetails({
    @Default('') String companyName,
    @Default('') String taxId,
    @Default('') String vatId,
    @Default('') String bankAccountIban,
    @Default('') String swift,
    @Default('') String bankName,
    @Default('') String accountHolder,
    @Default(Address()) Address address,
    DateTime? updatedAt,
  }) = _CompanyDetails;

  factory CompanyDetails.fromJson(Map<String, dynamic> json) =>
      _$CompanyDetailsFromJson(json);

  factory CompanyDetails.fromFirestore(Map<String, dynamic> data) {
    return CompanyDetails(
      companyName: data['companyName'] as String? ?? '',
      taxId: data['taxId'] as String? ?? '',
      vatId: data['vatId'] as String? ?? '',
      bankAccountIban: data['bankAccountIban'] as String? ?? '',
      swift: data['swift'] as String? ?? '',
      bankName: data['bankName'] as String? ?? '',
      accountHolder: data['accountHolder'] as String? ?? '',
      address: data['address'] != null
          ? Address.fromJson(data['address'] as Map<String, dynamic>)
          : const Address(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Check if bank details are complete for bank transfer payments
  bool get hasBankDetails {
    return bankAccountIban.isNotEmpty &&
        bankName.isNotEmpty &&
        accountHolder.isNotEmpty;
  }
}

/// User profile model (stored in Firestore: users/{userId}/profile)
@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String userId,
    @Default('') String displayName,
    @Default('') String emailContact,
    @Default('') String phoneE164, // E.164 format: +385911234567
    @Default(Address()) Address address,
    @Default(SocialLinks()) SocialLinks social,
    @Default('') String propertyType,
    @Default('') String logoUrl,
    DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  factory UserProfile.fromFirestore(String userId, Map<String, dynamic> data) {
    return UserProfile(
      userId: userId,
      displayName: data['displayName'] as String? ?? '',
      emailContact: data['emailContact'] as String? ?? '',
      phoneE164: data['phoneE164'] as String? ?? '',
      address: data['address'] != null
          ? Address.fromJson(data['address'] as Map<String, dynamic>)
          : const Address(),
      social: data['social'] != null
          ? SocialLinks.fromJson(data['social'] as Map<String, dynamic>)
          : const SocialLinks(),
      propertyType: data['propertyType'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore data (exclude userId)
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'emailContact': emailContact,
      'phoneE164': phoneE164,
      'address': address.toJson(),
      'social': social.toJson(),
      'propertyType': propertyType,
      'logoUrl': logoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Calculate profile completion percentage based on filled fields
  int get completionPercentage {
    int filled = 0;
    const total = 7; // Total fields to track

    if (displayName.isNotEmpty) filled++;
    if (emailContact.isNotEmpty) filled++;
    if (phoneE164.isNotEmpty) filled++;
    if (address.city.isNotEmpty) filled++;
    if (address.country.isNotEmpty) filled++;
    if (propertyType.isNotEmpty) filled++;
    if (logoUrl.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }
}

/// Complete user data (combines profile + company)
@freezed
class UserData with _$UserData {
  const factory UserData({
    required UserProfile profile,
    @Default(CompanyDetails()) CompanyDetails company,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
