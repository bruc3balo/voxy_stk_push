import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class MpesaCredentials {
  final String key;
  final String sec;
  final String callbackUrl;
  final int shortCode;
  final String account;
  final String passKey;

  const MpesaCredentials({
    required this.key,
    required this.sec,
    required this.callbackUrl,
    required this.shortCode,
    required this.account,
    required this.passKey,
  });

  factory MpesaCredentials.fromJson(Map<String, dynamic> json) => _$MpesaCredentialsFromJson(json);

  Map<String, dynamic> toJson() => _$MpesaCredentialsToJson(this);


  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable()
class StkCallbackResponse {

  @JsonKey(name: 'Body')
  final Body body;

  StkCallbackResponse({required this.body});

  factory StkCallbackResponse.fromJson(Map<String, dynamic> json) => _$StkCallbackResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StkCallbackResponseToJson(this);

}

@JsonSerializable()
class Body {
  @JsonKey(name: 'stkCallback')
  final StkCallback stkCallback;

  Body({required this.stkCallback});

  factory Body.fromJson(Map<String, dynamic> json) => _$BodyFromJson(json);

  Map<String, dynamic> toJson() => _$BodyToJson(this);

}

@JsonSerializable()
class StkCallback {

  @JsonKey(name: 'MerchantRequestID')
  final String merchantRequestID;

  @JsonKey(name: 'CheckoutRequestID')
  final String checkoutRequestID;

  @JsonKey(name: 'ResultCode')
  final int resultCode;

  @JsonKey(name: 'ResultDesc')
  final String resultDesc;

  @JsonKey(name: 'CallbackMetadata')
  final CallbackMetadata? callbackMetadata;


  StkCallback({
    required this.merchantRequestID,
    required this.checkoutRequestID,
    required this.resultCode,
    required this.resultDesc,
    required this.callbackMetadata,
  });

  factory StkCallback.fromJson(Map<String, dynamic> json) => _$StkCallbackFromJson(json);
  Map<String, dynamic> toJson() => _$StkCallbackToJson(this);

}


@JsonSerializable()
class CallbackMetadata {

  @JsonKey(name: 'Item')
  final List<Item> item;

  CallbackMetadata({required this.item});

  factory CallbackMetadata.fromJson(Map<String, dynamic> json) => _$CallbackMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$CallbackMetadataToJson(this);


  Map<String, dynamic> get itemMap => {for (var i in item) i.name : i.value};

}

@JsonSerializable()
class Item {

  @JsonKey(name: 'Name')
  final String name;

  @JsonKey(name: 'Value')
  dynamic value;

  Item({required this.name, required this.value});

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);


}

enum PaymentStatus {
  paid,
  notPaid,
}
