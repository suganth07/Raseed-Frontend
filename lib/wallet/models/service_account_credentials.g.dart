// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_account_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountCredentials _$ServiceAccountCredentialsFromJson(
        Map<String, dynamic> json) =>
    ServiceAccountCredentials(
      clientEmail: json['clientEmail'] as String,
      privateKey: json['privateKey'] as String,
      issuerId: json['issuerId'] as String,
    );

Map<String, dynamic> _$ServiceAccountCredentialsToJson(
        ServiceAccountCredentials instance) =>
    <String, dynamic>{
      'clientEmail': instance.clientEmail,
      'privateKey': instance.privateKey,
      'issuerId': instance.issuerId,
    };
