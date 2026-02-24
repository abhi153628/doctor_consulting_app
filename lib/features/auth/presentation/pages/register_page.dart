import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/core/utils/snackbar_utils.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            CustomSnackBar.show(
              context,
              message: 'Account created successfully!',
              type: SnackBarType.success,
            );
            // Clear the registration/login stack and let main.dart show the home page
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (state is AuthError) {
            CustomSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Register as:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Patient'),
                      value: UserRole.patient,
                      groupValue: _selectedRole,
                      onChanged: (v) =>
                          setState(() => _selectedRole = v ?? UserRole.patient),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Doctor'),
                      value: UserRole.doctor,
                      groupValue: _selectedRole,
                      onChanged: (v) =>
                          setState(() => _selectedRole = v ?? UserRole.patient),
                    ),
                  ),
                ],
              ),
              if (_selectedRole == UserRole.doctor) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    hintText: 'Specialization (e.g. Cardiologist)',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number (10 digits)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        final spec = _specializationController.text.trim();
                        final phone = _phoneController.text.trim();

                        if (name.isEmpty) {
                          CustomSnackBar.show(
                            context,
                            message: 'Please enter your full name',
                            type: SnackBarType.error,
                          );
                          return;
                        }

                        if (email.isEmpty || !email.contains('@')) {
                          CustomSnackBar.show(
                            context,
                            message: 'Please enter a valid email address',
                            type: SnackBarType.error,
                          );
                          return;
                        }

                        if (password.length < 6) {
                          CustomSnackBar.show(
                            context,
                            message: 'Password must be at least 6 characters',
                            type: SnackBarType.error,
                          );
                          return;
                        }

                        if (_selectedRole == UserRole.doctor) {
                          if (spec.isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please enter your specialization',
                              type: SnackBarType.error,
                            );
                            return;
                          }
                          // Indian Phone validation: 10 digits, starts with 6-9
                          final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                          if (phone.isEmpty || !phoneRegex.hasMatch(phone)) {
                            CustomSnackBar.show(
                              context,
                              message:
                                  'Please enter a valid 10-digit Indian phone number',
                              type: SnackBarType.error,
                            );
                            return;
                          }
                        }

                        context.read<AuthBloc>().add(
                          AuthSignUpEvent(
                            email: email,
                            password: password,
                            name: name,
                            role: _selectedRole,
                            specialization: _selectedRole == UserRole.doctor
                                ? spec
                                : null,
                            phoneNumber: _selectedRole == UserRole.doctor
                                ? phone
                                : null,
                          ),
                        );
                      },
                      child: const Text('Register'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
