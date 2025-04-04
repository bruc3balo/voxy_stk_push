class TripMpesaLog {
  final String paymentId;
  final String tripId;
  final TripMpesaPaymentRequest request;
  TripMpesaPaymentResponse? response;

  TripMpesaLog({
    required this.paymentId,
    required this.tripId,
    required this.request,
    required this.response,
  });

  factory TripMpesaLog.fromJson(Map<String, dynamic> json) {
    return TripMpesaLog(
      paymentId: json['paymentId'] ?? '',
      tripId: json['tripId'] ?? '',
      request: TripMpesaPaymentRequest.fromJson(json['request'] ?? {}),
      response: json['response'] != null
          ? TripMpesaPaymentResponse.fromJson(json['response'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'tripId': tripId,
      'request': request.toJson(),
      'response': response?.toJson(), // Will be null if no response yet
    };
  }
}


class TripMpesaPaymentRequest {
  final String checkoutRequestId;
  final String merchantRequestId;
  final String responseCode;
  final String account;
  final String amount;
  final String phoneNumber;

  TripMpesaPaymentRequest({
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.responseCode,
    required this.account,
    required this.amount,
    required this.phoneNumber,
  });

  factory TripMpesaPaymentRequest.fromJson(Map<String, dynamic> json) {
    return TripMpesaPaymentRequest(
      checkoutRequestId: json['CheckoutRequestID'] ?? '',
      merchantRequestId: json['MerchantRequestID'] ?? '',
      responseCode: json['ResponseCode'] ?? '',
      account: json['Account'] ?? '',
      amount: json['Amount'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CheckoutRequestID': checkoutRequestId,
      'MerchantRequestID': merchantRequestId,
      'ResponseCode': responseCode,
      'Account': account,
      'Amount': amount,
      'PhoneNumber': phoneNumber,
    };
  }
}

class TripMpesaPaymentResponse {
  final String checkoutRequestId;
  final String merchantRequestId;
  final String responseCode;
  final String amount;
  final String receipt;

  TripMpesaPaymentResponse({
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.responseCode,
    required this.amount,
    required this.receipt,
  });

  factory TripMpesaPaymentResponse.fromJson(Map<String, dynamic> json) {
    return TripMpesaPaymentResponse(
      checkoutRequestId: json['CheckoutRequestID'] ?? '',
      merchantRequestId: json['MerchantRequestID'] ?? '',
      responseCode: json['ResponseCode'] ?? '',
      amount: json['Amount'] ?? '',
      receipt: json['MpesaReceiptNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CheckoutRequestID': checkoutRequestId,
      'MerchantRequestID': merchantRequestId,
      'ResponseCode': responseCode,
      'Amount': amount,
      'MpesaReceiptNumber': receipt,
    };
  }
}
