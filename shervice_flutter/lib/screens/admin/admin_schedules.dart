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
  List<dynamic> _allSchedules = [];
  List<dynamic> _filteredSchedules = [];

  // Calendar State
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  // Filtering & Searching Metrics Configuration
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

  // --- Data Fetching & Processing (From Backend Code) ---
  Future<void> _fetchSchedulesFromDatabase() async {
    setState(() => _isLoading = true);

    // Construct the URL using the constant + the specific route
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
        debugPrint(
          "⚠️ Server returned non-200 status code: ${response.statusCode}",
        );
        _allSchedules = [];
      }
    } catch (e) {
      debugPrint("❌ Error reading live trip schedule streams: $e");
      _allSchedules = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  void _applyFiltersAndSort() {
    List<dynamic> temp = _allSchedules.where((trip) {
      final routeName = (trip['route_name'] ?? '').toString().toLowerCase();

      // Safe processing extracting variables out from relational nested join models
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

    // Sort chronologically using date and departure parameters combined context
    temp.sort((a, b) {
      final dateA = (a['schedule_date'] ?? '').toString();
      final timeA = (a['departure_time'] ?? '').toString();
      final dateB = (b['schedule_date'] ?? '').toString();
      final timeB = (b['departure_time'] ?? '').toString();

      return "$dateA $timeA".compareTo("$dateB $timeB");
    });

    setState(() {
      _filteredSchedules = temp;
      _isLoading = false;
    });
  }

  // --- Safely Extract Data for Calendar (Prevents RangeError) ---
  List<dynamic> _getTripsForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _filteredSchedules.where((trip) {
      final tripDateRaw = (trip['schedule_date'] ?? '').toString();
      // Length safety check to prevent RangeError when substring(0,10) evaluates empty/short DB values
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

  int get _totalTrips => _filteredSchedules.length;
  int get _scheduledTrips => _filteredSchedules
      .where(
        (t) =>
            (t['trip_status'] ?? 'Scheduled').toString().toLowerCase() ==
            'scheduled',
      )
      .length;
  int get _inProgressTrips => _filteredSchedules
      .where(
        (t) =>
            (t['trip_status'] ?? '').toString().toLowerCase() == 'in progress',
      )
      .length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.orange;
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

  // --- UI Layout Engine (From Design Code) ---
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Components
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                const Text(
                  'Trip Schedules',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: _fetchSchedulesFromDatabase,
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  tooltip: 'Refresh Schedules',
                  splashRadius: 24,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Control and Filtering Ribbon
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 350,
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFiltersAndSort();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search routes or drivers...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
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
                Container(
                  width: isMobile ? double.infinity : 200,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
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
                          setState(() {
                            _statusFilter = newValue;
                            _applyFiltersAndSort();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Core Stream Section - Calendar + Trip List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isMobile)
              // Mobile View: Stack vertically
              Column(
                children: [
                  _buildCompactCalendarGrid(),
                  const SizedBox(height: 24),
                  _buildTripListView(),
                ],
              )
            else
              // Desktop View: Side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildCompactCalendarGrid()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildTripListView()),
                ],
              ),
            const SizedBox(height: 24),

            // Summary Footer
            if (!_isLoading && _filteredSchedules.isNotEmpty)
              _buildSummaryFooter(),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthYearFormat(_selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
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
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: weekdays.map((day) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
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
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (hasTrips
                                  ? Colors.blue.shade700
                                  : Colors.black87),
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
    final displayedTrips = _getDisplayedTrips();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: displayedTrips.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trips scheduled.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap:
                  true, // Prevents expanding infinitely inside scroll views
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedTrips.length,
              itemBuilder: (context, index) {
                final trip = displayedTrips[index];

                // 🔒 Extract nested structural values mapping variables dynamically to your Postgres Schema rules
                final userAccount =
                    trip['user_account'] as Map<String, dynamic>?;
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
                final String deploymentTime = dateStr.isNotEmpty
                    ? "$dateStr @ $timeStr"
                    : timeStr;

                return _buildTripCard(
                  routeName: trip['route_name'] ?? 'Unassigned Route',
                  driverName: driver,
                  vehiclePlate: plate,
                  vehicleType: type,
                  timeString: deploymentTime,
                  status: trip['trip_status'] ?? 'Scheduled',
                  companyName: company,
                );
              },
            ),
    );
  }

  Widget _buildSummaryFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 24,
        runSpacing: 24,
        children: [
          _summaryStatCard('Total Trips', _totalTrips.toString(), Colors.blue),
          _summaryStatCard(
            'Scheduled',
            _scheduledTrips.toString(),
            Colors.green,
          ),
          _summaryStatCard(
            'In Progress',
            _inProgressTrips.toString(),
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Updated Card to support Vehicle Type and Company Name (From Backend Code) ---
  Widget _buildTripCard({
    required String routeName,
    required String driverName,
    required String vehiclePlate,
    required String vehicleType,
    required String timeString,
    required String status,
    required String companyName,
  }) {
    final statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  routeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _cardIconText(Icons.person_outline, 'Driver: $driverName'),
              _cardIconText(
                Icons.airport_shuttle_outlined,
                'Shuttle: $vehiclePlate ($vehicleType)',
              ),
              _cardIconText(Icons.access_time, 'Departure: $timeString'),
              _cardIconText(Icons.business_outlined, 'Company: $companyName'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
