import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/pages/call_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(title: Text(widget.doctor.name)),
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
                        widget.doctor.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.doctor.specialization,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.doctor.availableTimeSlots.isEmpty)
              const Text('No slots available')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.doctor.availableTimeSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSlot = selected ? slot : null);
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 48),
            BlocConsumer<BookingBloc, BookingState>(
              listener: (context, state) {
                if (state is BookingSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment Booked!')),
                  );
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    if (widget.doctor.phoneNumber != null)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final Uri telLaunchUri = Uri(
                                  scheme: 'tel',
                                  path: widget.doctor.phoneNumber,
                                );
                                if (await canLaunchUrl(telLaunchUri)) {
                                  await launchUrl(telLaunchUri);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(
                                  color: AppTheme.primaryColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.call, size: 20),
                              label: const Text('Call Now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final caller =
                                      (context.read<AuthBloc>().state
                                              as AuthAuthenticated)
                                          .user;
                                  context.read<CallBloc>().add(
                                    InitiateCallEvent(
                                      callerId: caller.id,
                                      callerName: caller.name,
                                      receiverId: widget.doctor.id,
                                      receiverName: widget.doctor.name,
                                    ),
                                  );
                                  // Navigation handled by BlocListener above
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.videocam, size: 20),
                                label: const Text('Video Call'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _selectedSlot == null
                          ? null
                          : () {
                              // Demo pricing
                              const amount = 500.0;
                              const commission = 50.0;
                              final booking = BookingEntity(
                                id: '',
                                doctorId: widget.doctor.id,
                                userId: user.id,
                                startTime:
                                    DateTime.now(), // Simplified for demo
                                endTime: DateTime.now().add(
                                  const Duration(minutes: 30),
                                ),
                                durationMinutes: 30,
                                totalAmount: amount,
                                commission: commission,
                                doctorEarning: amount - commission,
                              );
                              context.read<BookingBloc>().add(
                                BookAppointmentEvent(booking),
                              );
                            },
                      child: const Text('Book Appointment'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
