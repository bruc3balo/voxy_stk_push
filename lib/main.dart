import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:voxy_stk_push/firestore_db.dart';

import 'daraja.dart';
import 'models.dart';

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
    return HttpMethods.values.where((e) => e.method.toUpperCase() == method.toUpperCase()).firstOrNull;
  }
}

Future<dynamic> main(final context) async {
  try {
    context.log('==== Request received ====');

    var req = context.req;
    var res = context.res;

    logRequest(context);

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

        Map<String, dynamic> params = jsonDecode(json.encode(req.query)) as Map<String, dynamic>;

        String tripId = params['trip_id'];

        final MpesaCredentials credentials = credentialsFromEnv(context, account: tripId);
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
        description ??= 'Donation';

        await sentStkPush(
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
          onError: (s) {
            context.error(s);
            res.send(s, 400, defaultHeaders);
          },
          onSuccess: (map) {
            // TripPaymentRepository repository = FirestoreTripPaymentRepository(
            //   projectId: Platform.environment['FIREBASE_PROJECT_ID']!,
            // );
            //
            // repository.updatePayment(
            //   tripId: tripId,
            //   paymentId: map['CheckoutRequestID'],
            //   status: PaymentStatus.waiting,
            // );

            res.send(map, 200, defaultHeaders);
          },
        );

        break;

      case HttpMethods.post:

        final String databaseId = Platform.environment['DATABASE_ID']!;
        context.log("DB id => $databaseId");

        final String collectionId = Platform.environment['COLLECTION_ID']!;
        context.log("Collection id => $collectionId");

        String jsonString = json.encode(context.req.body);
        context.log(jsonString);

        var jdec = jsonDecode(jsonString);
        context.log('$jdec & ${jdec.runtimeType.toString()}');

        Map<String, dynamic> jsonMap = jdec as Map<String, dynamic>;

        context.log("JSON MAP => ${jsonMap.toString()}");
        StkCallbackResponse stkCallbackResponse = StkCallbackResponse.fromJson(jsonMap);

        context.log("STK CALLBACK RES => ${stkCallbackResponse.toJson().toString()}");

        Body body = stkCallbackResponse.body;
        StkCallback callback = body.stkCallback;

        context.log("STK CALLBACK => ${callback.toJson().toString()}");

        bool success = callback.resultCode == 0;
        String paymentId = callback.checkoutRequestID;
        String tripId = callback.callbackMetadata?.itemMap['account'];

        TripPaymentRepository repository = FirestoreTripPaymentRepository(
          projectId: Platform.environment['FIREBASE_PROJECT_ID']!,
        );

        repository.updatePayment(
          tripId: tripId,
          paymentId: paymentId,
          status: success ? PaymentStatus.paid : PaymentStatus.notPaid,
        );
        break;

      case _:
        context.error('Method not supported $method');
        return;
    }

    context.log(' ==== Request Completed Successfully ==== ');
    return res.send('Request Completed Successfully', 200, defaultHeaders);
  } on AppwriteException catch (e, trace) {
    context.log(' ==== AppWrite Exceptions ==== ');

    String error = createLogException(message: e.message, type: e.runtimeType, trace: trace);
    context.error(error);

    context.log(' ==== END ==== ');
    return context.res.send(e.toString(), 500, defaultHeaders);
  } catch (e, trace) {
    context.log(' ==== Generic Exceptions ==== ');

    String error = createLogException(message: e.toString(), type: e.runtimeType, trace: trace);
    context.error(error);

    context.log(' ==== END ==== ');
    return context.res.send(e.toString(), 500, defaultHeaders);
  }
}

String createLogException({String? message, Type? type, StackTrace? trace}) {
  return 'Message => $message\nType => ${type?.toString()}\nTrace => ${trace.toString()}';
}

Future<void> sentStkPush({
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
  Function(String)? onError,
  Function(Map<String, dynamic>)? onSuccess,
}) async {
  String? accessToken = await authenticate(
    consumerKey: consumerKey,
    consumerSecret: consumerSecret,
    onError: (s) {
      print(s);
    },
  );
  if (accessToken == null) return;

  onLog?.call("Request Authenticated");

  String phoneNumber = number.toString();

  if (!phoneNumber.startsWith(prefix254.prefix) && !phoneNumber.startsWith(prefix10.prefix)) {
    onError?.call("Invalid number $number");
    return;
  }

  if (phoneNumber.startsWith(prefix10.prefix)) {
    if (phoneNumber.length != prefix10.length) {
      onError?.call(lengthError);
      return;
    }

    phoneNumber = phoneNumber.replaceFirst(prefix10.prefix, prefix254.prefix);
  }
  if (phoneNumber.startsWith(prefix254.prefix) && phoneNumber.length != prefix254.length) {
    onError?.call(lengthError);
    return;
  }

  Map<String, dynamic>? stkRes = await initiateStkPush(
    accessToken: accessToken,
    amount: amount,
    businessShortCode: businessShortCode,
    passKey: passKey,
    phoneNumber: phoneNumber,
    callbackUrl: callbackUrl,
    account: account,
    description: description,
    onError: onError,
  );

  if (stkRes == null) return;

  onLog?.call("Stk Push initiated");
  onSuccess?.call(stkRes);
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

  context.log("REQUEST HAS BEEN LOGGED");
}
