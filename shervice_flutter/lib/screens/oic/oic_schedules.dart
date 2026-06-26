import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OicSchedules extends StatefulWidget {
  const OicSchedules({super.key});

  @override
  State<OicSchedules> createState() => _OicSchedulesState();
}

class _OicSchedulesState extends State<OicSchedules> {
  bool _isLoading = true;
  List<dynamic> _myTrips = [];

  // TODO: Replace with the actual logged-in OIC integer ID later
  final int currentOicId = 1;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/schedules/oic/$currentOicId'),
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
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewScheduleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const CreateTripRequestDialog(),
    ).then((_) {
      // Refresh the list when the modal closes!
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchMyTrips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                  'Track the status of your fleet requests.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showNewScheduleModal(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'New Request',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_myTrips.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "You have no scheduled trips.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._myTrips.map((trip) {
            final bool isPending = trip['trip_status'].toString().contains(
              'Pending',
            );
            final Color statusColor = isPending
                ? Colors.orange.shade700
                : Colors.green.shade700;
            final Color statusBg = isPending
                ? Colors.orange.shade50
                : Colors.green.shade50;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
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
                        trip['route_name'] ?? 'Unknown Route',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trip['trip_status'],
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _iconText(Icons.calendar_today, trip['schedule_date']),
                      const SizedBox(width: 24),
                      _iconText(
                        Icons.access_time,
                        trip['departure_time'].toString().substring(0, 5),
                      ), // Trims seconds
                      const SizedBox(width: 24),
                      _iconText(
                        Icons.people,
                        "${trip['passenger_count']} Passengers",
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
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
  const CreateTripRequestDialog({super.key});

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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/schedules/staff-options'),
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

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/schedules/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "oic_id": 1, // Will be dynamic later
          "staff_id": _selectedStaffId,
          "destination": _destinationController.text.trim(),
          "passenger_count": _passengerController.text.trim(),
          "departure_date": formattedDate,
          "departure_time": formattedTime,
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
                  const SizedBox(width: 16),
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
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? "Select Time"
                              : _selectedTime!.format(context),
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
