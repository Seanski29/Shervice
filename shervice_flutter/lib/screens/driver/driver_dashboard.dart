import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';

// IMPORTANT: Using your project's constant file or inline definition
const String backendUrl = kIsWeb ? 'http://127.0.0.1:5000/api' : 'http://10.0.2.2:5000/api';

class DriverDashboard extends StatefulWidget {
  final String driverName;

  const DriverDashboard({super.key, required this.driverName});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _fetchAssignedTripData();
  }

  Future<void> _fetchAssignedTripData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          '$backendUrl/driver/active-trip/${Uri.encodeComponent(widget.driverName)}',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _activeTrip = data['active_trip'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Driver Dashboard Sync Failure: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── ROBUST SAFETY CHECK FOR BACKEND DATA ───
  bool _hasAssignedTripData() {
    if (_activeTrip == null) return false;

    // Check if the backend returned an empty map or specifically marked it empty
    if (_activeTrip!.isEmpty) return false;

    final routeName = _activeTrip!['route_name'];
    final departureTime = _activeTrip!['departure_time'];
    final status = _activeTrip!['status'];
    final plateNumber = _activeTrip!['plate_number'];

    final hasRouteInfo = routeName != null && routeName.toString().trim().isNotEmpty;
    final hasScheduleInfo = departureTime != null && departureTime.toString().trim().isNotEmpty;
    final hasStatusInfo = status != null && status.toString().trim().isNotEmpty;
    final hasVehicleInfo = plateNumber != null && plateNumber.toString().trim().isNotEmpty && plateNumber.toString().trim() != 'No Plate Assigned';

    // If we have AT LEAST ONE piece of valid dispatch data, render the card.
    return hasRouteInfo || hasScheduleInfo || hasStatusInfo || hasVehicleInfo;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedTripData,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Greeting Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CURRENT DISPATCH SECTION
            const Text(
              'CURRENT DISPATCH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // ─── SAFE CONDITIONAL RENDERING ───
            if (_hasAssignedTripData())
              _buildActiveTripCard()
            else
              _buildEmptyTripPlaceholder(),

            const SizedBox(height: 24),

            // ASSIGNED VEHICLE SECTION
            const Text(
              'ASSIGNED VEHICLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_hasAssignedTripData()) 
              _buildVehicleDetailsCard()
            else 
              _buildEmptyVehiclePlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard() {
    // We already passed the `_hasAssignedTripData()` check to get here, so we know `_activeTrip` is not null.
    final status = _activeTrip!['status'] ?? 'SCHEDULED';
    final isOngoing = status == 'ONGOING';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TRP-${_activeTrip!['trip_id'] ?? 'TBD'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.green.shade400
                      : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimelineRow(
            Icons.my_location,
            'ROUTE PLAN',
            _activeTrip!['route_name']?.toString() ?? 'Pending Assignment',
            _activeTrip!['departure_time']?.toString() ?? '--:--',
            Colors.blue.shade200,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRouteDetail(
                  Icons.people_alt_outlined,
                  'Passengers',
                  '${_activeTrip!['passenger_count'] ?? 0} Logged',
                ),
                _buildRouteDetail(
                  Icons.straighten,
                  'Distance',
                  '${_activeTrip!['route_distance'] ?? 0} km',
                ),
                _buildRouteDetail(
                  Icons.pin_drop_outlined,
                  'Status',
                  isOngoing ? 'In Transit' : 'Pending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTripPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No route or schedule assigned',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh when your assigned route becomes available from dispatch.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsCard() {
    final plate = _activeTrip!['plate_number']?.toString() ?? 'UNASSIGNED';
    final model = _activeTrip!['model']?.toString() ?? 'Contact Staff Dispatcher';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car,
              size: 32,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  model,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
            tooltip: 'Scan Vehicle QR',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehiclePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, color: Colors.grey.shade400, size: 28),
            const SizedBox(width: 12),
            Text(
              'No vehicle keys assigned to your profile.',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    IconData icon,
    String label,
    String location,
    String time,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}