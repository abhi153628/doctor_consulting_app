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
    final docRef = firestore.collection('bookings').doc();
    final bookingWithId = BookingModel(
      id: docRef.id,
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
    await docRef.set(bookingWithId.toJson());
    return bookingWithId;
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
