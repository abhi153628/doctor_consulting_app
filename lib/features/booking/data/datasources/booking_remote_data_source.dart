import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../../core/services/notification_service.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> bookAppointment(BookingModel booking);
  Stream<List<BookingModel>> getPatientBookings(String userId);
  Stream<List<BookingModel>> getDoctorBookings(String doctorId);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<List<BookingModel>> getAllBookings();
  Stream<List<BookingModel>> getAllBookingsStream();
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;

  BookingRemoteDataSourceImpl({required this.firestore});

  String _slotKey(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime12h(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }

  @override
  Future<BookingModel> bookAppointment(BookingModel booking) async {
    final String targetSlotKey = _slotKey(booking.startTime);
    debugPrint('=== BOOKING ATTEMPT ===');
    debugPrint('Looking for slot: $targetSlotKey');
    debugPrint('Doctor ID: ${booking.doctorId}');
    debugPrint('User ID: ${booking.userId}');

    return await firestore.runTransaction((transaction) async {
      final doctorRef = firestore.collection('doctors').doc(booking.doctorId);
      final bookingRef = firestore.collection('bookings').doc();

      final doctorDoc = await transaction.get(doctorRef);
      if (!doctorDoc.exists) {
        throw Exception('Doctor not found. Please go back and try again.');
      }

      final List<String> rawSlots = List<String>.from(
        doctorDoc.data()?['availableTimeSlots'] ?? [],
      );
      debugPrint('Doctor has slots: $rawSlots');

      String? matchedSlot;
      for (final s in rawSlots) {
        final normalized = s
            .toUpperCase()
            .replaceAll(' AM', '')
            .replaceAll(' PM', '')
            .trim();
        if (normalized == targetSlotKey) {
          matchedSlot = s;
          break;
        }
      }

      debugPrint('Matched slot: $matchedSlot');

      if (matchedSlot == null) {
        throw Exception('SLOT_NOT_FOUND:$targetSlotKey:${rawSlots.join(",")}');
      }

      final startOfDay = DateTime(
        booking.startTime.year,
        booking.startTime.month,
        booking.startTime.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingSnap = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: booking.userId)
          .where('doctorId', isEqualTo: booking.doctorId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      final todayBookings = existingSnap.docs.where((doc) {
        final raw = doc.data()['startTime'];
        DateTime? dt;
        if (raw is Timestamp) {
          dt = raw.toDate();
        } else if (raw is String) {
          dt = DateTime.tryParse(raw);
        }
        if (dt == null) return false;
        return dt.isAfter(startOfDay) && dt.isBefore(endOfDay);
      }).toList();

      debugPrint('Existing bookings today: ${todayBookings.length}');

      if (todayBookings.length >= 2) {
        throw Exception(
          'MAX_BOOKINGS:You already have 2 appointments with this doctor today.',
        );
      }

      final updatedSlots = List<String>.from(rawSlots)..remove(matchedSlot);
      transaction.update(doctorRef, {'availableTimeSlots': updatedSlots});

      final data = {
        'id': bookingRef.id,
        'doctorId': booking.doctorId,
        'userId': booking.userId,
        'doctorName': booking.doctorName,
        'patientName': booking.patientName,
        'startTime': Timestamp.fromDate(booking.startTime),
        'endTime': Timestamp.fromDate(booking.endTime),
        'durationMinutes': booking.durationMinutes,
        'totalAmount': booking.totalAmount,
        'commission': booking.commission,
        'doctorEarning': booking.doctorEarning,
        'status': booking.status.name,
      };
      transaction.set(bookingRef, data);

      NotificationService.sendNotification(
        receiverIds: [booking.doctorId],
        title: 'New Appointment Booking!',
        content:
            '${booking.patientName} has booked a slot for ${_formatTime12h(booking.startTime)}',
        data: {'type': 'new_booking', 'bookingId': bookingRef.id},
      );

      return BookingModel(
        id: bookingRef.id,
        doctorId: booking.doctorId,
        userId: booking.userId,
        startTime: booking.startTime,
        endTime: booking.endTime,
        durationMinutes: booking.durationMinutes,
        totalAmount: booking.totalAmount,
        commission: booking.commission,
        doctorEarning: booking.doctorEarning,
        doctorName: booking.doctorName,
        patientName: booking.patientName,
        status: booking.status,
      );
    });
  }

  @override
  Stream<List<BookingModel>> getPatientBookings(String userId) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<BookingModel>> getDoctorBookings(String doctorId) {
    return firestore
        .collection('bookings')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final bookingDoc = await firestore
        .collection('bookings')
        .doc(bookingId)
        .get();
    if (!bookingDoc.exists) return;

    final bookingData = bookingDoc.data();
    if (bookingData == null) return;

    final Map<String, dynamic> updates = {'status': status.name};

    if (status == BookingStatus.accepted) {
      updates['totalAmount'] = 100.0;
      updates['commission'] = 20.0;
      updates['doctorEarning'] = 80.0;
    }

    await firestore.collection('bookings').doc(bookingId).update(updates);

    if (status == BookingStatus.accepted) {
      NotificationService.sendNotification(
        receiverIds: [bookingData['userId']],
        title: 'Booking Confirmed!',
        content:
            'Dr. ${bookingData['doctorName']} has accepted your booking request.',
        data: {'type': 'booking_accepted', 'bookingId': bookingId},
      );
    }
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    final snapshot = await firestore.collection('bookings').get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }

  /// Real-time stream of ALL bookings — used by admin to monitor all activity.
  @override
  Stream<List<BookingModel>> getAllBookingsStream() {
    return firestore.collection('bookings').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
      // Sort client-side — newest first (avoids Firestore composite index requirement)
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }
}
