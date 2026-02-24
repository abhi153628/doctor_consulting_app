import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';
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

class DoctorDashboard extends StatefulWidget {
  final UserEntity user;
  const DoctorDashboard({super.key, required this.user});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  bool _isOnline = false;
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _isOnline = (user is UserModel) ? (user.isApproved ?? false) : false;
    _refresh();
    context.read<CallBloc>().listenToIncomingCalls(widget.user.id);

    _pages = [
      _buildHomeContent(),
      const ChatListPage(),
      const Center(child: Text('Video Call History\n(Coming Soon)')),
    ];
  }

  void _refresh() {
    context.read<BookingBloc>().add(GetDoctorBookingsEvent(widget.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallOverlay(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? 'Doctor Dashboard'
                : _selectedIndex == 1
                ? 'Messages'
                : 'Video Calls',
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            if (_selectedIndex == 0)
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutEvent()),
            ),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
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
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.videocam_outlined),
              activeIcon: Icon(Icons.videocam),
              label: 'Calls',
            ),
          ],
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
          const SizedBox(height: 32),
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

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      color: _isOnline ? Colors.green[50] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isOnline
              ? (Colors.green[200] ?? Colors.green)
              : (Colors.grey[300] ?? Colors.grey),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _isOnline ? Colors.green : Colors.grey,
              radius: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? 'You are Online' : 'You are Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green[900] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    _isOnline
                        ? 'Patients can see you and book appointments'
                        : 'Your profile is hidden from search',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isOnline,
              activeColor: Colors.green,
              onChanged: (v) {
                setState(() => _isOnline = v);
                context.read<DoctorBloc>().add(
                  UpdateAvailabilityEvent(widget.user.id, v),
                );
              },
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
        _buildActionCard('Manage Slots', Icons.calendar_month, Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageSlotsPage(
                user: widget.user,
                currentSlots: (widget.user is DoctorEntity)
                    ? (widget.user as DoctorEntity).availableTimeSlots
                    : [],
              ),
            ),
          );
        }),
        _buildActionCard(
          'Earnings',
          Icons.account_balance_wallet,
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EarningsPage()),
            );
          },
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
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatusEvent(
                          booking.id,
                          BookingStatus.accepted,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        UpdateBookingStatusEvent(
                          booking.id,
                          BookingStatus.rejected,
                        ),
                      );
                    },
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
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
