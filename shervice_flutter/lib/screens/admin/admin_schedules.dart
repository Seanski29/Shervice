import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class AdminSchedules extends StatefulWidget {
  const AdminSchedules({super.key});

  @override
  State<AdminSchedules> createState() => _AdminSchedulesState();
}

class _AdminSchedulesState extends State<AdminSchedules> {
  // --- State Variables ---
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> _allSchedules = [];
  List<dynamic> _filteredSchedules = [];

  // Calendar State
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  // Filtering & Searching
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = [
    'All',
    'Scheduled',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchedulesFromDatabase();
  }

  // --- Data Fetching ---
  Future<void> _fetchSchedulesFromDatabase() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _isLoading = true;
    });

    final String url = '$backendUrl/trips';
    debugPrint("🔍 Fetching from: $url");

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _allSchedules = data;
        } else if (data is Map && data.containsKey('trips')) {
          _allSchedules = data['trips'] ?? [];
        } else if (data is Map && data.containsKey('sample_data_payload')) {
          _allSchedules = data['sample_data_payload'] ?? [];
        } else {
          _allSchedules = [];
        }
      } else {
        debugPrint("⚠️ Server returned non-200 status code: ${response.statusCode}");
        _allSchedules = [];
      }
    } catch (e) {
      debugPrint("❌ Error reading live trip schedule streams: $e");
      _allSchedules = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    List<dynamic> temp = _allSchedules.where((trip) {
      final routeName = (trip['route_name'] ?? '').toString().toLowerCase();
      final userAccount = trip['user_account'] as Map<String, dynamic>?;
      final driverName =
          (userAccount != null ? userAccount['full_name'] ?? '' : '')
              .toString()
              .toLowerCase();
      final tripStatus = (trip['trip_status'] ?? 'Scheduled').toString();

      final matchesSearch =
          routeName.contains(_searchQuery.toLowerCase()) ||
          driverName.contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == 'All' ||
          tripStatus.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    temp.sort((a, b) {
      final dateA = (a['schedule_date'] ?? '').toString();
      final timeA = (a['departure_time'] ?? '').toString();
      final dateB = (b['schedule_date'] ?? '').toString();
      final timeB = (b['departure_time'] ?? '').toString();
      return "$dateA $timeA".compareTo("$dateB $timeB");
    });

    setState(() {
      _filteredSchedules = temp;
    });
  }

  // --- Calendar Helpers ---
  List<dynamic> _getTripsForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _filteredSchedules.where((trip) {
      final tripDateRaw = (trip['schedule_date'] ?? '').toString();
      if (tripDateRaw.length >= 10) {
        final tripDate = tripDateRaw.substring(0, 10);
        return tripDate == dateStr;
      }
      return false;
    }).toList();
  }

  List<dynamic> _getDisplayedTrips() {
    if (_selectedDate == null) return _filteredSchedules;
    return _getTripsForDate(_selectedDate!);
  }

  // --- Stats ---
  int get _totalTrips => _filteredSchedules.length;
  int get _scheduledTrips => _filteredSchedules
      .where((t) => (t['trip_status'] ?? 'Scheduled').toString().toLowerCase() == 'scheduled')
      .length;
  int get _inProgressTrips => _filteredSchedules
      .where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'in progress')
      .length;
  int get _completedTrips => _filteredSchedules
      .where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'completed')
      .length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'active':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'scheduled':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _monthYearFormat(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // --- Modal ---
  void _showTripDetails(Map<String, dynamic> trip) {
    final userAccount = trip['user_account'] as Map<String, dynamic>?;
    final vehicle = trip['vehicle'] as Map<String, dynamic>?;
    final oicProfile = trip['oic_profile'] as Map<String, dynamic>?;

    final String driver = userAccount != null
        ? (userAccount['full_name'] ?? 'Not Assigned')
        : 'Not Assigned';
    final String email = userAccount != null
        ? (userAccount['email'] ?? 'N/A')
        : 'N/A';
    final String plate = vehicle != null
        ? (vehicle['plate_number'] ?? 'No Shuttle')
        : 'No Shuttle';
    final String type = vehicle != null
        ? (vehicle['bus_type'] ?? 'Standard')
        : 'Standard';
    final String company = oicProfile != null
        ? (oicProfile['company_name'] ?? 'GT LANTIN')
        : 'GT LANTIN';
    final String route = trip['route_name'] ?? 'Unassigned Route';
    final String status = trip['trip_status'] ?? 'Scheduled';
    final String date = trip['schedule_date'] ?? 'TBD';
    final String departure = trip['departure_time'] ?? 'TBD';
    final String arrival = trip['arrival_time'] ?? 'TBD';
    final String notes = trip['notes'] ?? 'No additional notes.';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Route', route),
              _detailRow('Status', status, color: _getStatusColor(status)),
              _detailRow('Driver', driver),
              _detailRow('Email', email),
              _detailRow('Vehicle', '$plate ($type)'),
              _detailRow('Company', company),
              _detailRow('Date', date),
              _detailRow('Departure', departure),
              _detailRow('Arrival', arrival),
              _detailRow('Notes', notes, isNotes: true),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool isNotes = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? const Color(0xFF0F172A),
                fontSize: 13,
                height: isNotes ? 1.4 : 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchSchedulesFromDatabase,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- HEADER (flexible row) -----
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Schedules',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor and manage all scheduled trips for your fleet operations.',
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
                  // Refresh button - fixed size
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _isRefreshing ? null : _fetchSchedulesFromDatabase,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF3B82F6),
                              ),
                            )
                          : const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                      tooltip: 'Refresh Schedules',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ----- FILTERS (fully responsive) -----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.start,
                  children: [
                    // Search field
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 280,
                        minWidth: isMobile ? double.infinity : 200,
                      ),
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          onChanged: (value) {
                            _searchQuery = value;
                            _applyFiltersAndSort();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search routes or drivers...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
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
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Status dropdown
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 180,
                        minWidth: isMobile ? double.infinity : 140,
                      ),
                      child: SizedBox(
                        height: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _statusFilter,
                              icon: const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              items: _statusOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _statusFilter = newValue;
                                    _applyFiltersAndSort();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----- TOP SUMMARY STATS (centered) -----
              if (!_isLoading && _filteredSchedules.isNotEmpty)
                _buildTopSummaryStats(),
              const SizedBox(height: 16),

              // ----- MAIN CONTENT -----
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                )
              else if (isMobile)
                Column(
                  children: [
                    _buildCompactCalendarGrid(),
                    const SizedBox(height: 16),
                    _buildTripListView(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildCompactCalendarGrid()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildTripListView()),
                  ],
                ),

              // ----- BOTTOM SUMMARY (optional) -----
              if (!_isLoading && _filteredSchedules.isNotEmpty)
                _buildSummaryFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- TOP SUMMARY STATS (Centered Wrap) ----
  Widget _buildTopSummaryStats() {
    final List<Map<String, dynamic>> stats = [
      {'label': 'Total Trips', 'value': _totalTrips.toString(), 'color': const Color(0xFF3B82F6)},
      {'label': 'Scheduled', 'value': _scheduledTrips.toString(), 'color': const Color(0xFF10B981)},
      {'label': 'In Progress', 'value': _inProgressTrips.toString(), 'color': const Color(0xFFF59E0B)},
      {'label': 'Completed', 'value': _completedTrips.toString(), 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: stats.map((stat) {
          return SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  stat['value'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: stat['color'],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- CALENDAR ----
  Widget _buildCompactCalendarGrid() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthYearFormat(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => setState(
                        () => _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  children: weekdays.map((day) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 3),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.95,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
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
                              ? const Color(0xFF3B82F6)
                              : (hasTrips ? const Color(0xFFEFF6FF) : Colors.white),
                          border: Border.all(
                            color: isToday
                                ? const Color(0xFFF59E0B)
                                : (isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
                            width: isToday ? 1.5 : (isSelected ? 1.5 : 1),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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
          ),
        ],
      ),
    );
  }

  // ---- TRIP LIST ----
  Widget _buildTripListView() {
    final displayedTrips = _getDisplayedTrips();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFF475569), size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _selectedDate == null
                              ? 'All Trips'
                              : 'Trips for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${displayedTrips.length} trips',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          displayedTrips.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No trips scheduled.',
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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTrips.length,
                  itemBuilder: (context, index) {
                    final trip = displayedTrips[index];
                    return _buildTripCard(trip);
                  },
                ),
        ],
      ),
    );
  }

  // ---- TRIP CARD (Compact, consistent with driver/fleet) ----
  Widget _buildTripCard(Map<String, dynamic> trip) {
    final userAccount = trip['user_account'] as Map<String, dynamic>?;
    final vehicle = trip['vehicle'] as Map<String, dynamic>?;
    final oicProfile = trip['oic_profile'] as Map<String, dynamic>?;

    final String driver = userAccount != null
        ? (userAccount['full_name'] ?? 'No Assigned Driver')
        : 'No Assigned Driver';
    final String plate = vehicle != null
        ? (vehicle['plate_number'] ?? 'No Shuttle Linked')
        : 'No Shuttle Linked';
    final String type = vehicle != null
        ? (vehicle['bus_type'] ?? 'Standard Shuttle')
        : 'Standard Shuttle';
    final String company = oicProfile != null
        ? (oicProfile['company_name'] ?? 'GT LANTIN')
        : 'GT LANTIN';

    final String dateStr = trip['schedule_date'] ?? '';
    final String timeStr = trip['departure_time'] ?? 'TBD';
    final String deploymentTime = dateStr.isNotEmpty ? "$dateStr @ $timeStr" : timeStr;
    final String status = trip['trip_status'] ?? 'Scheduled';
    final String routeName = trip['route_name'] ?? 'Unassigned Route';
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => _showTripDetails(trip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // reduced from 16,12
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left indicator - fixed height 36 to match driver/fleet
            Container(
              width: 4,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          routeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 8, // reduced from 9
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2), // reduced from 6
                  Wrap(
                    spacing: 10, // reduced from 14
                    runSpacing: 2,
                    children: [
                      _cardIconText(Icons.person_outline, driver),
                      _cardIconText(
                        Icons.airport_shuttle_outlined,
                        '$plate ($type)',
                      ),
                      _cardIconText(Icons.access_time, deploymentTime),
                      _cardIconText(Icons.business_outlined, company),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)), // reduced from 13
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            fontSize: 11, // reduced from 12
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---- BOTTOM SUMMARY (wrap) ----
  Widget _buildSummaryFooter() {
    final List<Map<String, dynamic>> stats = [
      {'label': 'Total Trips', 'value': _totalTrips.toString(), 'color': const Color(0xFF3B82F6)},
      {'label': 'Scheduled', 'value': _scheduledTrips.toString(), 'color': const Color(0xFF10B981)},
      {'label': 'In Progress', 'value': _inProgressTrips.toString(), 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 8,
        runSpacing: 8,
        children: stats.map((stat) {
          return Column(
            children: [
              Text(
                stat['value'],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: stat['color'],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat['label'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}