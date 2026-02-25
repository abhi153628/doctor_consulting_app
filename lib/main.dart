import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doctor_booking_app/injection_container.dart' as di;
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/message_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/pages/login_page.dart';
import 'package:doctor_booking_app/features/doctor/presentation/pages/patient_dashboard.dart';
import 'package:doctor_booking_app/features/doctor/presentation/pages/doctor_dashboard.dart';
import 'package:doctor_booking_app/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:doctor_booking_app/features/auth/presentation/pages/approval_pending_page.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:doctor_booking_app/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
        BlocProvider(create: (_) => di.sl<DoctorBloc>()),
        BlocProvider(create: (_) => di.sl<BookingBloc>()),
        BlocProvider(create: (_) => di.sl<ChatBloc>()),
        BlocProvider(create: (_) => di.sl<MessageBloc>()),
        BlocProvider(create: (_) => di.sl<CallBloc>()),
      ],
      child: MaterialApp(
        title: 'Doctor Booking App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final user = state.user;
              if (user.role == UserRole.doctor) {
                // Determine approval status regardless of concrete type
                bool isApproved = false;
                if (user is UserModel) {
                  isApproved = user.isApproved ?? false;
                } else if (user is DoctorEntity) {
                  // DoctorEntity is the parent of DoctorModel
                  isApproved = (user as dynamic).isApproved ?? false;
                }

                return isApproved
                    ? DoctorDashboard(user: user)
                    : const ApprovalPendingPage();
              } else if (user.role == UserRole.admin) {
                return const AdminDashboard();
              } else {
                return PatientDashboard(user: user);
              }
            }

            // For all other states (Initial, Loading, Error, Unauthenticated),
            // show LoginPage if not authenticated.
            // This prevents re-instantiating LoginPage during Loading/Error,
            // which would clear the text controllers.
            if (state is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const LoginPage();
          },
        ),
      ),
    );
  }
}
