import 'package:firedart/firedart.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:voxy_stk_push/models.dart';
import 'package:voxy_stk_push/task_result.dart';

abstract class TripPaymentRepository {
  Future<TaskResult<void>> updatePayment({
    required String tripId,
    required String paymentId,
    required PaymentStatus status,
  });

  Future<TaskResult<void>> setTrip({
    required String tripId,
    required String checkoutId,
  });

  Future<TaskResult<String?>> getTripId({
    required String checkoutId,
  });
}

class FirestoreTripPaymentRepository implements TripPaymentRepository {
  CollectionReference get tripCheckoutPaymentCollection => Firestore.instance.collection("trips_checkout_map");

  CollectionReference tripPaymentCollection(String tripId) => Firestore.instance.collection("trips").document(tripId).collection('payments');

  FirestoreTripPaymentRepository({
    required String projectId,
  }) {
    Firestore.initialize(projectId);
  }

  @override
  Future<TaskResult<void>> updatePayment({
    required String tripId,
    required String paymentId,
    required PaymentStatus status,
  }) async {
    try {
      await tripPaymentCollection(tripId).document(paymentId).update(
        {
          'status': status.name,
          'updated_at': DateTime.now(),
        },
      );

      return Success(null);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }

  @override
  Future<TaskResult<String?>> getTripId({required String checkoutId}) async {
    try {
      var result = await tripCheckoutPaymentCollection.document(checkoutId).get();

      return Success(result.map['trip_id']);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }

  @override
  Future<TaskResult<void>> setTrip({required String tripId, required String checkoutId}) async {
    try {
      await tripCheckoutPaymentCollection.document(checkoutId).set(
        {
          'trip_id': tripId,
          'checkout_id': checkoutId,
        },
      );

      return Success(null);
    } catch (e, trace) {
      return Error(Exception(e));
    }
  }
}
