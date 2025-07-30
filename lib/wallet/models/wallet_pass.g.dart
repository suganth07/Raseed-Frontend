// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_pass.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletPass _$WalletPassFromJson(Map<String, dynamic> json) => WalletPass(
      id: json['id'] as String,
      classId: json['classId'] as String?,
      state: $enumDecode(_$PassStateEnumMap, json['state']),
      passType: $enumDecode(_$PassTypeEnumMap, json['passType']),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      additionalData: (json['additionalData'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      saveUrl: json['saveUrl'] as String?,
      barcode: json['barcode'] as String?,
      barcodeType: json['barcodeType'] as String?,
      eventName: json['eventName'] as String?,
      venue: json['venue'] as String?,
      eventDate: json['eventDate'] == null
          ? null
          : DateTime.parse(json['eventDate'] as String),
      seatInfo: json['seatInfo'] as String?,
      ticketType: json['ticketType'] as String?,
      tripName: json['tripName'] as String?,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      departureTime: json['departureTime'] == null
          ? null
          : DateTime.parse(json['departureTime'] as String),
      seatNumber: json['seatNumber'] as String?,
      vehicleType: json['vehicleType'] as String?,
      offerCode: json['offerCode'] as String?,
      loyaltyAccountId: json['loyaltyAccountId'] as String?,
      pointsBalance: (json['pointsBalance'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WalletPassToJson(WalletPass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classId': instance.classId,
      'state': _$PassStateEnumMap[instance.state]!,
      'passType': _$PassTypeEnumMap[instance.passType]!,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'logoUrl': instance.logoUrl,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'additionalData': instance.additionalData,
      'saveUrl': instance.saveUrl,
      'barcode': instance.barcode,
      'barcodeType': instance.barcodeType,
      'eventName': instance.eventName,
      'venue': instance.venue,
      'eventDate': instance.eventDate?.toIso8601String(),
      'seatInfo': instance.seatInfo,
      'ticketType': instance.ticketType,
      'tripName': instance.tripName,
      'origin': instance.origin,
      'destination': instance.destination,
      'departureTime': instance.departureTime?.toIso8601String(),
      'seatNumber': instance.seatNumber,
      'vehicleType': instance.vehicleType,
      'offerCode': instance.offerCode,
      'loyaltyAccountId': instance.loyaltyAccountId,
      'pointsBalance': instance.pointsBalance,
    };

const _$PassStateEnumMap = {
  PassState.active: 'ACTIVE',
  PassState.expired: 'EXPIRED',
  PassState.inactive: 'INACTIVE',
  PassState.completed: 'COMPLETED',
};

const _$PassTypeEnumMap = {
  PassType.generic: 'generic',
  PassType.eventTicket: 'eventTicket',
  PassType.transit: 'transit',
  PassType.offer: 'offer',
  PassType.loyalty: 'loyalty',
  PassType.giftCard: 'giftCard',
};
