// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GuestDetailsImpl _$$GuestDetailsImplFromJson(Map<String, dynamic> json) =>
    _$GuestDetailsImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      message: json['message'] as String? ?? '',
    );

Map<String, dynamic> _$$GuestDetailsImplToJson(_$GuestDetailsImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'message': instance.message,
    };
