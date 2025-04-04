import 'package:firedart/firedart.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:voxy_stk_push/models.dart';
import 'package:voxy_stk_push/task_result.dart';

import 'firebase_models.dart';

abstract class TripPaymentRepository {
  Future<TaskResult<TripMpesaLog>> setRequest({
    required TripMpesaPaymentRequest request,
  });

  Future<TaskResult<TripMpesaLog>> setResponse({
    required TripMpesaPaymentResponse response,
  });
}

class FirestoreTripPaymentRepository implements TripPaymentRepository {
  CollectionReference get tripMpesaLogCollection =>
      Firestore.instance.collection("trip_mpesa_log");

  FirestoreTripPaymentRepository({
    required String projectId,
  }) {
    Firestore.initialize(projectId);
  }

  @override
  Future<TaskResult<TripMpesaLog>> setRequest({
    required TripMpesaPaymentRequest request,
  }) async {

    try {
      TripMpesaLog tripLog = TripMpesaLog(
        paymentId: request.checkoutRequestId,
        tripId: request.account,
        request: request,
        response: null,
      );
      await tripMpesaLogCollection
          .document(tripLog.paymentId)
          .set(tripLog.toJson());

      return Success(tripLog);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }

  @override
  Future<TaskResult<TripMpesaLog>> setResponse({
    required TripMpesaPaymentResponse response,
  }) async {
    try {
      var result = await tripMpesaLogCollection
          .document(response.checkoutRequestId)
          .get();

      TripMpesaLog trip = TripMpesaLog.fromJson(result.map);
      trip.response = response;

      await tripMpesaLogCollection
          .document(trip.paymentId)
          .set(trip.toJson());

      return Success(trip);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }
}
