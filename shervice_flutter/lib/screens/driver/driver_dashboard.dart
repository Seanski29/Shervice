import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../../constant.dart';
import '../../widgets/driver/driver_rating_badge.dart';

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
  // --- STATE ---
  bool _isLoading = true;
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _fetchAssignedTripData();
  }

  // --- DATA FETCHING ---
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

  // --- MODALS ---
  void _showPassengerQR(String tripId, bool isDark) {
    final String baseUrl = backendUrl.replaceAll('/api', '');
    final String evalUrl = '$baseUrl/evaluate?trip_id=$tripId';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.transparent,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Passenger Evaluation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask passengers to scan this code as they exit to submit a review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.grey.shade400
                      : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              // QR Must ALWAYS be on a white background for scanner reliability
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: evalUrl,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
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

  // --- UTILS ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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

    return '$formattedDeparture - $formattedEta';
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final double horizontalPadding = isMobile ? 16.0 : 32.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              // ----- HEADER -----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${widget.driverName}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your current dispatch and vehicle assignment overview.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.amber.withOpacity(0.15)
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.amber.shade200,
                      ),
                    ),
                    child: DriverRatingBadge(
                      key: UniqueKey(),
                      driverUuid: widget.driverId,
                      backendUrl: backendUrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ----- MAIN CONTENT AREA -----
              if (isMobile) ...[
                _buildSectionHeader('CURRENT DISPATCH'),
                const SizedBox(height: 12),
                if (_hasAssignedTripData())
                  _buildActiveTripCard(isDark)
                else
                  _buildEmptyTripPlaceholder(isDark),
                const SizedBox(height: 24),
                _buildSectionHeader('ASSIGNED VEHICLE'),
                const SizedBox(height: 12),
                if (_hasAssignedTripData())
                  _buildVehicleDetailsCard(isDark)
                else
                  _buildEmptyVehiclePlaceholder(isDark),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('CURRENT DISPATCH'),
                          const SizedBox(height: 12),
                          if (_hasAssignedTripData())
                            _buildActiveTripCard(isDark)
                          else
                            _buildEmptyTripPlaceholder(isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('ASSIGNED VEHICLE'),
                          const SizedBox(height: 12),
                          if (_hasAssignedTripData())
                            _buildVehicleDetailsCard(isDark)
                          else
                            _buildEmptyVehiclePlaceholder(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.0,
      ),
    );
  }

  // --- TRIP CARD (Maintains the vibrant gradient for primary focus) ---
  Widget _buildActiveTripCard(bool isDark) {
    final status = _activeTrip!['status'] ?? 'SCHEDULED';
    final isOngoing = status == 'ONGOING';
    final departureTime = _activeTrip!['departure_time']?.toString();
    final estimatedArrival = _activeTrip!['estimated_arrival_time']?.toString();

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF172554)]
              : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.15),
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
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineRow(
            Icons.my_location,
            'ROUTE / DESTINATION',
            _activeTrip!['route_name']?.toString() ?? 'Pending Assignment',
            _formatDepartureEta(departureTime, estimatedArrival),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildRouteDetail(details[0])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRouteDetail(details[1])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRouteDetail(details[2])),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRouteDetail(details[3])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showPassengerQR(_activeTrip!['trip_id'].toString(), isDark),
              icon: const Icon(
                Icons.qr_code,
                color: Color(0xFF1E3A8A),
                size: 20,
              ),
              label: const Text(
                'Show Passenger QR',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
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

  Widget _buildRouteDetail(Map<String, dynamic> detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(detail['icon'], color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              detail['label'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          detail['value'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTimelineRow(
    IconData icon,
    String label,
    String location,
    String time,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
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
                  letterSpacing: 0.8,
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
                maxLines: 2,
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

  Widget _buildEmptyTripPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No active assignment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh when dispatch assigns a trip.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- VEHICLE CARD ---
  Widget _buildVehicleDetailsCard(bool isDark) {
    final plate = _activeTrip!['plate_number']?.toString() ?? 'UNASSIGNED';
    final model =
        _activeTrip!['model']?.toString() ?? 'Contact Staff Dispatcher';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_car,
              size: 28,
              color: isDark ? Colors.blue.shade400 : const Color(0xFF0F172A),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  model,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Color.fromARGB(255, 240, 241, 244),
            ),
            tooltip: 'Scan QR',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehiclePlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.key_off,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'No vehicle assigned.',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
