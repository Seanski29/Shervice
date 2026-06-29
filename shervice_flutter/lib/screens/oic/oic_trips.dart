import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

class OicTrips extends StatefulWidget {
  final String oicId;

  const OicTrips({super.key, required this.oicId});

  @override
  State<OicTrips> createState() => _OicTripsState();
}

class _OicTripsState extends State<OicTrips> {
  String _searchTerm = '';
  String _sortOrder = 'Newest First'; // 👈 Added sort state
  List<dynamic> _trips = [];
  bool _isLoading = true;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchDeploymentLogs();
  }

  Future<void> _fetchDeploymentLogs() async {
    try {
      final res = await http.get(
        Uri.parse('$_backendUrl/schedules/oic/${widget.oicId}'),
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // Dynamically searches by Route Name or Driver Name
    final filteredTrips = _trips.where((trip) {
      final route = (trip['route_name'] ?? '').toString().toLowerCase();
      final driver = (trip['driver_name'] ?? '').toString().toLowerCase();
      final search = _searchTerm.toLowerCase();
      return route.contains(search) || driver.contains(search);
    }).toList();

    // 👈 Sort logic applied to the filtered list
    filteredTrips.sort((a, b) {
      // Parse the date robustly
      DateTime dateA = DateTime.tryParse(a['schedule_date']?.toString() ?? a['departure_date']?.toString() ?? '') ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b['schedule_date']?.toString() ?? b['departure_date']?.toString() ?? '') ?? DateTime(2000);
      
      // If dates match exactly, sort by ID as a fallback chronological measure
      if (dateA == dateB) {
        int idA = a['trip_id'] ?? a['id'] ?? 0;
        int idB = b['trip_id'] ?? b['id'] ?? 0;
        return _sortOrder == 'Newest First' ? idB.compareTo(idA) : idA.compareTo(idB);
      }
      
      // Compare dates based on selection
      return _sortOrder == 'Newest First' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Responsive Header using Wrap to adapt to mobile/desktop automatically
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comprehensive log of all fleet deployments and passenger counts.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              // FIX: Bounded width on desktop, full width on mobile
              SizedBox(
                width: isMobile ? double.infinity : 420, // 👈 Expanded width for sort dropdown
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchTerm = val),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 👈 Dropdown for Sorting Logic
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortOrder,
                            isExpanded: true,
                            icon: const Icon(Icons.sort, color: Colors.grey, size: 20),
                            items: ['Newest First', 'Oldest First'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value, 
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortOrder = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // List Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
              ]
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.blue.shade600, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Deployment Logs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 22),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchDeploymentLogs();
                        },
                        tooltip: "Refresh Logs",
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredTrips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No deployment records found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTrips.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      final String status = trip['trip_status'] ?? 'Scheduled';

                      Color statusColor = Colors.orange;
                      if (status == 'Completed') {
                        statusColor = Colors.green;
                      } else if (status == 'Ongoing') {
                        statusColor = Colors.blue;
                      }

                      // FIX: Unified, responsive Card layout for individual logs
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "TRP-${trip['trip_id'] ?? trip['id']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trip['route_name'] ?? 'Unknown Route',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
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
                            const SizedBox(height: 16),
                            // FIX: Wrap gracefully handles metadata pushing to the next line on small screens
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,
                              children: [
                                // 👈 Rendered Date explicitly to reflect sorting
                                _buildInfoChip(
                                  icon: Icons.calendar_today,
                                  label: trip['schedule_date'] ?? trip['departure_date'] ?? 'No Date',
                                ),
                                _buildInfoChip(
                                  icon: Icons.person,
                                  label: trip['driver_name'] ?? 'Unassigned',
                                ),
                                _buildInfoChip(
                                  icon: Icons.local_shipping,
                                  label: trip['plate_number'] ?? 'No Plate Assigned',
                                ),
                                _buildInfoChip(
                                  icon: Icons.access_time,
                                  label: trip['departure_time']?.toString().substring(0, 5) ?? '--:--',
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${trip['passenger_count'] ?? 0} Pax',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}