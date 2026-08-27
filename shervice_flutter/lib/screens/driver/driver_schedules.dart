import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';
import '../../widgets/dark_mode_toggle.dart';

class DriverSchedules extends StatefulWidget {
  final String driverId;
  const DriverSchedules({super.key, required this.driverId});

  @override
  State<DriverSchedules> createState() => _DriverSchedulesState();
}

class _DriverSchedulesState extends State<DriverSchedules> {
  // --- STATE ---
  bool _isLoading = true;
  List<dynamic> _myTrips = [];
  String _currentSort = 'Date (Newest)';
  final List<String> _sortOptions = ['Date (Newest)', 'Date (Oldest)'];
  
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  bool _calendarExpanded = false;
  bool _showAllCompleted = false;

  @override
  void initState() {
    super.initState();
    _fetchMySchedules();
  }

  // --- API ---
  Future<void> _fetchMySchedules() async {
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/driver/${widget.driverId}'),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _myTrips = data['data'] ?? [];
          _isLoading = false;
          _selectedDate = null;
          _showAllCompleted = false;
        });
      } else if (mounted) {
        setState(() {
          _myTrips = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myTrips = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTripStatus(int tripId, String newStatus) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/schedules/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trip_id': tripId, 'status': newStatus}),
      );
      if (res.statusCode == 200 && mounted) {
        _fetchMySchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Completed'
                  ? 'Trip Finished!'
                  : 'Trip Started! Drive safely.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating trip: $e');
    }
  }

  // --- UTILS ---
  DateTime? _parseTripDate(String? value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  // --- FILTER & SORT ---
  List<dynamic> _getFilteredTrips() {
    if (_selectedDate == null) return List<dynamic>.from(_myTrips);
    return _myTrips.where((trip) {
      final tripDate = _parseTripDate(trip['schedule_date']?.toString());
      return tripDate != null &&
          tripDate.year == _selectedDate!.year &&
          tripDate.month == _selectedDate!.month &&
          tripDate.day == _selectedDate!.day;
    }).toList();
  }

  List<dynamic> _sortTrips(List<dynamic> trips) {
    trips.sort((a, b) {
      final dateA = _parseTripDate(a['schedule_date']?.toString());
      final dateB = _parseTripDate(b['schedule_date']?.toString());
      if (_currentSort == 'Date (Newest)') {
        return (dateB ?? DateTime(0)).compareTo(dateA ?? DateTime(0));
      } else {
        return (dateA ?? DateTime(2100)).compareTo(dateB ?? DateTime(2100));
      }
    });
    return trips;
  }

  List<dynamic> get _scheduledTrips {
    final scheduled = _getFilteredTrips().where((t) => t['trip_status'] == 'Scheduled').toList();
    return _sortTrips(scheduled);
  }

  List<dynamic> get _ongoingTrips {
    final ongoing = _getFilteredTrips().where((t) => t['trip_status'] == 'Ongoing').toList();
    return _sortTrips(ongoing);
  }

  List<dynamic> get _completedTrips {
    final completed = _getFilteredTrips().where((t) => t['trip_status'] == 'Completed').toList();
    return _sortTrips(completed);
  }

  bool get _isFiltered => _selectedDate != null;

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day
          ? null
          : date;
      _showAllCompleted = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    });
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 16.0 : 32.0;
    final totalTrips = _myTrips.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: _fetchMySchedules,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
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
                              Text(
                                'My Schedule',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDate == null
                                    ? '$totalTrips trips assigned'
                                    : '${_getFilteredTrips().length} on ${_selectedDate!.day}/${_selectedDate!.month}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: Colors.blue.shade600, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _fetchMySchedules,
                            icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            tooltip: 'Refresh Schedules',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── STATS CHIPS ──
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _statChip(Icons.calendar_today, '${_scheduledTrips.length}', 'Scheduled', const Color(0xFFF59E0B), isDark),
                        _statChip(Icons.play_arrow, '${_ongoingTrips.length}', 'Ongoing', const Color(0xFF3B82F6), isDark),
                        _statChip(Icons.check_circle, '${_completedTrips.length}', 'Completed', const Color(0xFF10B981), isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── SORT + FILTER ROW ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _currentSort,
                                isExpanded: true,
                                dropdownColor: Theme.of(context).cardColor,
                                icon: const Icon(Icons.sort, size: 18, color: Color(0xFF64748B)),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                items: _sortOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) setState(() => _currentSort = value);
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = null;
                                _showAllCompleted = false;
                              });
                            },
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.close, size: 16, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Clear Filter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.blue.shade300 : const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── TRIP SECTIONS ──
                    if (_getFilteredTrips().isEmpty)
                      _buildEmptyState(isDark)
                    else ...[
                      if (_ongoingTrips.isNotEmpty) _buildStatusSection('Ongoing', _ongoingTrips, const Color(0xFF3B82F6), isDark),
                      if (_scheduledTrips.isNotEmpty) _buildStatusSection('Scheduled', _scheduledTrips, const Color(0xFFF59E0B), isDark),
                      if (_completedTrips.isNotEmpty) _buildCompletedSection(isDark),
                    ],

                    const SizedBox(height: 24),

                    // ── CALENDAR ──
                    _buildCalendarSection(isDark),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _selectedDate == null ? 'No trips assigned yet' : 'No trips scheduled for this date',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String title, List<dynamic> trips, Color themeColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? themeColor.withOpacity(0.3) : themeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          if (!isDark) BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  title == 'Scheduled' ? Icons.schedule : Icons.play_arrow,
                  size: 18,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '$title (${trips.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ...trips.map((trip) => _buildTripCard(trip, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildCompletedSection(bool isDark) {
    final allCompleted = _completedTrips;
    final displayTrips = _isFiltered || _showAllCompleted ? allCompleted : allCompleted.take(3).toList();
    final hasMore = !_isFiltered && allCompleted.length > 3 && !_showAllCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Completed (${allCompleted.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ...displayTrips.map((trip) => _buildTripCard(trip, isDark, isCompleted: true)),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAllCompleted = true),
                  child: Text(
                    'Show ${allCompleted.length - 3} more completed trips',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, bool isDark, {bool isCompleted = false}) {
    final String status = trip['trip_status'] ?? 'Scheduled';
    final bool isScheduled = status == 'Scheduled';
    final bool isOngoing = status == 'Ongoing';

    Color statusColor = const Color(0xFF64748B);
    if (isOngoing) statusColor = const Color(0xFF3B82F6);
    else if (isCompleted) statusColor = const Color(0xFF10B981);
    else if (isScheduled) statusColor = const Color(0xFFF59E0B);
    
    final Color bgColor = isDark ? statusColor.withOpacity(0.15) : statusColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip['route_name']?.toString() ?? 'Unassigned Route',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                trip['schedule_date']?.toString() ?? 'TBD',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : const Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                trip['departure_time']?.toString().substring(0, 5) ?? '--:--',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : const Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (!isCompleted && (isScheduled || isOngoing)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _updateTripStatus(trip['trip_id'], isScheduled ? 'Ongoing' : 'Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScheduled ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: Icon(isScheduled ? Icons.play_arrow : Icons.check_circle, color: Colors.white, size: 18),
                label: Text(
                  isScheduled ? 'Start Trip' : 'Finish Trip',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- COLLAPSIBLE CALENDAR ---
  Widget _buildCalendarSection(bool isDark) {
    final tripDates = _myTrips
        .map((trip) => _parseTripDate(trip['schedule_date']?.toString()))
        .whereType<DateTime>()
        .map((date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
        .toSet();

    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _calendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Calendar View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_calendarMonth.monthName} ${_calendarMonth.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue.shade300 : const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_calendarExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      ...['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(
                        (day) => Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(firstWeekday, (_) => const SizedBox()),
                      ...List.generate(daysInMonth, (index) {
                        final day = index + 1;
                        final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
                        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final hasTrip = tripDates.contains(key);
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.year == date.year &&
                            _selectedDate!.month == date.month &&
                            _selectedDate!.day == date.day;

                        return GestureDetector(
                          onTap: hasTrip ? () => _onDateSelected(date) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : (hasTrip
                                      ? (isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFEFF6FF))
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (hasTrip
                                          ? (isDark ? Colors.blue.shade300 : const Color(0xFF3B82F6))
                                          : (isDark ? Colors.grey.shade400 : const Color(0xFF0F172A))),
                                  fontWeight: hasTrip ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scheduled Trips Available',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

extension on DateTime {
  String get monthName {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }
}