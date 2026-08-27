import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

  DateTime? _parseTripDate(String? value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  // ── FILTER & SORT ──
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
    final filtered = _getFilteredTrips();
    final scheduled = filtered.where((t) => t['trip_status'] == 'Scheduled').toList();
    return _sortTrips(scheduled);
  }

  List<dynamic> get _ongoingTrips {
    final filtered = _getFilteredTrips();
    final ongoing = filtered.where((t) => t['trip_status'] == 'Ongoing').toList();
    return _sortTrips(ongoing);
  }

  List<dynamic> get _completedTrips {
    final filtered = _getFilteredTrips();
    final completed = filtered.where((t) => t['trip_status'] == 'Completed').toList();
    return _sortTrips(completed);
  }

  bool get _isFiltered => _selectedDate != null;

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate =
          _selectedDate != null &&
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
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;
    final totalTrips = _myTrips.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: _fetchMySchedules,
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
                              Text(
                                'My Schedule',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDate == null
                                    ? '$totalTrips trips assigned'
                                    : '${_getFilteredTrips().length} on ${_selectedDate!.day}/${_selectedDate!.month}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchMySchedules,
                          icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                          Icons.calendar_today,
                          '${_scheduledTrips.length}',
                          'Scheduled',
                          const Color(0xFF3B82F6),
                        ),
                        _statChip(
                          Icons.play_arrow,
                          '${_ongoingTrips.length}',
                          'Ongoing',
                          const Color(0xFF10B981),
                        ),
                        _statChip(
                          Icons.check_circle,
                          '${_completedTrips.length}',
                          'Completed',
                          const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── SORT + FILTER ROW ──
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _currentSort,
                                isExpanded: true,
                                icon: const Icon(Icons.sort, size: 18, color: Color(0xFF64748B)),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                items: _sortOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _currentSort = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedDate != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = null;
                                _showAllCompleted = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.close, size: 14, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF3B82F6),
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

                    // ── TRIP SECTIONS ──
                    if (_getFilteredTrips().isEmpty)
                      _buildEmptyState()
                    else ...[
                      // Scheduled
                      if (_scheduledTrips.isNotEmpty) _buildStatusSection('Scheduled', _scheduledTrips, isBlue: true),
                      // Ongoing
                      if (_ongoingTrips.isNotEmpty) _buildStatusSection('Ongoing', _ongoingTrips, isBlue: false),
                      // Completed
                      if (_completedTrips.isNotEmpty) _buildCompletedSection(),
                    ],

                    const SizedBox(height: 12),

                    // ── CALENDAR ──
                    _buildCalendarSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate == null
                  ? 'No trips assigned yet'
                  : 'No trips on this day',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(String title, List<dynamic> trips, {required bool isBlue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlue ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey.shade100,
          width: isBlue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isBlue ? const Color(0xFF3B82F6).withOpacity(0.05) : Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(
                  title == 'Scheduled'
                      ? Icons.schedule
                      : (title == 'Ongoing' ? Icons.play_arrow : Icons.check_circle),
                  size: 16,
                  color: title == 'Scheduled'
                      ? const Color(0xFF3B82F6)
                      : (title == 'Ongoing' ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  '$title (${trips.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          ...trips.map((trip) => _buildTripCard(trip)).toList(),
        ],
      ),
    );
  }

  Widget _buildCompletedSection() {
    final allCompleted = _completedTrips;
    final displayTrips = _isFiltered || _showAllCompleted
        ? allCompleted
        : allCompleted.take(3).toList();
    final hasMore = !_isFiltered && allCompleted.length > 3 && !_showAllCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Completed (${allCompleted.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          ...displayTrips.map((trip) => _buildTripCard(trip, isCompleted: true)),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAllCompleted = true),
                  child: Text(
                    'Show ${allCompleted.length - 3} more completed trips',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, {bool isCompleted = false}) {
    final String status = trip['trip_status'] ?? 'Scheduled';
    final bool isScheduled = status == 'Scheduled';
    final bool isOngoing = status == 'Ongoing';

    Color statusColor = const Color(0xFF64748B);
    Color bgColor = const Color(0xFFF1F5F9);
    if (isOngoing) {
      statusColor = const Color(0xFF3B82F6);
      bgColor = const Color(0xFFEFF6FF);
    } else if (isCompleted) {
      statusColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFECFDF5);
    } else if (isScheduled) {
      statusColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip['route_name']?.toString() ?? 'Route',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                trip['schedule_date']?.toString() ?? 'No date',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 12, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${trip['departure_time']?.toString().substring(0, 5) ?? '--:--'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (!isCompleted && (isScheduled || isOngoing)) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateTripStatus(
                  trip['trip_id'],
                  isScheduled ? 'Ongoing' : 'Completed',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScheduled ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isScheduled ? Icons.play_arrow : Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isScheduled ? 'Start Trip' : 'Finish Trip',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── COLLAPSIBLE CALENDAR ──
  Widget _buildCalendarSection() {
    final theme = Theme.of(context);
    final tripDates = _myTrips
        .map((trip) => _parseTripDate(trip['schedule_date']?.toString()))
        .whereType<DateTime>()
        .map(
          (date) =>
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        )
        .toSet();

    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final firstWeekday = firstDay.weekday % 7;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
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
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _calendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.iconTheme.color,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_calendarMonth.monthName} ${_calendarMonth.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    color: const Color(0xFF64748B),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_calendarExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    children: [
                      ...['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(
                        (day) => Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(firstWeekday, (_) => const SizedBox()),
                      ...List.generate(daysInMonth, (index) {
                        final day = index + 1;
                        final date = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month,
                          day,
                        );
                        final key =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final hasTrip = tripDates.contains(key);
                        final isSelected =
                            _selectedDate != null &&
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
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.transparent),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white
                                      : (hasTrip
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF0F172A)),
                                  fontWeight: hasTrip ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // ─── PREFERENCES ───
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // In dark mode, you might want to dynamically change this container color too, or let the scaffold handle it!
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const DarkModeToggle(),
          ),
          const SizedBox(height: 20),
                  
                  
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: const Color(0xFFEFF6FF)),
                      const SizedBox(width: 4),
                      const Text(
                        'Has trips',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
    return names[month - 1];
  }
}