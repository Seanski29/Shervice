import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../constant.dart';

class OicTrips extends StatefulWidget {
  final String oicId;

  const OicTrips({super.key, required this.oicId});

  @override
  State<OicTrips> createState() => _OicTripsState();
}

class _OicTripsState extends State<OicTrips> {
  String _searchTerm = '';
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeploymentLogs();
  }

  Future<void> _fetchDeploymentLogs() async {
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/oic/${widget.oicId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _trips = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching deployment logs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimeString(dynamic timeVal) {
    if (timeVal == null || timeVal.toString().trim().isEmpty) return '--:--';
    String t = timeVal.toString();
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }

  // ─── STATS ───
  int get _totalTrips => _trips.length;
  int get _scheduledTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'scheduled').length;
  int get _ongoingTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'ongoing').length;
  int get _completedTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'completed').length;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    final filteredTrips = _trips.where((trip) {
      final route = (trip['route_name'] ?? '').toString().toLowerCase();
      final driver = (trip['driver_name'] ?? '').toString().toLowerCase();
      final search = _searchTerm.toLowerCase();
      return route.contains(search) || driver.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchDeploymentLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Comprehensive log of all fleet deployments.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _fetchDeploymentLogs();
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 20),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── STATS CHIPS ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(Icons.list_alt, _totalTrips.toString(), 'Total', const Color(0xFF3B82F6)),
                  _statChip(Icons.event_available, _scheduledTrips.toString(), 'Scheduled', const Color(0xFFF59E0B)),
                  _statChip(Icons.play_arrow, _ongoingTrips.toString(), 'Ongoing', const Color(0xFF10B981)),
                  _statChip(Icons.check_circle, _completedTrips.toString(), 'Completed', const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 10),

              // ── SEARCH ──
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchTerm = val),
                  decoration: InputDecoration(
                    hintText: 'Search trips...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── TRIP LIST ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                      )
                    : filteredTrips.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No trips found.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredTrips.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final trip = filteredTrips[index];
                              return _buildTripCard(trip);
                            },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = (trip['trip_status'] ?? 'Scheduled').toString();
    final driver = trip['driver_name'] ?? 'Unassigned';
    final plate = trip['plate_number'] ?? 'No Plate';
    final route = trip['route_name'] ?? 'Unknown Route';
    final pax = trip['passenger_count'] ?? 0;
    final distance = trip['route_distance'] ?? 0;
    final dep = _formatTimeString(trip['departure_time']);
    final arr = _formatTimeString(trip['estimated_arrival_time']);

    Color statusColor;
    String statusLabel;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'COMPLETED';
        break;
      case 'ongoing':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'ONGOING';
        break;
      case 'scheduled':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'SCHEDULED';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status indicator bar
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'TRIP-${trip['trip_id']} • $route',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _infoChip(Icons.person, driver),
                    _infoChip(Icons.directions_car, plate),
                    _infoChip(Icons.people, '$pax pax'),
                    _infoChip(Icons.straighten, '$distance km'),
                    _infoChip(Icons.access_time, '$dep → $arr'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: const Color(0xFF64748B)),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}