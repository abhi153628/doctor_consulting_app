import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PatientBookingsPage extends StatefulWidget {
  const PatientBookingsPage({super.key});

  @override
  State<PatientBookingsPage> createState() => _PatientBookingsPageState();
}

class _PatientBookingsPageState extends State<PatientBookingsPage> {
  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    context.read<BookingBloc>().add(GetPatientBookingsEvent(user.id));
    context.read<DoctorBloc>().add(const GetDoctorsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, bookingState) {
          if (bookingState is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (bookingState is BookingsLoaded) {
            if (bookingState.bookings.isEmpty) {
              return const Center(child: Text('No bookings found'));
            }
            return BlocBuilder<DoctorBloc, DoctorState>(
              builder: (context, doctorState) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookingState.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookingState.bookings[index];
                    String doctorName = 'Doctor';
                    if (doctorState is DoctorsLoaded) {
                      DoctorEntity? doctor;
                      for (final d in doctorState.doctors) {
                        if (d.id == booking.doctorId) {
                          doctor = d;
                          break;
                        }
                      }
                      if (doctor != null) doctorName = doctor.name;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey[200] ?? Colors.grey,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  doctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                _buildStatusChip(booking.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(booking.startTime),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'hh:mm a',
                                  ).format(booking.startTime),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (booking.status == BookingStatus.accepted) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatPage(
                                              chatId:
                                                  '${booking.userId}_${booking.doctorId}',
                                              receiverName: doctorName,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.chat_outlined),
                                      label: const Text('Chat'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Start Call
                                      },
                                      icon: const Icon(Icons.videocam),
                                      label: const Text('Call'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (bookingState is BookingError) {
            return Center(child: Text(bookingState.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.accepted:
        color = Colors.green;
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        break;
      case BookingStatus.cancelled:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
