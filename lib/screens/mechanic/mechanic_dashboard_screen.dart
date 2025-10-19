import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../services/api_service.dart';
import '../../services/mechanic_auth_service.dart';
import '../../widgets/appointment_card.dart';

class MechanicDashboardScreen extends StatefulWidget {
  const MechanicDashboardScreen({super.key});

  @override
  State<MechanicDashboardScreen> createState() =>
      _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  List<Appointment> _upcomingAppointments = [];
  bool _loadingAppointments = false;
  bool _togglingAvailability = false;
  bool _checkingMechanicStatus = true;

  @override
  void initState() {
    super.initState();
    // Check if user has a mechanic profile by calling the API
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mechanicAuth = context.read<MechanicAuthService>();
      try {
        // Try to refresh the profile from the API
        await mechanicAuth.refreshProfile();
        if (mechanicAuth.currentMechanic != null) {
          _loadUpcomingAppointments();
        }
      } catch (e) {
        // If refresh fails, user is not a mechanic
        print('No mechanic profile found: $e');
      } finally {
        setState(() {
          _checkingMechanicStatus = false;
        });
      }
    });
  }

  Future<void> _loadUpcomingAppointments() async {
    // Don't try to load if no mechanic profile
    final mechanicAuth = context.read<MechanicAuthService>();
    if (mechanicAuth.currentMechanic == null) {
      return;
    }

    setState(() => _loadingAppointments = true);

    try {
      final apiService = context.read<ApiService>();
      final appointments = await apiService.getMechanicAppointments(
        statusFilter: 'scheduled',
        perPage: 10,
      );
      setState(() {
        _upcomingAppointments = appointments;
        _loadingAppointments = false;
      });
    } catch (e) {
      setState(() => _loadingAppointments = false);
      // Don't show error if it's just "not a mechanic" error
      if (mounted && !e.toString().contains('404')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAvailability(bool newValue) async {
    setState(() => _togglingAvailability = true);

    try {
      final mechanicAuth = context.read<MechanicAuthService>();
      await mechanicAuth.toggleAvailability(newValue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? '✅ You are now available for calls'
                  : '🔴 You are now offline',
            ),
            backgroundColor: newValue ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _togglingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mechanicAuth = context.watch<MechanicAuthService>();
    final mechanic = mechanicAuth.currentMechanic;

    // Show loading while checking mechanic status
    if (_checkingMechanicStatus) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Mechanic Dashboard'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (mechanic == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Mechanic Dashboard'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.engineering_outlined,
                    size: 80,
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mechanic Account Not Set Up',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To access the Mechanic Scheduler, you need to set up your mechanic profile first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to settings
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Go to Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mechanic Dashboard'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await mechanicAuth.refreshProfile();
          await _loadUpcomingAppointments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome back, ${mechanic.name}! 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your schedule and upcoming video consultations',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Quick Availability Toggle
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mechanic.isAvailable
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mechanic.isAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Availability Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mechanic.isAvailable
                                  ? 'You are ONLINE and available'
                                  : 'You are OFFLINE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.3,
                        child: Switch(
                          value: mechanic.isAvailable,
                          onChanged: _togglingAvailability
                              ? null
                              : _toggleAvailability,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.green.shade300,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Calls',
                      '3', // TODO: Get from backend
                      Icons.videocam,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '\$${(mechanic.hourlyRate * 6).toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Rating',
                      '⭐ ${mechanic.rating.toStringAsFixed(1)}',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Upcoming Appointments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 Upcoming Appointments',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _loadUpcomingAppointments,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loadingAppointments)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_upcomingAppointments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming appointments',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mechanic.isAvailable
                                ? 'You\'re available! Customers can book you.'
                                : 'Turn on availability to accept bookings',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_upcomingAppointments.length, (index) {
                  final appointment = _upcomingAppointments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppointmentCard(
                      appointment: appointment,
                      onJoinCall: appointment.canJoin
                          ? () => _joinVideoCall(appointment)
                          : null,
                      onReschedule: () => _rescheduleAppointment(appointment),
                      onCancel: () => _cancelAppointment(appointment),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Manage Availability Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mechanic-availability');
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Manage Availability Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinVideoCall(Appointment appointment) async {
    // Navigate to video call screen
    Navigator.pushNamed(
      context,
      '/mechanic-video-call',
      arguments: appointment,
    );
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    // TODO: Implement reschedule dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel the appointment with ${appointment.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = context.read<ApiService>();
        await apiService.updateAppointmentStatus(appointment.id, {
          'status': 'cancelled',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadUpcomingAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
