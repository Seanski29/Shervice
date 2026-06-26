import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StaffSchedules extends StatefulWidget {
  final String staffId;
  const StaffSchedules({super.key, required this.staffId});

  @override
  State<StaffSchedules> createState() => _StaffSchedulesState();
}

class _StaffSchedulesState extends State<StaffSchedules> {
  bool _isLoading = true;
  List<dynamic> _assignedTrips = [];

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchStaffDashboardData();
  }

  Future<void> _fetchStaffDashboardData() async {
    try {
      final tripsResponse = await http.get(
        Uri.parse('$_backendUrl/schedules/staff/${widget.staffId}'),
      );

      if (tripsResponse.statusCode == 200 && mounted) {
        final tripsData = jsonDecode(tripsResponse.body);
        setState(() {
          _assignedTrips = tripsData['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssignModal(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignTripDialog(
        trip: trip,
        backendUrl: _backendUrl,
        onSuccess: () {
          setState(() => _isLoading = true);
          _fetchStaffDashboardData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dispatch & Scheduling',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchStaffDashboardData();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MAIN TRIP LIST
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _assignedTrips.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text("No trips routed to your queue."),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _assignedTrips.length,
                            separatorBuilder: (c, i) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final trip = _assignedTrips[i];
                              final bool needsAssignment =
                                  trip['user_id'] == null ||
                                  trip['vehicle_id'] == null;

                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip['route_name'] ??
                                              'Unspecified Route',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                trip['departure_time']
                                                    .toString()
                                                    .substring(0, 5),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                trip['schedule_date'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (needsAssignment)
                                      ElevatedButton.icon(
                                        onPressed: () => _showAssignModal(trip),
                                        icon: const Icon(
                                          Icons.assignment_ind,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Assign Assets",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade700,
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Scheduled",
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 24),

                // INSTRUCTIONS PANEL
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Smart Dispatch',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'When you click "Assign Assets", the system automatically checks the date and removes any drivers or vehicles that are already scheduled to drive that day.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── DEDICATED ASSIGNMENT MODAL WIDGET ───
// Extracts the logic so it fetches live availability the moment you open it
class AssignTripDialog extends StatefulWidget {
  final Map<String, dynamic> trip;
  final String backendUrl;
  final VoidCallback onSuccess;

  const AssignTripDialog({
    super.key,
    required this.trip,
    required this.backendUrl,
    required this.onSuccess,
  });

  @override
  State<AssignTripDialog> createState() => _AssignTripDialogState();
}

class _AssignTripDialogState extends State<AssignTripDialog> {
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;

  List<dynamic> _drivers = [];
  List<dynamic> _vehicles = [];

  String? _selectedDriverUuid;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    try {
      // Passes the specific date of THIS trip to Python
      final String tripDate = widget.trip['schedule_date'];
      final res = await http.get(
        Uri.parse(
          '${widget.backendUrl}/schedules/dispatch-options?date=$tripDate',
        ),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _drivers = data['drivers'] ?? [];
          _vehicles = data['vehicles'] ?? [];
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedDriverUuid == null || _selectedVehicleId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await http.post(
        Uri.parse('${widget.backendUrl}/schedules/assign'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "trip_id": widget.trip['trip_id'],
          "driver_uuid": _selectedDriverUuid,
          "vehicle_id": int.parse(_selectedVehicleId!),
        }),
      );
      if (res.statusCode == 200 && mounted) {
        Navigator.pop(context); // Close modal
        widget.onSuccess(); // Trigger parent refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip assigned successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Dispatch: ${widget.trip['route_name']}"),
      content: _isLoadingOptions
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Date: ${widget.trip['schedule_date']}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (_drivers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: const Text(
                      "⚠️ No drivers available for this date.",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign Available Driver",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDriverUuid,
                    items: _drivers
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d['user_id'],
                            child: Text(d['full_name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDriverUuid = val),
                  ),

                const SizedBox(height: 16),

                if (_vehicles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: const Text(
                      "⚠️ No vehicles available for this date.",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assign Available Vehicle",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedVehicleId,
                    items: _vehicles
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['vehicle_id'].toString(),
                            child: Text(
                              "${v['plate_number']} (${v['bus_type']})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedVehicleId = val),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
          onPressed:
              (_isSubmitting ||
                  _selectedDriverUuid == null ||
                  _selectedVehicleId == null)
              ? null
              : _submitAssignment,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Confirm Schedule",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
