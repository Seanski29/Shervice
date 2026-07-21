import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import '../../constant.dart';
import '../../widgets/driver_rating_badge.dart';

class DriverDashboard extends StatefulWidget {
  final String driverName;
  final String driverId;

  const DriverDashboard({
    super.key,
    required this.driverName,
    required this.driverId,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Evaluation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask passengers to scan this code as they exit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: QrImageView(
                  data: evalUrl,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedTripData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER (consistent with admin) ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning, ${widget.driverName}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your current dispatch and vehicle status.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
              const SizedBox(height: 20),

              // ── CURRENT DISPATCH ──
              const Text(
                'CURRENT DISPATCH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_hasAssignedTripData())
                _buildActiveTripCard()
              else
                _buildEmptyTripPlaceholder(),
              const SizedBox(height: 20),

              // ── ASSIGNED VEHICLE ──
              const Text(
                'ASSIGNED VEHICLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_hasAssignedTripData())
                _buildVehicleDetailsCard()
              else
                _buildEmptyVehiclePlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard() {
    final status = _activeTrip!['status'] ?? 'SCHEDULED';
    final isOngoing = status == 'ONGOING';
    final departureTime = _activeTrip!['departure_time']?.toString();
    final estimatedArrival = _activeTrip!['estimated_arrival_time']?.toString();

    // ── Route details data ──
    final details = [
      {
        'icon': Icons.people_alt_outlined,
        'label': 'Passengers',
        'value': '${_activeTrip!['passenger_count'] ?? 0}',
      },
      {
        'icon': Icons.straighten,
        'label': 'Distance',
        'value': '${_activeTrip!['route_distance'] ?? 0} km',
      },
      {
        'icon': Icons.access_time,
        'label': 'Schedule',
        'value': _formatDepartureEta(departureTime, estimatedArrival),
      },
      {
        'icon': Icons.pin_drop_outlined,
        'label': 'Status',
        'value': isOngoing ? 'In Transit' : 'Pending',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(76),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TRP-${_activeTrip!['trip_id'] ?? 'TBD'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineRow(
            Icons.my_location,
            'ROUTE',
            _activeTrip!['route_name']?.toString() ?? 'Pending Assignment',
            _formatDepartureEta(departureTime, estimatedArrival),
            Colors.blue.shade200,
          ),
          const SizedBox(height: 16),
          // ── 2x2 GRID for details ──
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildRouteDetail(details[0])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRouteDetail(details[1])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildRouteDetail(details[2])),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRouteDetail(details[3])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showPassengerQR(_activeTrip!['trip_id'].toString()),
              label: const Text(
                'Show QR',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── New method to build a single detail item (used in 2x2 grid) ──
  Widget _buildRouteDetail(Map<String, dynamic> detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(detail['icon'], color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Text(
              detail['label'],
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          detail['value'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTripPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No route or schedule assigned',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pull down to refresh when dispatch assigns a trip.',
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car,
              size: 28,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Scan QR',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehiclePlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.key_off, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 8),
          Text(
            'No vehicle assigned to your profile.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
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
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
            fontSize: 13,
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
}
