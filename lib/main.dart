import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:voxy_stk_push/firebase_models.dart';
import 'package:voxy_stk_push/firestore_db.dart';
import 'package:voxy_stk_push/task_result.dart';

import 'daraja.dart';
import 'models.dart';

bool firebaseInit = false;

const Map<String, String> defaultHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, PATCH, POST",
  "Access-Control-Allow-Headers": "Origin, Content-Type",
};

MpesaCredentials credentialsFromEnv(final context, {required String account}) {
  String key = Platform.environment['CONSUMER_KEY']!;
  String sec = Platform.environment['CONSUMER_SECRET']!;
  String callbackUrl = Platform.environment['CALLBACK_URL']!;
  int shortCode = int.parse(Platform.environment['SHORT_CODE']!);
  String passKey = Platform.environment['PASS_KEY']!;
  return MpesaCredentials(
    key: key,
    sec: sec,
    callbackUrl: callbackUrl,
    shortCode: shortCode,
    account: account,
    passKey: passKey,
  );
}

const ({String prefix, int length}) prefix10 = (prefix: '0', length: 10);
const ({String prefix, int length}) prefix254 = (prefix: '254', length: 12);
const lengthError = 'Invalid number length';

enum HttpMethods {
  get('GET'),
  post('POST'),
  patch('PATCH'),
  options('OPTIONS');

  final String method;

  const HttpMethods(this.method);

  static HttpMethods? findByMethod(String? method) {
    if (method == null) return null;
    return HttpMethods.values
        .where((e) => e.method.toUpperCase() == method.toUpperCase())
        .firstOrNull;
  }
}

Future<dynamic> main(final context) async {
  try {
    context.log('==== Request received ====');

    var req = context.req;
    var res = context.res;

    logRequest(context);

    TripPaymentRepository repository = FirestoreTripPaymentRepository(
      projectId: Platform.environment['FIREBASE_PROJECT_ID']!,
    );

    var method = HttpMethods.findByMethod(context.req.method);
    switch (method) {
      case HttpMethods.options:
        context.log("OPTIONS REQUEST");

        return res.send('Options', 200, defaultHeaders);
      case HttpMethods.patch:
        context.log("PATCH REQUEST");
        break;

      case HttpMethods.get:
        context.log("SENDING STK REQUEST");

        Map<String, dynamic> params =
            jsonDecode(json.encode(req.query)) as Map<String, dynamic>;

        String? account = params['account'] as String?;
        if (account == null) {
          res.send('Account required', 400, defaultHeaders);
          return;
        }

        context.log("account = ${account}");

        final MpesaCredentials credentials = credentialsFromEnv(
          context,
          account: account,
        );
        context.log("MPESA_CREDENTIALS => ${credentials.toString()}");

        String? amount = params['amount'] as String?;
        if (amount == null) {
          res.send('Amount required', 400, defaultHeaders);
          return;
        }

        String? number = params['number'] as String?;
        if (number == null) {
          res.send('Number required', 400, defaultHeaders);
          return;
        }

        String? description = params['description'] as String?;
        description ??= 'Trip payment';


        TaskResult<Map<String, dynamic>> stkResult = await sentStkPush(
          amount: int.parse(amount),
          number: number,
          passKey: credentials.passKey,
          description: description,
          account: credentials.account,
          consumerKey: credentials.key,
          consumerSecret: credentials.sec,
          businessShortCode: credentials.shortCode,
          callbackUrl: credentials.callbackUrl,
          onLog: (s) => context.log(s),
        );

        switch (stkResult) {
          case Success<Map<String, dynamic>>():
            TripPaymentRepository repository = FirestoreTripPaymentRepository(
              projectId: Platform.environment['FIREBASE_PROJECT_ID']!,
            );

            MpesaPaymentResponse response =
                MpesaPaymentResponse.fromJson(stkResult.data);

            TaskResult<TripMpesaLog> mpesaLog = await repository.setRequest(
              request: TripMpesaPaymentRequest(
                checkoutRequestId: response.checkoutRequestID,
                merchantRequestId: response.merchantRequestID,
                responseCode: response.responseCode,
                account: account,
                amount: amount,
                phoneNumber: number,
              ),
            );
            switch (mpesaLog) {
              case Success<TripMpesaLog>():
                return res.json(response.toJson(), 200, defaultHeaders);
              case Error<TripMpesaLog>():
                context.error(mpesaLog.errorMessage.toString());
                res.send(mpesaLog.errorMessage.toString(), 400, defaultHeaders);
                break;
            }
          case Error<Map<String, dynamic>>():
            context.error(stkResult.errorMessage.toString());
            res.send(stkResult.errorMessage.toString(), 400, defaultHeaders);
            return;
        }

      case HttpMethods.post:
        String jsonString = json.encode(context.req.body);
        context.log(jsonString);

        var jdec = jsonDecode(jsonString);
        context.log('$jdec & ${jdec.runtimeType.toString()}');

        Map<String, dynamic> jsonMap = jdec as Map<String, dynamic>;

        context.log("JSON MAP => ${jsonMap.toString()}");
        StkCallbackResponse stkCallbackResponse =
            StkCallbackResponse.fromJson(jsonMap);

        context.log(
            "STK CALLBACK RES => ${stkCallbackResponse.toJson().toString()}");

        Body body = stkCallbackResponse.body;
        StkCallback callback = body.stkCallback;

        context.log("STK CALLBACK => ${callback.toJson().toString()}");

        bool success = callback.resultCode == 0;
        String paymentId = callback.checkoutRequestID;



        TaskResult<TripMpesaLog> responseResult = await repository.setResponse(
          response: TripMpesaPaymentResponse(
            checkoutRequestId: callback.checkoutRequestID,
            merchantRequestId: callback.merchantRequestID,
            responseCode: "${callback.resultCode}",
            amount: "${callback.callbackMetadata?.itemMap['Amount']}",
            receipt: callback.callbackMetadata?.itemMap['MpesaReceiptNumber'],
          ),
        );
        switch (responseResult) {
          case Success<TripMpesaLog>():
            return res.send(
              'Request Completed Successfully',
              200,
              defaultHeaders,
            );
          case Error<TripMpesaLog>():
            return res.send(
              responseResult.errorMessage.toString(),
              404,
              defaultHeaders,
            );
        }

      case _:
        context.error('Method not supported $method');
        return;
    }

    context.log(' ==== Request Completed Successfully ==== ');
    return res.send('Request Completed Successfully', 200, defaultHeaders);
  } on AppwriteException catch (e, trace) {
    context.log(' ==== AppWrite Exceptions ==== ');

    String error = createLogException(
        message: e.message, type: e.runtimeType, trace: trace);
    context.error(error);

    context.log(' ==== END ==== ');
    return context.res.send(e.toString(), 500, defaultHeaders);
  } catch (e, trace) {
    context.log(' ==== Generic Exceptions ==== ');

    String error = createLogException(
        message: e.toString(), type: e.runtimeType, trace: trace);
    context.error(error);

    context.log(' ==== END ==== ');
    return context.res.send(e.toString(), 500, defaultHeaders);
  }
}

String createLogException({String? message, Type? type, StackTrace? trace}) {
  return 'Message => $message\nType => ${type?.toString()}\nTrace => ${trace.toString()}';
}

Future<TaskResult<Map<String, dynamic>>> sentStkPush({
  required int amount,
  required String number,
  required String passKey,
  required String description,
  required String consumerKey,
  required String consumerSecret,
  required String account,
  required int businessShortCode,
  required String callbackUrl,
  Function(String)? onLog,
  Function()? onSuccess,
}) async {
  TaskResult<String> accessTokenResult = await authenticate(
    consumerKey: consumerKey,
    consumerSecret: consumerSecret,
  );
  switch (accessTokenResult) {
    case Success<String>():
      onLog?.call("Request Authenticated");

      String phoneNumber = number.toString();

      if (!phoneNumber.startsWith(prefix254.prefix) &&
          !phoneNumber.startsWith(prefix10.prefix)) {
        return Error(Exception("Invalid number $number"));
      }

      if (phoneNumber.startsWith(prefix10.prefix)) {
        if (phoneNumber.length != prefix10.length) {
          return Error(Exception(lengthError));
        }

        phoneNumber =
            phoneNumber.replaceFirst(prefix10.prefix, prefix254.prefix);
      }
      if (phoneNumber.startsWith(prefix254.prefix) &&
          phoneNumber.length != prefix254.length) {
        return Error(Exception(lengthError));
      }

      onLog?.call("Requesting stk push");

      TaskResult<Map<String, dynamic>> stkRes = await initiateStkPush(
        accessToken: accessTokenResult.data,
        amount: amount,
        businessShortCode: businessShortCode,
        passKey: passKey,
        phoneNumber: phoneNumber,
        callbackUrl: callbackUrl,
        account: account,
        description: description,
      );

      switch (stkRes) {
        case Success<Map<String, dynamic>>():
          onLog?.call("Stk Push initiated");
          return Success(stkRes.data);
        case Error<Map<String, dynamic>>():
          return Error(stkRes.errorMessage);
      }
    case Error<String>():
      return Error(accessTokenResult.errorMessage);
  }
}

void logRequest(context) {
  var req = context.req;

  // Raw request body, contains request data
  context.log('Body => ${req.bodyRaw}');

  // Object from parsed JSON request body, otherwise string
  context.log("JSON BODY => ${json.encode(context.req.body)}");

  // String key-value pairs of all request headers, keys are lowercase
  context.log("HEADERS => ${json.encode(req.headers)}");

  // Value of the x-forwarded-proto header, usually http or https
  context.log("SCHEME => ${req.scheme}");
  // Request method, such as GET, POST, PUT, DELETE, PATCH, etc.
  context.log("METHOD => ${req.method}");

  // Full URL, for example: http://awesome.appwrite.io:8000/v1/hooks?limit=12&offset=50
  context.log("URI => ${req.url}");

  // Hostname from the host header, such as awesome.appwrite.io
  context.log('Host => ${context.req.host}');

  // Port from the host header, for example 8000
  context.log("PORT => ${req.port}");

  // Path part of URL, for example /v1/hooks
  context.log('PATH => ${req.path}');

  // Raw query params string. For example "limit=12&offset=50"
  context.log("QUERY => ${req.queryString}");

  Map<String, dynamic> params =
      jsonDecode(json.encode(req.query)) as Map<String, dynamic>;

  context.log("QUERY => $params");

  context.log("REQUEST HAS BEEN LOGGED");
}
