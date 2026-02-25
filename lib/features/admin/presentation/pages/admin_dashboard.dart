import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        title: const Text(
          'Admin Console',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutEvent()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.verified_user_outlined, size: 20),
              text: 'Approvals',
            ),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Users'),
            Tab(
              icon: Icon(Icons.calendar_today_outlined, size: 20),
              text: 'Bookings',
            ),
            Tab(
              icon: Icon(Icons.analytics_outlined, size: 20),
              text: 'Finance',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ApprovalsTab(), _UsersTab(), _BookingsTab(), _FinanceTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const _blue = Color(0xFF1565C0);

Widget _emptyState(IconData icon, String title, [String subtitle = '']) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<bool> _confirmBlock(
  BuildContext context,
  String name,
  bool block,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(block ? 'Block $name?' : 'Unblock $name?'),
      content: Text(
        block
            ? 'Are you sure you want to block $name? They will be immediately signed out and cannot use the app.'
            : 'Are you sure you want to unblock $name? They will regain access to the app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: block ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(block ? 'Yes, Block' : 'Yes, Unblock'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: APPROVALS
// ─────────────────────────────────────────────────────────────────────────────
class _ApprovalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<DoctorBloc>().repository;
    return StreamBuilder<List<DoctorEntity>>(
      stream: repo.getPendingDoctorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final doctors = snapshot.data ?? [];
        if (doctors.isEmpty) {
          return _emptyState(
            Icons.verified_user_outlined,
            'No pending approvals',
            'All doctor registrations have been reviewed',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, i) => _ApprovalCard(doctor: doctors[i]),
        );
      },
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final DoctorEntity doctor;
  const _ApprovalCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _blue.withOpacity(0.1),
                  child: Text(
                    doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        doctor.specialization,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (doctor.email.isNotEmpty)
                        Text(
                          doctor.email,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<DoctorBloc>().add(
                      RejectDoctorEvent(doctor.id),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<DoctorBloc>().add(
                      ApproveDoctorEvent(doctor.id),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: USERS (doctors + patients with Block button)
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DoctorBloc>().repository;
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _inner,
            labelColor: _blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _blue,
            tabs: const [
              Tab(text: 'Doctors'),
              Tab(text: 'Patients'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              // Doctors
              StreamBuilder<List<DoctorEntity>>(
                stream: repo.getAllDoctorsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty)
                    return _emptyState(
                      Icons.local_hospital_outlined,
                      'No doctors',
                    );
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _DoctorUserCard(doctor: list[i]),
                  );
                },
              ),
              // Patients
              StreamBuilder<List<UserEntity>>(
                stream: repo.getAllUsersStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty)
                    return _emptyState(Icons.person_outline, 'No patients');
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _PatientUserCard(user: list[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorUserCard extends StatelessWidget {
  final DoctorEntity doctor;
  const _DoctorUserCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return _UserCardBase(
      name: doctor.name,
      subtitle: doctor.specialization,
      email: doctor.email,
      isBlocked: doctor.isBlocked,
      badge: doctor.isApproved ? 'Approved' : 'Pending',
      badgeColor: doctor.isApproved ? Colors.green : Colors.orange,
      onBlockToggle: (block) async {
        final ok = await _confirmBlock(context, doctor.name, block);
        if (ok && context.mounted) {
          context.read<DoctorBloc>().add(BlockDoctorEvent(doctor.id, block));
        }
      },
    );
  }
}

class _PatientUserCard extends StatelessWidget {
  final UserEntity user;
  const _PatientUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _UserCardBase(
      name: user.name,
      subtitle: user.email,
      isBlocked: user.isBlocked,
      onBlockToggle: (block) async {
        final ok = await _confirmBlock(context, user.name, block);
        if (ok && context.mounted) {
          context.read<DoctorBloc>().add(BlockUserEvent(user.id, block));
        }
      },
    );
  }
}

class _UserCardBase extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? email;
  final bool isBlocked;
  final String? badge;
  final Color? badgeColor;
  final Future<void> Function(bool block) onBlockToggle;

  const _UserCardBase({
    required this.name,
    required this.subtitle,
    this.email,
    required this.isBlocked,
    this.badge,
    this.badgeColor,
    required this.onBlockToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isBlocked ? Colors.red[100]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isBlocked
                  ? Colors.red.withOpacity(0.1)
                  : _blue.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isBlocked ? Colors.red : _blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BLOCKED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (email != null)
                    Text(
                      email!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  if (badge != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? Colors.grey).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Block / Unblock button
            if (isBlocked)
              OutlinedButton(
                onPressed: () => onBlockToggle(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Unblock', style: TextStyle(fontSize: 12)),
              )
            else
              ElevatedButton(
                onPressed: () => onBlockToggle(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Block', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: BOOKINGS — shows all bookings (pending + completed)
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<BookingBloc>().repository;
    return StreamBuilder<List<BookingEntity>>(
      stream: repo.getAllBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading bookings:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return _emptyState(Icons.calendar_today_outlined, 'No bookings yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  const _BookingCard({required this.booking});

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medical_services_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${booking.doctorName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Patient: ${booking.patientName}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy · hh:mm a',
                    ).format(booking.startTime),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                booking.status.name.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: FINANCE
// ─────────────────────────────────────────────────────────────────────────────
class _FinanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<BookingBloc>().repository;
    return StreamBuilder<List<BookingEntity>>(
      stream: repo.getAllBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final paid = all
            .where(
              (b) =>
                  b.status == BookingStatus.accepted ||
                  b.status == BookingStatus.completed,
            )
            .toList();

        final Map<String, _DocSummary> perDoctor = {};
        double totalCommission = 0;
        for (final b in paid) {
          totalCommission += b.commission;
          perDoctor.putIfAbsent(b.doctorId, () => _DocSummary(b.doctorName));
          perDoctor[b.doctorId]!.earning += b.doctorEarning;
          perDoctor[b.doctorId]!.count++;
        }
        final list = perDoctor.values.toList()
          ..sort((a, b) => b.earning.compareTo(a.earning));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _financeHeader(totalCommission, paid.length),
              const SizedBox(height: 20),
              if (list.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Per Doctor Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...list.map((s) => _DocCard(s)),
              ] else
                _emptyState(
                  Icons.analytics_outlined,
                  'No transactions yet',
                  'Accept a booking to see earnings',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _financeHeader(double commission, int count) {
    final totalRevenue = count > 0 ? commission / 0.20 : 0.0;
    final doctorPay = totalRevenue - commission;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Commission Earned',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${commission.toStringAsFixed(0)}',
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
              Expanded(
                child: _fStat(
                  'Total Revenue',
                  '₹${totalRevenue.toStringAsFixed(0)}',
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _fStat(
                  'Paid to Doctors',
                  '₹${doctorPay.toStringAsFixed(0)}',
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(child: _fStat('Sessions', '$count')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DocSummary {
  final String name;
  double earning = 0;
  int count = 0;
  _DocSummary(this.name);
}

class _DocCard extends StatelessWidget {
  final _DocSummary s;
  const _DocCard(this.s);

  @override
  Widget build(BuildContext context) {
    final adminCut = s.earning * 0.25;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _blue.withOpacity(0.1),
              child: Text(
                s.name.isNotEmpty ? s.name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${s.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${s.count} session${s.count == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Admin cut: ₹${adminCut.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${s.earning.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'doctor earned',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
