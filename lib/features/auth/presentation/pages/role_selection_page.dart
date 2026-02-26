import 'package:flutter/material.dart';
import 'package:doctor_booking_app/features/auth/presentation/pages/login_page.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';

enum AppRole { patient, doctor, admin }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AppRole? _selected;

  void _proceed() {
    if (_selected == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(role: _selected!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      // ✅ Called here, before return
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),

              // ── App brand ─────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MediConnect',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 44),

              const Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your role to continue',
                style: TextStyle(fontSize: 15, color: Colors.grey[500]),
              ),

              const SizedBox(height: 28),

              // ── Role Cards ────────────────────────────────
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'Patient',
                subtitle: 'Find doctors & book appointments',
                tag: 'For patients',
                selected: _selected == AppRole.patient,
                onTap: () => setState(() => _selected = AppRole.patient),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.medical_services_rounded,
                title: 'Doctor',
                subtitle: 'Manage schedule & consultations',
                tag: 'For doctors',
                selected: _selected == AppRole.doctor,
                onTap: () => setState(() => _selected = AppRole.doctor),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.shield_rounded,
                title: 'Admin',
                subtitle: 'Oversee platform & user management',
                tag: 'Staff only',
                selected: _selected == AppRole.admin,
                onTap: () => setState(() => _selected = AppRole.admin),
              ),

              const Spacer(),

              // ── Continue Button ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  opacity: _selected != null ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _selected != null ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryColor,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFE8E8EE),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primaryColor.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(
                  selected ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 26),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primaryColor
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryColor
                      : const Color(0xFFCCCCDD),
                  width: 2,
                ),
                color: selected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
