import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class StaffTrips extends StatefulWidget {
  final String staffId;

  const StaffTrips({super.key, required this.staffId});

  @override
  State<StaffTrips> createState() => _StaffTripsState();
}

class _StaffTripsState extends State<StaffTrips> {
  String _searchTerm = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Scheduled', 'Ongoing', 'Completed'];
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaffLogs();
  }

  Future<void> _fetchStaffLogs() async {
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/staff/${widget.staffId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _trips = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching staff logs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredTrips {
    return _trips.where((trip) {
      // Search filter
      final route = (trip['route_name'] ?? '').toString().toLowerCase();
      final driver = (trip['driver_name'] ?? '').toString().toLowerCase();
      final client = (trip['client_company'] ?? '').toString().toLowerCase();
      final search = _searchTerm.toLowerCase();
      final matchesSearch = route.contains(search) ||
          driver.contains(search) ||
          client.contains(search);

      // Status filter
      final status = (trip['trip_status'] ?? '').toString().toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          status == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalTrips => _trips.length;
  int get _scheduledTrips => _trips
      .where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'scheduled')
      .length;
  int get _ongoingTrips => _trips
      .where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'ongoing')
      .length;
  int get _completedTrips => _trips
      .where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'completed')
      .length;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'ongoing':
        return const Color(0xFF3B82F6);
      case 'scheduled':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;
    final filteredTrips = _filteredTrips;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchStaffLogs,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Dispatched Trips',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'History of trips you have actively assigned.',
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
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _fetchStaffLogs();
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── STATS CHIPS ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(Icons.event, _totalTrips.toString(), 'Total', const Color(0xFF3B82F6)),
                  _statChip(Icons.schedule, _scheduledTrips.toString(), 'Scheduled', const Color(0xFFF59E0B)),
                  _statChip(Icons.play_arrow, _ongoingTrips.toString(), 'Ongoing', const Color(0xFF3B82F6)),
                  _statChip(Icons.check_circle, _completedTrips.toString(), 'Completed', const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 12),

              // ── SEARCH & FILTER ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 280,
                      minWidth: isMobile ? double.infinity : 200,
                    ),
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchTerm = val),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 160,
                      minWidth: isMobile ? double.infinity : 120,
                    ),
                    child: SizedBox(
                      height: 38,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _statusFilter,
                            icon: const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                            items: _statusOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() => _statusFilter = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── TRIP LIST ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                      : filteredTrips.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No trips found.',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredTrips.length,
                              itemBuilder: (context, index) {
                                final trip = filteredTrips[index];
                                return _buildTripCard(trip);
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = (trip['trip_status'] ?? 'Unknown').toString();
    final statusColor = _statusColor(status);
    final driver = trip['driver_name'] ?? 'Unassigned';
    final plate = trip['plate_number'] ?? 'N/A';
    final route = trip['route_name'] ?? 'Unknown Route';
    final client = trip['client_company'] ?? 'Unknown Client';
    final date = trip['schedule_date'] ?? 'TBD';
    final departure = trip['departure_time']?.toString().substring(0, 5) ?? '--:--';
    final arrival = trip['estimated_arrival_time']?.toString().substring(0, 5) ?? '--:--';
    final passengers = trip['passenger_count'] ?? 0;
    final distance = trip['route_distance'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROW: ROUTE + STATUS ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  route,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── CLIENT + DATE ──
          Row(
            children: [
              Icon(Icons.business, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  client,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.calendar_today, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── DRIVER + VEHICLE ──
          Row(
            children: [
              Icon(Icons.person, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                driver,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.directions_car, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                plate,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── TIME + PASSENGERS + DISTANCE ──
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _infoChip(Icons.access_time, '$departure - $arrival'),
              _infoChip(Icons.people, '$passengers pax'),
              _infoChip(Icons.straighten, '$distance km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}