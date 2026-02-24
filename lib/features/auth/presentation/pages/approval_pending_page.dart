import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class ApprovalPendingPage extends StatelessWidget {
  const ApprovalPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Approval Pending',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your doctor profile is currently under review by our administrators. You will be able to access the dashboard once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutEvent());
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Logout'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthCheckStatusEvent());
                },
                child: const Text('Check Status Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
