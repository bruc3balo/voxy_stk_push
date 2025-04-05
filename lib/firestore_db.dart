import 'package:firedart/firedart.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:voxy_stk_push/models.dart';
import 'package:voxy_stk_push/task_result.dart';

import 'firebase_models.dart';
import 'main.dart';

abstract class TripPaymentRepository {
  Future<TaskResult<TripMpesaLog>> setRequest({
    required TripMpesaPaymentRequest request,
  });

  Future<TaskResult<TripMpesaLog>> setResponse({
    required TripMpesaPaymentResponse response,
  });

  Future<TaskResult<void>> updateTripPayment({
    required String tripId,
    required String paymentId,
    required PaymentStatus status,
  });
}

class FirestoreTripPaymentRepository implements TripPaymentRepository {
  CollectionReference get tripMpesaLogCollection =>
      Firestore.instance.collection("trip_mpesa_log");

  CollectionReference tripPaymentCollection(String tripId) => Firestore.instance
      .collection('trips')
      .document(tripId)
      .collection('payments');

  FirestoreTripPaymentRepository({
    required String projectId,
  }) {
    if (!firebaseInit) {
      Firestore.initialize(projectId);
      firebaseInit = true;
    }
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

      await tripMpesaLogCollection.document(trip.paymentId).set(trip.toJson());

      return Success(trip);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }

  @override
  Future<TaskResult<void>> updateTripPayment({
    required String tripId,
    required String paymentId,
    required PaymentStatus status,
  }) async {
    try {

      await tripPaymentCollection(tripId)
          .document(paymentId)
          .update({'status': status.name});

      return Success(null);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }
}
