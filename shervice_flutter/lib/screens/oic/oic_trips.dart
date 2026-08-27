import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import '../../constant.dart';

class OicTrips extends StatefulWidget {
  final String oicId;

  const OicTrips({super.key, required this.oicId});

  @override
  State<OicTrips> createState() => _OicTripsState();
}

class _OicTripsState extends State<OicTrips> {
  String _searchTerm = '';
  String _sortOption = 'Date (Newest)';
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Route Name',
    'Status (Priority)',
  ];

  DateTime? _filterDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _calendarExpanded = false;

  List<dynamic> _trips = [];
  bool _isLoading = true;

  // ─── PAGINATION ───
  int _currentPage = 0;
  final int _itemsPerPage = 6;

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
            _currentPage = 0;
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

  // ─── FILTER + SORT + PAGINATION ───
  List<dynamic> get _filteredAndSortedTrips {
    // 1. Date filter
    List<dynamic> filtered = _trips.where((trip) {
      if (_filterDate == null) return true;
      final dateStr = trip['schedule_date']?.toString() ?? '';
      final todayStr =
          '${_filterDate!.year}-${_filterDate!.month.toString().padLeft(2, '0')}-${_filterDate!.day.toString().padLeft(2, '0')}';
      return dateStr.startsWith(todayStr);
    }).toList();

    // 2. Search filter
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((trip) {
        final route = (trip['route_name'] ?? '').toString().toLowerCase();
        final driver = (trip['driver_name'] ?? '').toString().toLowerCase();
        final query = _searchTerm.toLowerCase();
        return route.contains(query) || driver.contains(query);
      }).toList();
    }

    // 3. Sort
    switch (_sortOption) {
      case 'Date (Newest)':
        filtered.sort((a, b) {
          final da = _parseDate(a['schedule_date']);
          final db = _parseDate(b['schedule_date']);
          if (da == null || db == null) return 0;
          return db.compareTo(da);
        });
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) {
          final da = _parseDate(a['schedule_date']);
          final db = _parseDate(b['schedule_date']);
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });
        break;
      case 'Route Name':
        filtered.sort((a, b) {
          final ra = (a['route_name'] ?? '').toString().toLowerCase();
          final rb = (b['route_name'] ?? '').toString().toLowerCase();
          return ra.compareTo(rb);
        });
        break;
      case 'Status (Priority)':
        filtered.sort((a, b) {
          final statusA = (a['trip_status'] ?? '').toString().toLowerCase();
          final statusB = (b['trip_status'] ?? '').toString().toLowerCase();
          final priority = {
            'pending staff assignment': 0,
            'rejected': 1,
            'completed': 2,
            'ongoing': 3,
            'scheduled': 4,
          };
          final pA = priority[statusA] ?? 5;
          final pB = priority[statusB] ?? 5;
          return pA.compareTo(pB);
        });
        break;
    }
    return filtered;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      try {
        return DateTime.parse(text.split(' ').first);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int get _totalPages => (_filteredAndSortedTrips.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedTrips {
    final start = _currentPage * _itemsPerPage;
    final end = min(start + _itemsPerPage, _filteredAndSortedTrips.length);
    return _filteredAndSortedTrips.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() => _currentPage = page);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _filterDate =
          _filterDate != null &&
                  _filterDate!.year == date.year &&
                  _filterDate!.month == date.month &&
                  _filterDate!.day == date.day
              ? null
              : date;
      _currentPage = 0;
    });
  }

  List<dynamic> _schedulesForDate(DateTime day) {
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _trips.where((trip) {
      final tripDate = trip['schedule_date']?.toString() ?? '';
      return tripDate.startsWith(dateStr);
    }).toList();
  }

  // ─── STATS ───
  int get _totalTrips => _trips.length;
  int get _todayTrips => _trips.where((t) {
        final dateStr = t['schedule_date']?.toString() ?? '';
        final todayStr =
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
        return dateStr.startsWith(todayStr);
      }).length;
  int get _scheduledTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'scheduled').length;
  int get _ongoingTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'ongoing').length;
  int get _completedTrips => _trips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'completed').length;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 10.0 : 20.0;
    final totalItems = _filteredAndSortedTrips.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchDeploymentLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
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
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Comprehensive log of all fleet deployments.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _fetchDeploymentLogs();
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 18),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── STATS CHIPS ──
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _statChip(Icons.list_alt, _totalTrips.toString(), 'Total', const Color(0xFF3B82F6)),
                  _statChip(Icons.today, _todayTrips.toString(), 'Today', const Color(0xFF8B5CF6)),
                  _statChip(Icons.event_available, _scheduledTrips.toString(), 'Scheduled', const Color(0xFFF59E0B)),
                  _statChip(Icons.play_arrow, _ongoingTrips.toString(), 'Ongoing', const Color(0xFF10B981)),
                  _statChip(Icons.check_circle, _completedTrips.toString(), 'Completed', const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 8),

              // ── DATE FILTER CHIP + SEARCH + SORT ──
              Row(
                children: [
                  // Date filter chip – toggles Today / All Dates
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterDate = _filterDate == null ? DateTime.now() : null;
                        _currentPage = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _filterDate != null ? const Color(0xFFEFF6FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _filterDate != null ? const Color(0xFF3B82F6) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Text(
                            _filterDate != null ? 'Today' : 'All Dates',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() {
                          _searchTerm = val;
                          _currentPage = 0;
                        }),
                        decoration: InputDecoration(
                          hintText: '',
                          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF64748B)),
                          suffixIcon: _searchTerm.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() {
                                    _searchTerm = '';
                                    _currentPage = 0;
                                  }),
                                  child: const Icon(Icons.clear, size: 14, color: Color(0xFF64748B)),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortOption,
                        icon: const Icon(Icons.sort, size: 14, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                        items: _sortOptions.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _sortOption = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── TRIP LIST ──
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
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
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                      )
                    : totalItems == 0
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No trips found.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _paginatedTrips.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                itemBuilder: (context, index) {
                                  final trip = _paginatedTrips[index];
                                  return _buildTripCard(trip);
                                },
                              ),
                              if (_totalPages > 1) _buildPagination(),
                            ],
                          ),
              ),
              const SizedBox(height: 10),

              // ── COLLAPSIBLE CALENDAR ──
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    // ── Calendar toggle header ──
                    InkWell(
                      onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _calendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: const Color(0xFF64748B),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Calendar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 16),
                              onPressed: () => _changeMonth(-1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 16),
                              onPressed: () => _changeMonth(1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_calendarExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: _buildCalendarGrid(),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = (trip['trip_status'] ?? 'Scheduled').toString().toLowerCase();
    final driver = trip['driver_name'] ?? 'Unassigned';
    final plate = trip['plate_number'] ?? 'No Plate';
    final route = trip['route_name'] ?? 'Unknown Route';
    final pax = trip['passenger_count'] ?? 0;
    final distance = trip['route_distance'] ?? 0;
    final dep = _formatTimeString(trip['departure_time']);
    final arr = _formatTimeString(trip['estimated_arrival_time']);
    final date = trip['schedule_date'] ?? 'TBD';

    Color statusColor;
    String statusLabel;
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Status indicator bar
          Container(
            width: 3,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
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
                const SizedBox(height: 1),
                Wrap(
                  spacing: 4,
                  runSpacing: 1,
                  children: [
                    _infoChip(Icons.calendar_today, date),
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

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${(_currentPage * _itemsPerPage) + 1}–${min((_currentPage + 1) * _itemsPerPage, _filteredAndSortedTrips.length)} of ${_filteredAndSortedTrips.length}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 14),
                onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                color: _currentPage > 0 ? const Color(0xFF3B82F6) : Colors.grey.shade300,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                    fontSize: 10,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 14),
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                color: _currentPage < _totalPages - 1 ? const Color(0xFF3B82F6) : Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── COMPACT CALENDAR GRID ───
  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysBefore = firstDay.weekday % 7;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = ((daysBefore + daysInMonth) / 7).ceil() * 7;
    final now = DateTime.now();

    return Column(
      children: [
        // ── Weekday headers ──
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 7, color: Color(0xFF475569)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        // ── Days grid ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, index - daysBefore + 1);
            final isCurrentMonth = date.month == _focusedMonth.month;
            final schedules = _schedulesForDate(date);
            final isOccupied = schedules.isNotEmpty;
            final isSelected = _filterDate != null &&
                _filterDate!.year == date.year &&
                _filterDate!.month == date.month &&
                _filterDate!.day == date.day;
            final isToday = now.year == date.year && now.month == date.month && now.day == date.day;

            return InkWell(
              onTap: () => _onDateSelected(date),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : (isOccupied
                          ? const Color(0xFFEFF6FF)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFFF59E0B)
                        : (isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade200),
                    width: isToday ? 1.2 : (isSelected ? 1.2 : 0.5),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8)),
                        ),
                      ),
                      if (isOccupied)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            schedules.length > 1 ? '${schedules.length}' : '•',
                            style: TextStyle(
                              fontSize: 5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}