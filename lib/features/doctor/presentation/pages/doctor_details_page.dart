import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/pages/call_page.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailsPage extends StatefulWidget {
  final DoctorEntity doctor;
  const DoctorDetailsPage({super.key, required this.doctor});

  @override
  State<DoctorDetailsPage> createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  String? _selectedSlot;
  late DoctorEntity _doctor;

  String _formatForDisplaySlot(String standardTime) {
    try {
      final parts = standardTime.split(':');
      final time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      return time.format(context);
    } catch (e) {
      return standardTime;
    }
  }

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
    context.read<DoctorBloc>().add(GetDoctorProfileEvent(_doctor.id));

    // Fetch bookings to check for the 'one booking' rule
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
        GetPatientBookingsEvent(authState.user.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorBloc, DoctorState>(
      builder: (context, state) {
        if (state is DoctorProfileLoaded) {
          _doctor = state.doctor;
        }

        final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

        return Scaffold(
          appBar: AppBar(title: Text(_doctor.name)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withAlpha(25),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctor.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _doctor.specialization,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _doctor.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _doctor.isOnline ? 'Available' : 'Offline',
                                style: TextStyle(
                                  color: _doctor.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const _PolicyInfoCard(),
                const SizedBox(height: 32),
                const Text(
                  'Select Time Slot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_doctor.availableTimeSlots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No slots available for today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _doctor.availableTimeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _doctor.availableTimeSlots[index];
                      final isSelected = _selectedSlot == slot;
                      final isDimmed = _selectedSlot != null && !isSelected;
                      final isLoading =
                          context.watch<BookingBloc>().state is BookingLoading;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isDimmed ? 0.4 : 1.0,
                        child: InkWell(
                          onTap: isLoading
                              ? null
                              : () => setState(
                                  () =>
                                      _selectedSlot = isSelected ? null : slot,
                                ),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _formatForDisplaySlot(slot),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 40),
                BlocConsumer<BookingBloc, BookingState>(
                  listener: (context, state) {
                    if (state is BookingSuccess) {
                      _showSuccessDialog();
                    } else if (state is BookingError) {
                      _showAvailabilityDialog(state.message);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is BookingLoading;
                    bool alreadyBooked = false;

                    if (state is BookingsLoaded) {
                      final now = DateTime.now();
                      final todayBookings = state.bookings
                          .where(
                            (b) =>
                                b.doctorId == _doctor.id &&
                                b.startTime.year == now.year &&
                                b.startTime.month == now.month &&
                                b.startTime.day == now.day &&
                                (b.status == BookingStatus.pending ||
                                    b.status == BookingStatus.accepted),
                          )
                          .toList();
                      // Allow up to 2 appointments per day per doctor
                      alreadyBooked = todayBookings.length >= 2;
                    }

                    return AbsorbPointer(
                      absorbing: isLoading,
                      child: BlocListener<CallBloc, CallState>(
                        listener: (context, state) {
                          if (state is CallDialing) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CallPage(
                                  channelId: state.call.channelName,
                                  remoteName: state.call.receiverName,
                                ),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONSULTATION OPTIONS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_doctor.phoneNumber != null)
                              Row(
                                children: [
                                  _ActionButton(
                                    icon: Icons.call,
                                    label: 'Call',
                                    onPressed: () async {
                                      final Uri telLaunchUri = Uri(
                                        scheme: 'tel',
                                        path: _doctor.phoneNumber,
                                      );
                                      if (await canLaunchUrl(telLaunchUri)) {
                                        await launchUrl(telLaunchUri);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionButton(
                                    icon: Icons.videocam,
                                    label: 'Video',
                                    onPressed: () {
                                      final caller =
                                          (context.read<AuthBloc>().state
                                                  as AuthAuthenticated)
                                              .user;
                                      context.read<CallBloc>().add(
                                        InitiateCallEvent(
                                          callerId: caller.id,
                                          callerName: caller.name,
                                          receiverId: _doctor.id,
                                          receiverName: _doctor.name,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionButton(
                                    icon: Icons.chat_bubble_outline,
                                    label: 'Chat',
                                    onPressed: () {
                                      final ids = [user.id, _doctor.id]..sort();
                                      final chatId = ids.join('_');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            chatId: chatId,
                                            receiverName: _doctor.name,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _selectedSlot == null ||
                                        alreadyBooked ||
                                        isLoading
                                    ? null
                                    : () {
                                        final amount = _doctor.consultationFee;
                                        final commission = amount * 0.1;
                                        final doctorEarning =
                                            amount - commission;

                                        DateTime appointmentStart =
                                            DateTime.now();
                                        try {
                                          // SLOTS ARE ALWAYS HH:mm (24h) — directly parse
                                          final parts = _selectedSlot!.split(
                                            ':',
                                          );
                                          final int hour = int.parse(parts[0]);
                                          final int minute = int.parse(
                                            parts[1],
                                          );

                                          final now = DateTime.now();
                                          appointmentStart = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                            hour,
                                            minute,
                                          );

                                          // If this slot time is already past today, book for tomorrow
                                          if (appointmentStart.isBefore(now)) {
                                            appointmentStart = appointmentStart
                                                .add(const Duration(days: 1));
                                          }
                                        } catch (e) {
                                          debugPrint('Error parsing slot: $e');
                                        }

                                        final booking = BookingEntity(
                                          id: '',
                                          doctorId: _doctor.id,
                                          userId: user.id, doctorName: _doctor.name, patientName: user.name,
                                          startTime: appointmentStart,
                                          endTime: appointmentStart.add(
                                            const Duration(minutes: 30),
                                          ),
                                          durationMinutes: 30,
                                          totalAmount: amount,
                                          commission: commission,
                                          doctorEarning: doctorEarning,
                                        );
                                        context.read<BookingBloc>().add(
                                          BookAppointmentEvent(booking),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading) ...[
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Text(
                                      isLoading
                                          ? 'Confirming Slot...'
                                          : alreadyBooked
                                          ? 'Already Booked Today'
                                          : 'Book Appointment',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Appointment Booked Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to list
              },
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvailabilityDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Availability Update'),
          ],
        ),
        content: Builder(
          builder: (context) {
            String friendlyMessage;
            if (message.contains('SLOT_NOT_FOUND') ||
                message.contains('mismatch') ||
                message.contains('not available')) {
              friendlyMessage =
                  'This time slot is not available. The doctor may have removed it. Please go back and refresh to see the latest available slots.';
            } else if (message.contains('MAX_BOOKINGS') ||
                message.contains('already have')) {
              friendlyMessage =
                  'You have reached the maximum of 2 appointments with this doctor today. Please book for another day or choose a different doctor.';
            } else if (message.contains('Doctor not found')) {
              friendlyMessage =
                  'Could not find the doctor\'s profile. Please go back and try again.';
            } else {
              friendlyMessage =
                  'Something went wrong while booking. Please check your internet connection and try again.';
            }
            return Text(friendlyMessage);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DoctorBloc>().add(GetDoctorProfileEvent(_doctor.id));
              setState(() => _selectedSlot = null);
            },
            child: const Text('Refresh Availability'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyInfoCard extends StatelessWidget {
  const _PolicyInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Booking Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'To ensure timely care for everyone, patients are limited to one appointment per doctor per day.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
