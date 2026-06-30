import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class DriverSchedules extends StatefulWidget {
  final String driverId; // Pass the logged-in driver's UUID
  const DriverSchedules({super.key, required this.driverId});

  @override
  State<DriverSchedules> createState() => _DriverSchedulesState();
}

class _DriverSchedulesState extends State<DriverSchedules> {
  bool _isLoading = true;
  List<dynamic> _myTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchMySchedules();
  }

  Future<void> _fetchMySchedules() async {
    try {
      // Fetch only the trips assigned to this specific driver
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/driver/${widget.driverId}'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _myTrips = jsonDecode(res.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTripStatus(int tripId, String newStatus) async {
    try {
      final res = await http.post(
        Uri.parse(
          '$backendUrl/schedules/update-status',
        ), // We will create this Python route next!
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"trip_id": tripId, "status": newStatus}),
      );
      if (res.statusCode == 200 && mounted) {
        _fetchMySchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Completed'
                  ? "Trip Finished! Assets Released."
                  : "Trip Started! Drive safely.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating trip: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                const Text(
                  'My Schedule',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                ..._myTrips.map((t) => _buildScheduleCard(t)),
              ],
            ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> trip) {
    final String status = trip['trip_status'] ?? 'Scheduled';
    Color statusColor = Colors.grey;
    Color bgColor = Colors.grey.shade100;

    if (status == 'Ongoing') {
      statusColor = Colors.blue.shade700;
      bgColor = Colors.blue.shade50;
    } else if (status == 'Completed') {
      statusColor = Colors.green.shade700;
      bgColor = Colors.green.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20.0),
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
                trip['schedule_date'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                trip['route_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Departure: ${trip['departure_time']}",
            style: TextStyle(color: Colors.grey.shade600),
          ),

          if (status == 'Scheduled') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateTripStatus(trip['trip_id'], 'Ongoing'),
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Start Trip",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (status == 'Ongoing') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _updateTripStatus(trip['trip_id'], 'Completed'),
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Finish Trip",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
