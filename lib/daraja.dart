import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

Dio dio = Dio(BaseOptions(baseUrl: 'https://sandbox.safaricom.co.ke/'));

///Initiate stk push with access token from [authenticate]
Future<Map<String, dynamic>?> initiateStkPush({
  required String accessToken,
  required int amount,
  required int businessShortCode,
  required String passKey,
  required String phoneNumber,
  required String callbackUrl,
  required String account,
  required String description,
  Function(String)? onError,
}) async {
  String time = timeStamp;
  String pass = password(
    businessShortCode: businessShortCode,
    passKey: passKey,
    timeStamp: time,
  );
  pass = encodeToBase64(pass);

  Map<String, dynamic> body = {
    'BusinessShortCode': businessShortCode,
    'Password': pass,
    'Timestamp': time,
    'TransactionType': 'CustomerPayBillOnline',
    'Amount': amount,
    'PartyA': phoneNumber,
    'PartyB': businessShortCode,
    'PhoneNumber': phoneNumber,
    'CallBackURL': callbackUrl,
    'AccountReference': account,
    'TransactionDesc': description,
  };

  Response res = await dio.post(
    'mpesa/stkpush/v1/processrequest',
    data: body,
    options: Options(
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ),
  );

  if (res.statusCode != 200) {
    onError?.call(res.statusMessage ?? 'Failed to send stk push');
    return null;
  }

  Map<String, dynamic> data = res.data;
  return data;
}

///Daraja authentication to get access token
Future<String?> authenticate({
  required String consumerKey,
  required String consumerSecret,
  Function(String)? onError,
}) async {
  String cred = authCredentials(
    consumerKey: consumerKey,
    consumerSecret: consumerSecret,
  );
  String basicToken = encodeToBase64(cred);
  String authorization = 'Basic $basicToken';

  Response res = await dio.get(
    'oauth/v1/generate',
    queryParameters: {
      'grant_type': 'client_credentials',
    },
    options: Options(
      headers: {
        'Authorization': authorization,
      },
    ),
  );

  if (res.statusCode != 200) {
    onError?.call(res.statusMessage ?? 'Failed to authenticate daraja request');
    return null;
  }

  var data = res.data as Map<String, dynamic>;
  return data['access_token'];
}

String authCredentials({
  required String consumerKey,
  required String consumerSecret,
}) =>
    '$consumerKey:$consumerSecret';

String password({
  required int businessShortCode,
  required String passKey,
  required String timeStamp,
}) =>
    '$businessShortCode$passKey$timeStamp';

String encodeToBase64(String s) => base64.encode(utf8.encode(s));

String get timeStamp => DateFormat('yyyyMMddHHmmss').format(DateTime.now());
