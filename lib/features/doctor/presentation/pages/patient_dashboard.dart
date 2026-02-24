import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/doctor/presentation/pages/doctor_details_page.dart';
import 'package:doctor_booking_app/features/booking/presentation/pages/patient_bookings_page.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/widgets/incoming_call_overlay.dart';

class PatientDashboard extends StatefulWidget {
  final UserEntity user;
  const PatientDashboard({super.key, required this.user});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _searchController = TextEditingController();
  String? _selectedSpecialization;
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  final List<String> _specializations = [
    'Cardiologist',
    'Dermatologist',
    'General Physician',
    'Pediatrician',
    'Neurologist',
    'Psychiatrist',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    context.read<CallBloc>().listenToIncomingCalls(widget.user.id);

    _pages = [
      _buildHomeContent(),
      const PatientBookingsPage(),
      const ChatListPage(),
    ];
  }

  void _fetchDoctors() {
    context.read<DoctorBloc>().add(
      GetDoctorsEvent(specialization: _selectedSpecialization),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallOverlay(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? 'Find Doctors'
                : _selectedIndex == 1
                ? 'My Bookings'
                : 'Messages',
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
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
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search doctors...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300] ?? Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300] ?? Colors.grey,
                    ),
                  ),
                ),
                onChanged: (v) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _specializations.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final spec = isAll ? 'All' : _specializations[index - 1];
                    final isSelected = isAll
                        ? _selectedSpecialization == null
                        : _selectedSpecialization == spec;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(spec),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSpecialization = isAll ? null : spec;
                          });
                          _fetchDoctors();
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<DoctorBloc, DoctorState>(
            builder: (context, state) {
              if (state is DoctorLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DoctorsLoaded) {
                final doctors = state.doctors;
                final filteredDoctors = doctors.where((d) {
                  final query = _searchController.text.toLowerCase();
                  if (query.isEmpty) return true;
                  final name = d.name.toLowerCase();
                  return name.contains(query);
                }).toList();

                if (filteredDoctors.isEmpty) {
                  return const Center(child: Text('No doctors found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    if (index >= filteredDoctors.length) {
                      return const SizedBox();
                    }
                    final doctor = filteredDoctors[index];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: (Colors.grey[200] ?? Colors.grey),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor
                                    .withAlpha(25),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.specialization.isNotEmpty
                                        ? doctor.specialization
                                        : 'General Physician',
                                    style: TextStyle(
                                      color: Colors.grey[600] ?? Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor.rating.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.circle,
                                        color: doctor.isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 8,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor.isOnline ? 'Online' : 'Offline',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    if (doctor.id.isEmpty) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          chatId:
                                              '${widget.user.id}_${doctor.id}',
                                          receiverName: doctor.name.isNotEmpty
                                              ? doctor.name
                                              : 'Doctor',
                                          receiverPhoneNumber:
                                              doctor.phoneNumber,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Chat'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DoctorDetailsPage(doctor: doctor),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('View Profile'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (state is DoctorError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

// Note: CardVariant might not be in all Flutter versions. I'll use simple Card if it fails.
