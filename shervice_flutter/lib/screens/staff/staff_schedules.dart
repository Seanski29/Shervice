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
  DateTime? _selectedDate = DateTime.now();

  String _searchQuery = '';
  String _statusFilter = 'All';
  // 👇 FIX: Added 'Rejected' to the dropdown filter options
  final List<String> _statusOptions = [
    'All',
    'Scheduled',
    'Unassigned',
    'Rejected',
  ];

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

    if (_searchQuery.isNotEmpty) {
      trips = trips.where((trip) {
        final routeName = (trip['route_name'] ?? '').toString().toLowerCase();
        final driverName = (trip['driver_name'] ?? '').toString().toLowerCase();
        final companyName = (trip['client_company'] ?? '')
            .toString()
            .toLowerCase();
        return routeName.contains(_searchQuery.toLowerCase()) ||
            driverName.contains(_searchQuery.toLowerCase()) ||
            companyName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_statusFilter != 'All') {
      trips = trips.where((trip) {
        final statusStr = trip['trip_status']?.toString() ?? 'Unknown';
        final isRejected = statusStr.toLowerCase().contains('rejected');
        final isUnassigned =
            (trip['user_id'] == null || trip['vehicle_id'] == null) &&
            !isRejected;
        final isScheduled =
            trip['user_id'] != null &&
            trip['vehicle_id'] != null &&
            !isRejected;

        if (_statusFilter == 'Scheduled') return isScheduled;
        if (_statusFilter == 'Unassigned') return isUnassigned;
        // 👇 FIX: Implemented logic to filter the list specifically by Rejected items
        if (_statusFilter == 'Rejected') return isRejected;

        return true;
      }).toList();
    }

    // ── SORT: unassigned first ──
    trips.sort((a, b) {
      final aStatus = a['trip_status']?.toString().toLowerCase() ?? '';
      final bStatus = b['trip_status']?.toString().toLowerCase() ?? '';

      final aRejected = aStatus.contains('rejected');
      final bRejected = bStatus.contains('rejected');

      final aUnassigned =
          (a['user_id'] == null || a['vehicle_id'] == null) && !aRejected;
      final bUnassigned =
          (b['user_id'] == null || b['vehicle_id'] == null) && !bRejected;

      if (aUnassigned && !bUnassigned) return -1;
      if (!aUnassigned && bUnassigned) return 1;
      return 0;
    });

    return trips;
  }

  int get _totalTrips => _assignedTrips.length;

  int get _rejectedTrips => _assignedTrips.where((t) {
    final statusStr = t['trip_status']?.toString() ?? 'Unknown';
    return statusStr.toLowerCase().contains('rejected');
  }).length;

  int get _scheduledTrips => _assignedTrips.where((t) {
    final statusStr = t['trip_status']?.toString() ?? 'Unknown';
    final isRejected = statusStr.toLowerCase().contains('rejected');
    return t['user_id'] != null && t['vehicle_id'] != null && !isRejected;
  }).length;

  int get _unassignedTrips => _assignedTrips.where((t) {
    final statusStr = t['trip_status']?.toString() ?? 'Unknown';
    final isRejected = statusStr.toLowerCase().contains('rejected');
    return (t['user_id'] == null || t['vehicle_id'] == null) && !isRejected;
  }).length;

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

  String _formatDateOnly(DateTime date) {
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchStaffDashboardData,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12.0,
          ),
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
                          'Dispatch & Scheduling',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage trip assignments and monitor dispatch status.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
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
                        _fetchStaffDashboardData();
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
                  _statChip(
                    Icons.event,
                    _totalTrips.toString(),
                    'Total',
                    const Color(0xFF3B82F6),
                  ),
                  _statChip(
                    Icons.check_circle,
                    _scheduledTrips.toString(),
                    'Scheduled',
                    const Color(0xFF10B981),
                  ),
                  _statChip(
                    Icons.warning,
                    _unassignedTrips.toString(),
                    'Unassigned',
                    const Color(0xFFF59E0B),
                  ),
                  // 👇 FIX: Added the new Rejected statistics chip
                  _statChip(
                    Icons.cancel,
                    _rejectedTrips.toString(),
                    'Rejected',
                    const Color(0xFFEF4444),
                  ),
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 1.5,
                            ),
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
                            icon: const Icon(
                              Icons.filter_alt_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
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
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── DATE HINT ──
              if (_selectedDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateOnly(_selectedDate!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── MAIN CONTENT ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : isMobile
                    ? Column(
                        children: [
                          _buildCompactCalendarGrid(),
                          const SizedBox(height: 12),
                          Expanded(child: _buildTripListView()),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildCompactCalendarGrid()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildTripListView()),
                        ],
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthYearFormat(_selectedMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
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
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: weekdays.map((day) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
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
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = date;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : (hasTrips ? const Color(0xFFEFF6FF) : Colors.white),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFFF59E0B)
                          : (isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFE2E8F0)),
                      width: isToday ? 1.5 : (isSelected ? 1.5 : 1),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (hasTrips
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF0F172A)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.list_alt,
                      color: Color(0xFF475569),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate == null ? 'All Trips' : 'Scheduled',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredTrips.length}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTrips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDate == null
                              ? 'No trips found for this filter.'
                              : 'No trips on this date.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      final statusStr =
                          trip['trip_status']?.toString() ?? 'Unknown';
                      final isRejected = statusStr.toLowerCase().contains(
                        'rejected',
                      );
                      final bool needsAssignment =
                          (trip['user_id'] == null ||
                              trip['vehicle_id'] == null) &&
                          !isRejected;

                      return TripCard(
                        trip: trip,
                        backendUrl: backendUrl,
                        needsAssignment: needsAssignment,
                        isModal: false,
                        onAssign: () {
                          setState(() => _isLoading = true);
                          _fetchStaffDashboardData();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trips - ${_formatDate(widget.date)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: widget.trips.isEmpty
                  ? Center(
                      child: Text(
                        'No trips for this date.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.trips.length,
                      itemBuilder: (context, index) {
                        final trip = widget.trips[index];
                        final statusStr =
                            trip['trip_status']?.toString() ?? 'Unknown';
                        final isRejected = statusStr.toLowerCase().contains(
                          'rejected',
                        );
                        final bool needsAssignment =
                            (trip['user_id'] == null ||
                                trip['vehicle_id'] == null) &&
                            !isRejected;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TripCard(
                            trip: trip,
                            backendUrl: widget.backendUrl,
                            needsAssignment: needsAssignment,
                            isModal: true,
                            onAssign: widget.onAssign,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

// ─── UNIFIED TRIP CARD ───
class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String backendUrl;
  final bool needsAssignment;
  final bool isModal;
  final VoidCallback onAssign;

  const TripCard({
    super.key,
    required this.trip,
    required this.backendUrl,
    required this.needsAssignment,
    this.isModal = false,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final statusStr = trip['trip_status']?.toString() ?? 'Unknown';
    final isRejected = statusStr.toLowerCase().contains('rejected');
    final isUnassigned = needsAssignment && !isRejected;

    // Determine status styling
    Color statusColor = const Color(0xFF10B981);
    Color bgColor = const Color(0xFFECFDF5);
    String badgeText = 'Scheduled';

    if (isRejected) {
      statusColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
      badgeText = 'Rejected';
    } else if (isUnassigned) {
      statusColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
      badgeText = 'Unassigned';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
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
          // ── ROW: ROUTE + STATUS BADGE ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip['route_name'] ?? 'Unspecified Route',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── INFO CHIPS (larger, spaced) ──
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _infoChip(
                Icons.access_time,
                _formatTimeRange(
                  trip['departure_time'],
                  trip['estimated_arrival_time'],
                ),
              ),
              _infoChip(Icons.business, trip['client_company'] ?? 'Unknown'),
              _infoChip(Icons.people, '${trip['passenger_count'] ?? 0} pax'),
              _infoChip(Icons.straighten, '${trip['route_distance'] ?? 0} km'),
              if (trip['driver_name'] != null && !isUnassigned && !isRejected)
                _infoChip(Icons.person, trip['driver_name']),
              if (trip['vehicle_plate'] != null && !isUnassigned && !isRejected)
                _infoChip(Icons.directions_car, trip['vehicle_plate']),
            ],
          ),

          // ── ACTION BUTTONS (only for unassigned) ──
          if (isUnassigned) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isModal) Navigator.pop(context);
                        _showAssignModal(context);
                      },
                      icon: const Icon(
                        Icons.assignment_ind,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Assign',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectTrip(context),
                      icon: const Icon(
                        Icons.cancel,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAssignModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignTripDialog(
        trip: trip,
        backendUrl: backendUrl,
        onSuccess: onAssign,
      ),
    );
  }

  Future<void> _rejectTrip(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reject Request?"),
        content: const Text(
          "Are you sure you want to reject this trip request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Reject",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        if (isModal) Navigator.pop(context);
        onAssign();
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
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Dispatch: ${widget.trip['route_name']}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: _isLoadingOptions
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            )
          : SizedBox(
              width: isMobile ? double.infinity : 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Date: ${widget.trip['schedule_date']}",
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_drivers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "⚠️ No drivers available",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Driver",
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
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
                  const SizedBox(height: 12),
                  if (_vehicles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "⚠️ No vehicles available",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Vehicle",
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
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
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          onPressed:
              (_isSubmitting ||
                  _selectedDriverUuid == null ||
                  _selectedVehicleId == null)
              ? null
              : _submitAssignment,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Confirm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
