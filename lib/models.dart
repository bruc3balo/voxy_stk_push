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
class MpesaStkPushRequest {
  @JsonKey(name: 'BusinessShortCode')
  final String businessShortCode;

  @JsonKey(name: 'Password')
  final String password;

  @JsonKey(name: 'Timestamp')
  final String timestamp;

  @JsonKey(name: 'TransactionType')
  final String transactionType;

  @JsonKey(name: 'Amount')
  final int amount;

  @JsonKey(name: 'PartyA')
  final String partyA;

  @JsonKey(name: 'PartyB')
  final String partyB;

  @JsonKey(name: 'PhoneNumber')
  final String phoneNumber;

  @JsonKey(name: 'CallBackURL')
  final String callBackURL;

  @JsonKey(name: 'AccountReference')
  final String accountReference;

  @JsonKey(name: 'TransactionDesc')
  final String transactionDesc;

  MpesaStkPushRequest({
    required this.businessShortCode,
    required this.password,
    required this.timestamp,
    this.transactionType = 'CustomerPayBillOnline',
    required this.amount,
    required this.partyA,
    required this.partyB,
    required this.phoneNumber,
    required this.callBackURL,
    required this.accountReference,
    required this.transactionDesc,
  });

  factory MpesaStkPushRequest.fromJson(Map<String, dynamic> json) {
    return MpesaStkPushRequest(
      businessShortCode: json['BusinessShortCode'],
      password: json['Password'],
      timestamp: json['Timestamp'],
      transactionType: json['TransactionType'],
      amount: json['Amount'],
      partyA: json['PartyA'],
      partyB: json['PartyB'],
      phoneNumber: json['PhoneNumber'],
      callBackURL: json['CallBackURL'],
      accountReference: json['AccountReference'],
      transactionDesc: json['TransactionDesc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BusinessShortCode': businessShortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': transactionType,
      'Amount': amount,
      'PartyA': partyA,
      'PartyB': partyB,
      'PhoneNumber': phoneNumber,
      'CallBackURL': callBackURL,
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc,
    };
  }

  // factory MpesaStkPushRequest.fromJson(Map<String, dynamic> json) =>
  //     _$MpesaStkPushRequestFromJson(json);
  //
  // Map<String, dynamic> toJson() => _$MpesaStkPushRequestToJson(this);
}

class MpesaPaymentResponse {
  final String merchantRequestID;
  final String checkoutRequestID;
  final String responseCode;
  final String responseDescription;
  final String customerMessage;

  MpesaPaymentResponse({
    required this.merchantRequestID,
    required this.checkoutRequestID,
    required this.responseCode,
    required this.responseDescription,
    required this.customerMessage,
  });

  factory MpesaPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MpesaPaymentResponse(
      merchantRequestID: json['MerchantRequestID'] as String,
      checkoutRequestID: json['CheckoutRequestID'] as String,
      responseCode: json['ResponseCode'] as String,
      responseDescription: json['ResponseDescription'] as String,
      customerMessage: json['CustomerMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MerchantRequestID': merchantRequestID,
      'CheckoutRequestID': checkoutRequestID,
      'ResponseCode': responseCode,
      'ResponseDescription': responseDescription,
      'CustomerMessage': customerMessage,
    };
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
