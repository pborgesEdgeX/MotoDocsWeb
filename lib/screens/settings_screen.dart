import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/mechanic_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _specializationsController = TextEditingController();

  bool _isMechanic = false;
  bool _loadingMechanicProfile = true;
  bool _savingProfile = false;
  String _selectedDuration = '30'; // Default 30 minutes

  @override
  void initState() {
    super.initState();
    _loadMechanicProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hourlyRateController.dispose();
    _specializationsController.dispose();
    super.dispose();
  }

  Future<void> _loadMechanicProfile() async {
    setState(() => _loadingMechanicProfile = true);

    try {
      final mechanicAuth = context.read<MechanicAuthService>();
      await mechanicAuth.refreshProfile();

      final mechanic = mechanicAuth.currentMechanic;
      if (mechanic != null) {
        setState(() {
          _isMechanic = true;
          _nameController.text = mechanic.name;
          _hourlyRateController.text = mechanic.hourlyRate.toString();
          _specializationsController.text = mechanic.specializations.join(', ');
          _loadingMechanicProfile = false;
        });
      } else {
        setState(() {
          _isMechanic = false;
          _loadingMechanicProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isMechanic = false;
        _loadingMechanicProfile = false;
      });
    }
  }

  Future<void> _toggleMechanicStatus(bool value) async {
    if (value && !_isMechanic) {
      // User wants to become a mechanic
      _showMechanicRegistrationDialog();
    } else if (!value && _isMechanic) {
      // User wants to disable mechanic status
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Mechanic Account'),
          content: const Text(
            'Are you sure you want to disable your mechanic account? '
            'This will hide you from customers and cancel all pending appointments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _disableMechanicAccount();
      }
    }
  }

  Future<void> _disableMechanicAccount() async {
    try {
      final mechanicAuth = context.read<MechanicAuthService>();
      await mechanicAuth.toggleAvailability(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mechanic account disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMechanicRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Become a Mechanic'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fill in your mechanic profile details to start accepting appointments:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (\$) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your hourly rate';
                    }
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Please enter a valid rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specializationsController,
                  decoration: const InputDecoration(
                    labelText: 'Specializations (comma-separated)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                    hintText: 'e.g. Harley-Davidson, Engine Repair',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDuration,
                  decoration: const InputDecoration(
                    labelText: 'Default Slot Duration',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  items: const [
                    DropdownMenuItem(value: '15', child: Text('15 minutes')),
                    DropdownMenuItem(value: '30', child: Text('30 minutes')),
                    DropdownMenuItem(value: '45', child: Text('45 minutes')),
                    DropdownMenuItem(value: '60', child: Text('60 minutes')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDuration = value ?? '30');
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _savingProfile ? null : _registerAsMechanic,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: _savingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Register as Mechanic'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerAsMechanic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('Not authenticated');
      }

      final apiService = context.read<ApiService>();

      // Parse specializations
      final specializations = _specializationsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Register mechanic via API
      final response = await apiService.registerMechanic({
        'email': user.email,
        'name': _nameController.text.trim(),
        'hourly_rate': double.parse(_hourlyRateController.text),
        'specializations': specializations,
      });

      // Update mechanic auth service with the response
      final mechanicAuth = context.read<MechanicAuthService>();
      await mechanicAuth.register(response);

      setState(() {
        _savingProfile = false;
        _isMechanic = true;
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mechanic account activated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _savingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register as mechanic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingMechanicProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  const Text(
                    '👤 User Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: Colors.blue,
                            ),
                            title: const Text('Email'),
                            subtitle: Text(user?.email ?? 'Not logged in'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.green,
                            ),
                            title: const Text('Display Name'),
                            subtitle: Text(user?.displayName ?? 'Not set'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mechanic Settings Section
                  const Text(
                    '🔧 Mechanic Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Enable Mechanic Account',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _isMechanic
                                  ? 'You can accept video consultation appointments'
                                  : 'Turn on to start accepting appointments',
                            ),
                            value: _isMechanic,
                            onChanged: _toggleMechanicStatus,
                            activeColor: Colors.green,
                            secondary: Icon(
                              _isMechanic
                                  ? Icons.check_circle
                                  : Icons.engineering,
                              color: _isMechanic ? Colors.green : Colors.grey,
                            ),
                          ),
                          if (_isMechanic) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.orange,
                              ),
                              title: const Text('Mechanic Name'),
                              subtitle: Text(_nameController.text),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.attach_money,
                                color: Colors.green,
                              ),
                              title: const Text('Hourly Rate'),
                              subtitle: Text(
                                '\$${_hourlyRateController.text}/hour',
                              ),
                            ),
                            if (_specializationsController.text.isNotEmpty)
                              ListTile(
                                leading: const Icon(
                                  Icons.build,
                                  color: Colors.blue,
                                ),
                                title: const Text('Specializations'),
                                subtitle: Text(_specializationsController.text),
                              ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to availability management
                                  Navigator.pushNamed(
                                    context,
                                    '/mechanic-availability',
                                  );
                                },
                                icon: const Icon(Icons.calendar_month),
                                label: const Text(
                                  'Manage Availability Schedule',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
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
    );
  }
}
