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
}

class FirestoreTripPaymentRepository implements TripPaymentRepository {
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
}
