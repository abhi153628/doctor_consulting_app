import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/pages/manage_slots_page.dart';
import 'package:doctor_booking_app/features/doctor/presentation/pages/earnings_page.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/widgets/incoming_call_overlay.dart';
import 'package:doctor_booking_app/core/utils/snackbar_utils.dart';

class DoctorDashboard extends StatefulWidget {
  final UserEntity user;
  const DoctorDashboard({super.key, required this.user});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  bool isOn = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user is DoctorEntity) {
      isOn = user.isOnline;
    }
    _refresh();
    context.read<CallBloc>().listenToIncomingCalls(widget.user.id);
    // Subscribe to real-time profile changes (for initial sync)
    context.read<DoctorBloc>().add(GetDoctorProfileEvent(widget.user.id));
  }

  void _refresh() {
    context.read<BookingBloc>().add(GetDoctorBookingsEvent(widget.user.id));
  }

  void _handleAvailabilityToggle(bool value) {
    setState(() {
      isOn = value;
    });
    // Sync to Firestore so patients see it in real-time
    context.read<DoctorBloc>().add(
      UpdateAvailabilityEvent(widget.user.id, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHomeContent(), const ChatListPage()];

    return BlocListener<DoctorBloc, DoctorState>(
      listener: (context, state) {
        if (state is DoctorError) {
          CustomSnackBar.show(
            context,
            message: 'Firestore Update Error',
            type: SnackBarType.error,
          );
        }
      },
      child: IncomingCallOverlay(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(_selectedIndex == 0 ? 'Doctor Dashboard' : 'Messages'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              if (_selectedIndex == 0)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutEvent()),
              ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              if (index == 0) _refresh();
            },
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_outlined),
                activeIcon: Icon(Icons.message),
                label: 'Messages',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 24),
          _buildActionGrid(),
          const SizedBox(height: 24),
          // ── Live Earnings Summary ──────────────────────────────────────
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingsLoaded) {
                return _buildEarningsSummaryCard(state.bookings);
              }
              // Show a shimmer/placeholder while loading
              return _buildEarningsSummaryCard(const []);
            },
          ),
          const SizedBox(height: 24),
          // ── Recent Booking Requests ────────────────────────────────────
          const Text(
            'Recent Booking Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BookingsLoaded) {
                if (state.bookings.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return _buildBookingItem(booking);
                  },
                );
              } else if (state is BookingError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  /// Live earnings card: updates automatically whenever the booking stream fires.
  /// Counts both [accepted] and [completed] bookings towards total earnings.
  Widget _buildEarningsSummaryCard(List<BookingEntity> bookings) {
    final paidBookings = bookings
        .where(
          (b) =>
              b.status == BookingStatus.accepted ||
              b.status == BookingStatus.completed,
        )
        .toList();

    double totalEarned = 0;
    double totalCommission = 0;
    for (final b in paidBookings) {
      totalEarned += b.doctorEarning; // ₹80 each
      totalCommission += b.commission; // ₹20 each
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withAlpha(89),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${paidBookings.length} consultation${paidBookings.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${totalEarned.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            children: [
              // Doctor's share
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your share (80%)',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${totalEarned.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              // Admin commission
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin commission (20%)',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${totalCommission.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(217),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      color: isOn ? Colors.green[50] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOn
              ? (Colors.green[200] ?? Colors.green)
              : (Colors.grey[300] ?? Colors.grey),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isOn ? Colors.green : Colors.grey,
              radius: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOn ? 'You are Online' : 'You are Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOn ? Colors.green[900] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    isOn
                        ? 'Patients can see you and book appointments'
                        : 'Your profile is hidden from search',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: isOn,
                  activeColor: Colors.green,
                  onChanged: _handleAvailabilityToggle,
                ),
                Text(
                  isOn ? "Status: ON" : "Status: OFF",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          'Manage Slots',
          Icons.calendar_month,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageSlotsPage(
                user: widget.user,
                currentSlots: (widget.user is DoctorEntity)
                    ? (widget.user as DoctorEntity).availableTimeSlots
                    : [],
              ),
            ),
          ),
        ),
        _buildActionCard(
          'Earnings',
          Icons.account_balance_wallet,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EarningsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200] ?? Colors.grey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BookingEntity booking) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200] ?? Colors.grey),
      ),
      child: ListTile(
        title: Text(
          DateFormat('MMM dd, hh:mm a').format(booking.startTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Status: ${booking.status.name.toUpperCase()}'),
        trailing: booking.status == BookingStatus.pending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatusEvent(
                          booking.id,
                          BookingStatus.accepted,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatusEvent(
                          booking.id,
                          BookingStatus.rejected,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'REJECT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getStatusBadge(booking.status),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: '${booking.userId}_${booking.doctorId}',
                            receiverName: 'Patient',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getStatusBadge(BookingStatus status) {
    Color color = Colors.grey;
    switch (status) {
      case BookingStatus.accepted:
        color = Colors.green;
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No new booking requests',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
