import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import '../../constant.dart';

// 1. ADDED IMPORT FOR THE BADGE
import '../../widgets/driver_rating_badge.dart';

class DriverDashboard extends StatefulWidget {
  final String driverName;
  final String driverId; // 2. DRIVER ID ADDED HERE

  const DriverDashboard({
    super.key,
    required this.driverName,
    required this.driverId, // 2. DRIVER ID REQUIRED HERE
  });

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

  bool _hasAssignedTripData() {
    if (_activeTrip == null) return false;
    if (_activeTrip!.isEmpty) return false;

    final routeName = _activeTrip!['route_name'];
    final departureTime = _activeTrip!['departure_time'];
    final estimatedArrival = _activeTrip!['estimated_arrival_time'];
    final status = _activeTrip!['status'];
    final plateNumber = _activeTrip!['plate_number'];

    final hasRouteInfo =
        routeName != null && routeName.toString().trim().isNotEmpty;
    final hasScheduleInfo =
        departureTime != null && departureTime.toString().trim().isNotEmpty;
    final hasEtaInfo =
        estimatedArrival != null &&
        estimatedArrival.toString().trim().isNotEmpty;
    final hasStatusInfo = status != null && status.toString().trim().isNotEmpty;
    final hasVehicleInfo =
        plateNumber != null &&
        plateNumber.toString().trim().isNotEmpty &&
        plateNumber.toString().trim() != 'No Plate Assigned';

    return hasRouteInfo ||
        hasScheduleInfo ||
        hasEtaInfo ||
        hasStatusInfo ||
        hasVehicleInfo;
  }

  void _showPassengerQR(String tripId) {
    final String baseUrl = backendUrl.replaceAll('/api', '');
    final String evalUrl = '$baseUrl/evaluate?trip_id=$tripId';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Passenger Evaluation',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask passengers to scan this code as they exit to evaluate the trip.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: evalUrl,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
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
                // 3. HARDCODED RATING REPLACED HERE
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
                  child: DriverRatingBadge(
                    key: UniqueKey(),
                    driverUuid: widget.driverId,
                    backendUrl: backendUrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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

            if (_hasAssignedTripData())
              _buildActiveTripCard()
            else
              _buildEmptyTripPlaceholder(),

            const SizedBox(height: 24),

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
    final status = _activeTrip!['status'] ?? 'SCHEDULED';
    final isOngoing = status == 'ONGOING';
    final departureTime = _activeTrip!['departure_time']?.toString();
    final estimatedArrival = _activeTrip!['estimated_arrival_time']?.toString();

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
            _formatDepartureEta(departureTime, estimatedArrival),
            Colors.blue.shade200,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
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
                  Icons.access_time,
                  'Schedule',
                  _formatDepartureEta(departureTime, estimatedArrival),
                ),
                _buildRouteDetail(
                  Icons.pin_drop_outlined,
                  'Status',
                  isOngoing ? 'In Transit' : 'Pending',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showPassengerQR(_activeTrip!['trip_id'].toString()),
              icon: const Icon(Icons.qr_code, color: Colors.blue),
              label: const Text(
                'Show Passenger QR',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final model =
        _activeTrip!['model']?.toString() ?? 'Contact Staff Dispatcher';

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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  String _formatDepartureEta(String? departureTime, String? etaTime) {
    final departure = departureTime?.trim();
    final eta = etaTime?.trim();

    final formattedDeparture = departure != null && departure.isNotEmpty
        ? (departure.length >= 5 ? departure.substring(0, 5) : departure)
        : '--:--';
    final formattedEta = eta != null && eta.isNotEmpty
        ? (eta.length >= 5 ? eta.substring(0, 5) : eta)
        : '--:--';

    return '$formattedDeparture-$formattedEta';
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
