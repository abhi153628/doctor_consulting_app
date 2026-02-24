import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/pages/register_page.dart';
import 'package:doctor_booking_app/core/utils/snackbar_utils.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            CustomSnackBar.show(
              context,
              message: 'Login successful!',
              type: SnackBarType.success,
            );
            // LoginPage is usually the root, but we clear any pushes just in case
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
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
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (email.isEmpty || !email.contains('@')) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please enter a valid email address',
                              type: SnackBarType.error,
                            );
                            return;
                          }

                          if (password.isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: 'Please enter your password',
                              type: SnackBarType.error,
                            );
                            return;
                          }

                          context.read<AuthBloc>().add(
                            AuthLoginEvent(email, password),
                          );
                        },
                        child: const Text('Login'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
