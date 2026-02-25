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

  /// Normalize any slot to "HH:mm" (24h). Handles:
  ///   "HH:mm"     → returned as-is
  ///   "H:mm AM"   → converted to 24h
  ///   "H:mm PM"   → converted to 24h
  ///   "H AM" / "H PM" (no minutes) → converted to 24h with :00
  String _normalizeSlot(String s) {
    try {
      final upper = s.toUpperCase().trim();
      final isPM = upper.endsWith('PM');
      final isAM = upper.endsWith('AM');
      final cleaned = upper.replaceAll('AM', '').replaceAll('PM', '').trim();

      // Support both "H:mm" and plain "H" (no minutes)
      int hour;
      int minute = 0;
      if (cleaned.contains(':')) {
        final parts = cleaned.split(':');
        hour = int.parse(parts[0].trim());
        minute = int.parse(parts[1].trim());
      } else {
        hour = int.parse(cleaned);
      }

      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s; // Return as-is if we can't parse; won't crash
    }
  }

  /// Parse a normalized "HH:mm" slot to minutes for sorting
  int _slotToMinutes(String s) {
    try {
      final normalized = _normalizeSlot(s);
      final parts = normalized.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    // Normalize all existing slots so we never crash on legacy AM/PM data
    _slots = widget.currentSlots.map(_normalizeSlot).toList();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // Store in strict HH:mm (24h) format
        final String hour = picked.hour.toString().padLeft(2, '0');
        final String minute = picked.minute.toString().padLeft(2, '0');
        final standardTime = '$hour:$minute';

        if (!_slots.contains(standardTime)) {
          _slots.add(standardTime);

          // Sort chronologically using robust minute-value comparator
          _slots.sort((a, b) => _slotToMinutes(a).compareTo(_slotToMinutes(b)));

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
