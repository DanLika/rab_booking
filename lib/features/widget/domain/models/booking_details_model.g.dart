// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GuestCountImpl _$$GuestCountImplFromJson(Map<String, dynamic> json) =>
    _$GuestCountImpl(
      adults: (json['adults'] as num).toInt(),
      children: (json['children'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$GuestCountImplToJson(_$GuestCountImpl instance) =>
    <String, dynamic>{'adults': instance.adults, 'children': instance.children};

_$BankDetailsImpl _$$BankDetailsImplFromJson(Map<String, dynamic> json) =>
    _$BankDetailsImpl(
      bankName: json['bankName'] as String?,
      accountHolder: json['accountHolder'] as String?,
      iban: json['iban'] as String?,
      swift: json['swift'] as String?,
    );

Map<String, dynamic> _$$BankDetailsImplToJson(_$BankDetailsImpl instance) =>
    <String, dynamic>{
      'bankName': instance.bankName,
      'accountHolder': instance.accountHolder,
      'iban': instance.iban,
      'swift': instance.swift,
    };

_$BookingDetailsModelImpl _$$BookingDetailsModelImplFromJson(
  Map<String, dynamic> json,
) => _$BookingDetailsModelImpl(
  bookingId: json['bookingId'] as String,
  bookingReference: json['bookingReference'] as String,
  propertyId: json['propertyId'] as String?,
  unitId: json['unitId'] as String?,
  propertyName: json['propertyName'] as String,
  unitName: json['unitName'] as String,
  guestName: json['guestName'] as String,
  guestEmail: json['guestEmail'] as String,
  guestPhone: json['guestPhone'] as String?,
  checkIn: json['checkIn'] as String,
  checkOut: json['checkOut'] as String,
  nights: (json['nights'] as num).toInt(),
  guestCount: GuestCount.fromJson(json['guestCount'] as Map<String, dynamic>),
  totalPrice: (json['totalPrice'] as num).toDouble(),
  depositAmount: (json['depositAmount'] as num).toDouble(),
  remainingAmount: (json['remainingAmount'] as num).toDouble(),
  paidAmount: (json['paidAmount'] as num).toDouble(),
  paymentStatus: json['paymentStatus'] as String,
  paymentMethod: json['paymentMethod'] as String,
  status: json['status'] as String,
  ownerEmail: json['ownerEmail'] as String?,
  ownerPhone: json['ownerPhone'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] as String?,
  paymentDeadline: json['paymentDeadline'] as String?,
  bankDetails: json['bankDetails'] == null
      ? null
      : BankDetails.fromJson(json['bankDetails'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$BookingDetailsModelImplToJson(
  _$BookingDetailsModelImpl instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'bookingReference': instance.bookingReference,
  'propertyId': instance.propertyId,
  'unitId': instance.unitId,
  'propertyName': instance.propertyName,
  'unitName': instance.unitName,
  'guestName': instance.guestName,
  'guestEmail': instance.guestEmail,
  'guestPhone': instance.guestPhone,
  'checkIn': instance.checkIn,
  'checkOut': instance.checkOut,
  'nights': instance.nights,
  'guestCount': instance.guestCount,
  'totalPrice': instance.totalPrice,
  'depositAmount': instance.depositAmount,
  'remainingAmount': instance.remainingAmount,
  'paidAmount': instance.paidAmount,
  'paymentStatus': instance.paymentStatus,
  'paymentMethod': instance.paymentMethod,
  'status': instance.status,
  'ownerEmail': instance.ownerEmail,
  'ownerPhone': instance.ownerPhone,
  'notes': instance.notes,
  'createdAt': instance.createdAt,
  'paymentDeadline': instance.paymentDeadline,
  'bankDetails': instance.bankDetails,
};

_$BookingLookupResponseImpl _$$BookingLookupResponseImplFromJson(
  Map<String, dynamic> json,
) => _$BookingLookupResponseImpl(
  success: json['success'] as bool,
  booking: BookingDetailsModel.fromJson(
    json['booking'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$BookingLookupResponseImplToJson(
  _$BookingLookupResponseImpl instance,
) => <String, dynamic>{
  'success': instance.success,
  'booking': instance.booking,
};
