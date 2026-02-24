import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    context.read<BookingBloc>().add(GetDoctorBookingsEvent(user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Earnings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookingsLoaded) {
            final completedBookings = state.bookings
                .where((b) => b.status == BookingStatus.completed)
                .toList();

            double totalEarnings = 0;
            for (var b in completedBookings) {
              totalEarnings += b.doctorEarning;
            }

            return Column(
              children: [
                _buildSummaryHeader(totalEarnings, completedBookings.length),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Transaction History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: completedBookings.isEmpty
                      ? const Center(child: Text('No completed consultas yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: completedBookings.length,
                          itemBuilder: (context, index) {
                            final booking = completedBookings[index];
                            return _buildTransactionItem(booking);
                          },
                        ),
                ),
              ],
            );
          } else if (state is BookingError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double total, int count) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Total Earning',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Consultations Completed',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BookingEntity booking) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200] ?? Colors.grey),
      ),
      child: ListTile(
        title: Text(
          DateFormat('MMM dd, yyyy').format(booking.startTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Consultation fee'),
        trailing: Text(
          '₹${booking.doctorEarning.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
