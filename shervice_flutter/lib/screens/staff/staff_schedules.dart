import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

String _formatTimeRange(String? departureTime, String? etaTime) {
  final departure = departureTime?.toString().trim();
  final eta = etaTime?.toString().trim();

  final formattedDeparture = departure != null && departure.isNotEmpty
      ? (departure.length >= 5 ? departure.substring(0, 5) : departure)
      : '--:--';
  final formattedEta = eta != null && eta.isNotEmpty
      ? (eta.length >= 5 ? eta.substring(0, 5) : eta)
      : '--:--';

  return '$formattedDeparture-$formattedEta';
}

class StaffSchedules extends StatefulWidget {
  final String staffId;
  const StaffSchedules({super.key, required this.staffId});

  @override
  State<StaffSchedules> createState() => _StaffSchedulesState();
}

class _StaffSchedulesState extends State<StaffSchedules> {
  bool _isLoading = true;
  List<dynamic> _assignedTrips = [];
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  // Search and filtering
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Scheduled', 'Unassigned'];

  @override
  void initState() {
    super.initState();
    _fetchStaffDashboardData();
  }

  Future<void> _fetchStaffDashboardData() async {
    try {
      final tripsResponse = await http.get(
        Uri.parse('$backendUrl/schedules/staff/${widget.staffId}'),
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

  List<dynamic> _getTripsForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _assignedTrips
        .where((trip) => trip['schedule_date'] == dateStr)
        .toList();
  }

  List<dynamic> _getFilteredTrips() {
    List<dynamic> trips = _selectedDate != null
        ? _getTripsForDate(_selectedDate!)
        : _assignedTrips;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      trips = trips.where((trip) {
        final routeName = (trip['route_name'] ?? '').toString().toLowerCase();
        final driverName = (trip['driver_name'] ?? '').toString().toLowerCase();
        // 👇 ADDED: Allow staff to search by company name
        final companyName = (trip['client_company'] ?? '')
            .toString()
            .toLowerCase();

        return routeName.contains(_searchQuery.toLowerCase()) ||
            driverName.contains(_searchQuery.toLowerCase()) ||
            companyName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'All') {
      trips = trips.where((trip) {
        final isScheduled =
            trip['user_id'] != null && trip['vehicle_id'] != null;
        if (_statusFilter == 'Scheduled') return isScheduled;
        if (_statusFilter == 'Unassigned') return !isScheduled;
        return true;
      }).toList();
    }

    return trips;
  }

  int get _totalTrips => _assignedTrips.length;
  int get _scheduledTrips => _assignedTrips
      .where((t) => t['user_id'] != null && t['vehicle_id'] != null)
      .length;
  int get _unassignedTrips => _assignedTrips
      .where((t) => t['user_id'] == null || t['vehicle_id'] == null)
      .length;

  void _showTripDetailsModal(DateTime date, List<dynamic> trips) {
    showDialog(
      context: context,
      builder: (context) => TripDetailsDialog(
        date: date,
        trips: trips.isEmpty ? _getFilteredTrips() : trips,
        backendUrl: backendUrl,
        onAssign: () {
          setState(() => _isLoading = true);
          _fetchStaffDashboardData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dispatch & Scheduling',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 16),

              // Search and Filter Controls
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search by route, driver, or company...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        icon: const Icon(Icons.filter_alt_outlined),
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
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Calendar
                    Expanded(flex: 1, child: _buildCompactCalendarGrid()),
                    const SizedBox(width: 24),
                    // Trip List
                    Expanded(flex: 2, child: _buildTripListView()),
                  ],
                ),
              const SizedBox(height: 24),

              // Summary Footer
              if (!_isLoading && _assignedTrips.isNotEmpty)
                _buildSummaryFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactCalendarGrid() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthYearFormat(_selectedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: weekdays.map((day) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (daysInMonth + firstWeekday),
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return Container();
              }

              final day = index - firstWeekday + 1;
              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                day,
              );
              final trips = _getTripsForDate(date);
              final hasTrips = trips.isNotEmpty;
              final isSelected =
                  _selectedDate?.year == date.year &&
                  _selectedDate?.month == date.month &&
                  _selectedDate?.day == date.day;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : (hasTrips ? Colors.blue.shade50 : Colors.white),
                    border: Border.all(
                      color: isToday
                          ? Colors.orange.shade400
                          : Colors.grey.shade200,
                      width: isToday ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (hasTrips ? Colors.blue.shade700 : Colors.black),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripListView() {
    final filteredTrips = _getFilteredTrips();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: filteredTrips.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No trips scheduled.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTrips.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final trip = filteredTrips[i];
                final bool needsAssignment =
                    trip['user_id'] == null || trip['vehicle_id'] == null;
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: TripCard(
                    trip: trip,
                    backendUrl: backendUrl,
                    needsAssignment: needsAssignment,
                    onAssign: () {
                      setState(() => _isLoading = true);
                      _fetchStaffDashboardData();
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryStatCard('Total Trips', _totalTrips.toString(), Colors.blue),
          _summaryStatCard(
            'Scheduled',
            _scheduledTrips.toString(),
            Colors.green,
          ),
          _summaryStatCard(
            'Unassigned',
            _unassignedTrips.toString(),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _summaryStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _monthYearFormat(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ─── TRIP DETAILS MODAL ───
class TripDetailsDialog extends StatefulWidget {
  final DateTime date;
  final List<dynamic> trips;
  final String backendUrl;
  final VoidCallback onAssign;

  const TripDetailsDialog({
    super.key,
    required this.date,
    required this.trips,
    required this.backendUrl,
    required this.onAssign,
  });

  @override
  State<TripDetailsDialog> createState() => _TripDetailsDialogState();
}

class _TripDetailsDialogState extends State<TripDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 500;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled Trips - ${_formatDate(widget.date)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (widget.trips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No trips for this date')),
                    )
                  else
                    Column(
                      children: widget.trips.map((trip) {
                        final bool needsAssignment =
                            trip['user_id'] == null ||
                            trip['vehicle_id'] == null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TripCard(
                            trip: trip,
                            backendUrl: widget.backendUrl,
                            needsAssignment: needsAssignment,
                            onAssign: widget.onAssign,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── TRIP CARD WIDGET ───
class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String backendUrl;
  final bool needsAssignment;
  final VoidCallback onAssign;

  const TripCard({
    super.key,
    required this.trip,
    required this.backendUrl,
    required this.needsAssignment,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final statusStr = trip['trip_status']?.toString() ?? 'Unknown';
    final isRejected = statusStr.toLowerCase().contains('rejected');
    final isPending = statusStr.toLowerCase().contains('pending');
    
    // Buttons are only shown if the trip is pending AND needs assignment, and NOT rejected
    final bool showActions = isPending && needsAssignment && !isRejected;

    Color cardBorder = Colors.green.shade200;
    Color cardBg = Colors.green.shade50;
    Color badgeColor = Colors.green;
    String badgeText = 'Scheduled';

    if (isRejected) {
      cardBorder = Colors.red.shade300;
      cardBg = Colors.red.shade50;
      badgeColor = Colors.red;
      badgeText = 'Rejected';
    } else if (isPending && needsAssignment) {
      cardBorder = Colors.orange.shade200;
      cardBg = Colors.orange.shade50;
      badgeColor = Colors.orange;
      badgeText = 'Action Required';
    } else if (isPending && !needsAssignment) {
       cardBorder = Colors.orange.shade200;
       cardBg = Colors.orange.shade50;
       badgeColor = Colors.orange;
       badgeText = 'Pending';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8), 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardBorder, width: isRejected ? 2 : 1), 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip['route_name'] ?? 'Unspecified Route',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Time', _formatTimeRange(trip['departure_time'], trip['estimated_arrival_time'])),
              const SizedBox(height: 8),
              _buildInfoRow('Company', trip['client_company'] ?? 'Unknown Company'),
            ],
          ),
        ),
        
        if (showActions)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAssignModal(context);
                    },
                    icon: const Icon(Icons.assignment_ind, color: Colors.white, size: 16),
                    label: const Text('Assign', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectTrip(context),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
                    label: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showAssignModal(BuildContext context) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AssignTripDialog(trip: trip, backendUrl: backendUrl, onSuccess: onAssign));
  }

  Future<void> _rejectTrip(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Request?"),
        content: const Text("Are you sure you want to reject this trip request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.post(
        Uri.parse('$backendUrl/schedules/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"trip_id": trip['trip_id']}),
      );
      if (res.statusCode == 200 && context.mounted) {
        onAssign(); // Refresh list
      }
    } catch (e) {
      debugPrint("Reject Error: $e");
    }
  }
}

// ─── ASSIGNMENT MODAL ───
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
        Navigator.pop(context);
        widget.onSuccess();
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
          : SingleChildScrollView(
              child: Column(
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