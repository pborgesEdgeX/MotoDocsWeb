import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/availability_slot.dart';
import '../../services/api_service.dart';
import '../../services/mechanic_auth_service.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends State<AvailabilityManagementScreen> {
  List<AvailabilitySlot> _slots = [];
  bool _loading = false;

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() => _loading = true);

    try {
      final apiService = context.read<ApiService>();
      final slots = await apiService.getAvailabilitySlots(activeOnly: false);
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AvailabilitySlot> _getSlotsForDay(String day) {
    return _slots.where((slot) => slot.dayOfWeek == day && slot.isRecurring).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mechanicAuth = context.watch<MechanicAuthService>();
    final mechanic = mechanicAuth.currentMechanic;

    if (mechanic == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Availability Schedule'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailabilitySlots,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Availability Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.orange.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Toggle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Turn availability on/off instantly',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await mechanicAuth.toggleAvailability(
                            !mechanic.isAvailable,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  mechanic.isAvailable
                                      ? '🟢 Now Available'
                                      : '🔴 Now Offline',
                                ),
                                backgroundColor: mechanic.isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          mechanic.isAvailable ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(
                          mechanic.isAvailable ? 'Go Offline' : 'Go Online',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mechanic.isAvailable
                              ? Colors.grey.shade600
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Weekly Schedule
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📅 Weekly Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSlotDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Time Slot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(_daysOfWeek.length, (index) {
                      final day = _daysOfWeek[index];
                      final daySlots = _getSlotsForDay(day);
                      final isLastDay = index == _daysOfWeek.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    _dayLabels[day]!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: daySlots.isEmpty
                                      ? Row(
                                          children: [
                                            Text(
                                              'Unavailable',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _showAddSlotDialog(day: day),
                                              icon: const Icon(Icons.add,
                                                  size: 16),
                                              label: const Text('Add Hours'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: daySlots.map((slot) {
                                            return _buildSlotChip(slot);
                                          }).toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLastDay)
                            Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(AvailabilitySlot slot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: slot.isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: slot.isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: slot.isActive ? Colors.green.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '${slot.startTime} - ${slot.endTime}',
            style: TextStyle(
              color:
                  slot.isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showEditSlotDialog(slot),
            child: Icon(
              Icons.edit,
              size: 16,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _deleteSlot(slot),
            child: Icon(
              Icons.delete,
              size: 16,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSlotDialog({String? day}) async {
    String? selectedDay = day;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Availability Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Selection
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day of Week',
                    border: OutlineInputBorder(),
                  ),
                  items: _daysOfWeek.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(_dayLabels[d]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedDay = value);
                  },
                ),
                const SizedBox(height: 16),

                // Start Time
                ListTile(
                  title: const Text('Start Time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() => startTime = time);
                      }
                    },
                    child: Text(
                      startTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                // End Time
                ListTile(
                  title: const Text('End Time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() => endTime = time);
                      }
                    },
                    child: Text(
                      endTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createSlot(selectedDay!, startTime, endTime);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Slot'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSlot(
    String day,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.createAvailabilitySlot({
        'day_of_week': day,
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:'
            '${startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:'
            '${endTime.minute.toString().padLeft(2, '0')}',
        'timezone': 'America/New_York',
        'is_recurring': true,
        'max_concurrent_calls': 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability slot added'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailabilitySlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditSlotDialog(AvailabilitySlot slot) async {
    final parts = slot.startTime.split(':');
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final endParts = slot.endTime.split(':');
    TimeOfDay endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${_dayLabels[slot.dayOfWeek] ?? 'Slot'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Time'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      setState(() => startTime = time);
                    }
                  },
                  child: Text(
                    startTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setState(() => endTime = time);
                    }
                  },
                  child: Text(
                    endTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateSlot(slot, startTime, endTime);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSlot(
    AvailabilitySlot slot,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.updateAvailabilitySlot(slot.id, {
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:'
            '${startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:'
            '${endTime.minute.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot updated'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadAvailabilitySlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSlot(AvailabilitySlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
          'Delete ${_dayLabels[slot.dayOfWeek]} slot ${slot.startTime} - ${slot.endTime}?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = context.read<ApiService>();
        await apiService.deleteAvailabilitySlot(slot.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Slot deleted'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadAvailabilitySlots();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete slot: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

