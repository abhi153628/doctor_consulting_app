import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/core/utils/snackbar_utils.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class ManageSlotsPage extends StatefulWidget {
  final UserEntity user;
  final List<String> currentSlots;

  const ManageSlotsPage({
    super.key,
    required this.user,
    required this.currentSlots,
  });

  @override
  State<ManageSlotsPage> createState() => _ManageSlotsPageState();
}

class _ManageSlotsPageState extends State<ManageSlotsPage> {
  late List<String> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.currentSlots);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // Store in a standard HH:mm format for reliable parsing
        final String hour = picked.hour.toString().padLeft(2, '0');
        final String minute = picked.minute.toString().padLeft(2, '0');
        final standardTime = '$hour:$minute';

        if (!_slots.contains(standardTime)) {
          _slots.add(standardTime);

          // Sort chronologically
          _slots.sort((a, b) {
            final aParts = a.split(':');
            final bParts = b.split(':');
            final aValue = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
            final bValue = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
            return aValue.compareTo(bValue);
          });

          CustomSnackBar.show(
            context,
            message: 'Slot added: ${picked.format(context)}',
            type: SnackBarType.success,
          );
        } else {
          CustomSnackBar.show(
            context,
            message: 'This slot already exists',
            type: SnackBarType.error,
          );
        }
      });
    }
  }

  String _formatForDisplay(String standardTime) {
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

  void _save() {
    context.read<DoctorBloc>().add(UpdateSlotsEvent(widget.user.id, _slots));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [TextButton(onPressed: _save, child: const Text('SAVE'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.more_time),
                label: const Text('Add Time Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Active Slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _slots.isEmpty
                  ? const Center(child: Text('No slots added yet'))
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _slots
                          .map(
                            (slot) => Chip(
                              label: Text(_formatForDisplay(slot)),
                              onDeleted: () {
                                setState(() => _slots.remove(slot));
                              },
                              backgroundColor: AppTheme.primaryColor.withAlpha(
                                20,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
