import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class OicSchedules extends StatefulWidget {
  final String oicId; // ✅ Require the UUID from the layout

  const OicSchedules({super.key, required this.oicId});

  @override
  State<OicSchedules> createState() => _OicSchedulesState();
}

class _OicSchedulesState extends State<OicSchedules> {
  bool _isLoading = true;
  List<dynamic> _myTrips = [];
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    try {
      // ✅ Use the dynamic UUID!
      final response = await http.get(
        Uri.parse('$backendUrl/schedules/oic/${widget.oicId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _myTrips = data['data'];
            _isLoading = false;
          });
          return;
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewScheduleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // ✅ Pass the UUID down into the dialog so they can create trips
      builder: (BuildContext context) =>
          CreateTripRequestDialog(oicId: widget.oicId),
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchMyTrips();
      }
    });
  }

  List<dynamic> get _recentSchedules {
    final sorted = [..._myTrips]
      ..sort((a, b) {
        final aDate = _parseDate(a['schedule_date']);
        final bDate = _parseDate(b['schedule_date']);
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
    return sorted.take(4).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      try {
        return DateTime.parse(text.split(' ').first);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  List<dynamic> _schedulesForDate(DateTime day) {
    return _myTrips.where((trip) {
      final date = _parseDate(trip['schedule_date']);
      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  void _showDayDetailsDialog(DateTime day, List<dynamic> schedules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_formatDateLabel(day)),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = schedules[index];
              final isPending = trip['trip_status']?.toString().toLowerCase().contains('pending') ?? false;
              final statusColor = isPending ? Colors.orange.shade700 : Colors.green.shade700;
              final statusBg = isPending ? Colors.orange.shade50 : Colors.green.shade50;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip['route_name'] ?? 'Unknown Route',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            trip['trip_status']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Departure: ${_formatTime(trip['departure_time'])}  •  ETA: ${_formatTime(trip['estimated_arrival_time'])}'),
                    const SizedBox(height: 4),
                    Text('Passengers: ${trip['passenger_count'] ?? 0}  •  Distance: ${trip['route_distance'] ?? 0} km'),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentSchedules = _recentSchedules;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysBefore = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = ((daysBefore + daysInMonth) / 7).ceil() * 7;
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Trip Requests',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A calendar view of your recent schedules and dispatches.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewScheduleModal(context),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'New Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Schedules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (recentSchedules.isEmpty)
                  const Text('No schedules recorded yet.', style: TextStyle(color: Colors.grey))
                else
                  ...recentSchedules.map((trip) {
                    final isPending = trip['trip_status']?.toString().toLowerCase().contains('pending') ?? false;
                    final statusColor = isPending ? Colors.orange.shade700 : Colors.green.shade700;
                    final statusBg = isPending ? Colors.orange.shade50 : Colors.green.shade50;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip['route_name'] ?? 'Unknown Route',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${trip['schedule_date'] ?? ''} • ${_formatTime(trip['departure_time'])} → ${_formatTime(trip['estimated_arrival_time'])}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trip['trip_status']?.toString() ?? 'Unknown',
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, index - daysBefore + 1);
                    final isCurrentMonth = date.month == _focusedMonth.month;
                    final schedules = _schedulesForDate(date);
                    final isOccupied = schedules.isNotEmpty;
                    final isSelected = _selectedDate != null &&
                        _selectedDate!.year == date.year &&
                        _selectedDate!.month == date.month &&
                        _selectedDate!.day == date.day;
                    final isToday = now.year == date.year && now.month == date.month && now.day == date.day;

                    return InkWell(
                      onTap: isOccupied
                          ? () {
                              setState(() => _selectedDate = date);
                              _showDayDetailsDialog(date, schedules);
                            }
                          : () => setState(() => _selectedDate = date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : isOccupied
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? Colors.blue.shade300 : Colors.transparent,
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth ? Colors.black87 : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isOccupied)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  schedules.length > 1 ? '${schedules.length}' : '1',
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── NEW TRIP REQUEST FORM DIALOG ───
class CreateTripRequestDialog extends StatefulWidget {
  final String oicId; // ✅ Require the UUID here too

  const CreateTripRequestDialog({super.key, required this.oicId});

  @override
  State<CreateTripRequestDialog> createState() =>
      _CreateTripRequestDialogState();
}

class _CreateTripRequestDialogState extends State<CreateTripRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _loadingStaff = true;

  List<dynamic> _staffMembers = [];
  String? _selectedStaffId;

  final _destinationController = TextEditingController();
  final _passengerController = TextEditingController();
  final _distanceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedArrivalTime;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/schedules/staff-options'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && mounted) {
        setState(() {
          _staffMembers = data['data'];
          _loadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedArrivalTime == null ||
        _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
    final formattedETA =
        "${_selectedArrivalTime!.hour.toString().padLeft(2, '0')}:${_selectedArrivalTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/schedules/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "oic_id": widget.oicId,
          "staff_id": _selectedStaffId,
          "destination": _destinationController.text.trim(),
          "passenger_count": _passengerController.text.trim(),
          "route_distance": _distanceController.text.trim(),
          "departure_date": formattedDate,
          "departure_time": formattedTime,
          "estimated_arrival_time": formattedETA,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip requested successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message'] ?? "Failed to submit request.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Request New Schedule",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingStaff)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign to Dispatch Staff",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.support_agent),
                    ),
                    value: _selectedStaffId,
                    items: _staffMembers
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['user_id'],
                            child: Text(s['full_name'] ?? 'Staff'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStaffId = val),
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _destinationController,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(
                    labelText: "Route / Destination",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),

                // 👇 NEW DISTANCE FIELD
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Required";
                    if (double.tryParse(val) == null)
                      return "Must be a valid number";
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: "Distance (km)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passengerController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Required";
                    if (int.tryParse(val) == null)
                      return "Must be a valid number";
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: "Number of Passengers",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setState(() => _selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? "Select Date"
                                : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null)
                            setState(() => _selectedTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Departure',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedTime == null
                                ? "Time"
                                : _selectedTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 👇 THE NEW ETA PICKER
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null)
                            setState(() => _selectedArrivalTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'ETA',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedArrivalTime == null
                                ? "Arrival"
                                : _selectedArrivalTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text(
                  "Submit Request",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
