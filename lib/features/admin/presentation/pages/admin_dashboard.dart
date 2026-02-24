import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorBloc>().add(GetPendingDoctorsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutEvent()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Approvals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<DoctorBloc, DoctorState>(
              builder: (context, state) {
                if (state is DoctorLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DoctorsLoaded) {
                  if (state.doctors.isEmpty) {
                    return _buildEmptyPendingState();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = state.doctors[index];
                      return _buildApprovalCard(doctor);
                    },
                  );
                } else if (state is DoctorError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(DoctorEntity doctor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200] ?? Colors.grey),
      ),
      child: ListTile(
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(doctor.specialization),
        trailing: ElevatedButton(
          onPressed: () {
            context.read<DoctorBloc>().add(ApproveDoctorEvent(doctor.id));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 40),
          ),
          child: const Text('Approve'),
        ),
      ),
    );
  }

  Widget _buildEmptyPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
