import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../../domain/entities/booking_entity.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> bookAppointment(BookingModel booking);
  Future<List<BookingModel>> getPatientBookings(String userId);
  Future<List<BookingModel>> getDoctorBookings(String doctorId);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<List<BookingModel>> getAllBookings();
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;

  BookingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<BookingModel> bookAppointment(BookingModel booking) async {
    return await firestore.runTransaction((transaction) async {
      final doctorRef = firestore.collection('doctors').doc(booking.doctorId);
      final bookingRef = firestore.collection('bookings').doc();

      final doctorDoc = await transaction.get(doctorRef);
      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final List<String> slots = List<String>.from(
        doctorDoc.data()?['availableTimeSlots'] ?? [],
      );

      // We need to find the specific slot to remove.
      // For now, we match by the formatted time string if that's what's stored.
      // In a more robust system, we would match by exact DateTime.

      // Attempting to remove the slot.
      // Note: This logic assumes slots are stored as "HH:mm" strings or similar.
      // If the exact string isn't found, we'll still proceed with the booking
      // but log/warn if this were a production system.
      // For this implementation, we'll expect the string to match exactly as picked in the UI.

      // In the current UI, slot is just a String.
      // We'll pass the specific slot string to remove via a custom field or infer it.
      // Let's assume for now the startTime matches the slot string format (e.g. 10:30 AM).
      // Since startTime is parsed from the slot, we should ideally pass the slot string.

      // Let's refine the model to include the original slot string if needed,
      // or just try to find a matching one.

      // Optimization: remove matching slot from the list
      // In a real app, we'd use a more precise slot ID.

      // For now, let's keep it simple: we remove the first slot that roughly matches the hour/minute.
      // Actually, let's just use the startTime to find a match.

      // Re-reading common slot formats: "10:30 AM"
      // [NEW] Date-specific booking check in backend for safety
      final startOfDay = DateTime(
        booking.startTime.year,
        booking.startTime.month,
        booking.startTime.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingBookings = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: booking.userId)
          .where('doctorId', isEqualTo: booking.doctorId)
          .where('status', whereIn: ['pending', 'accepted'])
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .where('startTime', isLessThan: endOfDay)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        throw Exception(
          'You already have an appointment with this doctor today.',
        );
      }

      final String standardSlot = _formatToStandardSlot(booking.startTime);

      if (!slots.contains(standardSlot)) {
        throw Exception(
          'Slot mismatch: Looking for "$standardSlot", but doctor has ${slots.isEmpty ? "NO SLOTS" : "only: " + slots.join(", ")}. Please refresh.',
        );
      }

      slots.remove(standardSlot);

      transaction.update(doctorRef, {'availableTimeSlots': slots});

      final bookingWithId = BookingModel(
        id: bookingRef.id,
        doctorId: booking.doctorId,
        userId: booking.userId,
        startTime: booking.startTime,
        endTime: booking.endTime,
        durationMinutes: booking.durationMinutes,
        totalAmount: booking.totalAmount,
        commission: booking.commission,
        doctorEarning: booking.doctorEarning,
        status: booking.status,
      );

      transaction.set(bookingRef, bookingWithId.toJson());

      return bookingWithId;
    });
  }

  String _formatToStandardSlot(DateTime dt) {
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Future<List<BookingModel>> getPatientBookings(String userId) async {
    final snapshot = await firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<BookingModel>> getDoctorBookings(String doctorId) async {
    final snapshot = await firestore
        .collection('bookings')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await firestore.collection('bookings').doc(bookingId).update({
      'status': status.name,
    });
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    final snapshot = await firestore.collection('bookings').get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }
}
