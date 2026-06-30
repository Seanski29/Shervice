import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

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
  final List<String> _sortOptions = ['Date (Newest)', 'Date (Oldest)', 'Status'];
  int _currentPage = 0;
  final int _itemsPerPage = 3;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchMySchedules();
  }

  Future<void> _fetchMySchedules() async {
    try {
      // Fetch only the trips assigned to this specific driver
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/driver/${widget.driverId}'),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _myTrips = data['data'] ?? [];
          _isLoading = false;
          _currentPage = 0;
          _selectedDate = null;
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
        Uri.parse(
          '$backendUrl/schedules/update-status',
        ), // We will create this Python route next!
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trip_id': tripId, 'status': newStatus}),
      );
      if (res.statusCode == 200 && mounted) {
        _fetchMySchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Completed'
                  ? 'Trip Finished! Assets Released.'
                  : 'Trip Started! Drive safely.',
            ),
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

  List<dynamic> _getSortedTrips() {
    final filteredTrips = _selectedDate == null
        ? List<dynamic>.from(_myTrips)
        : _myTrips.where((trip) {
            final tripDate = _parseTripDate(trip['schedule_date']?.toString());
            return tripDate != null &&
                tripDate.year == _selectedDate!.year &&
                tripDate.month == _selectedDate!.month &&
                tripDate.day == _selectedDate!.day;
          }).toList();

    filteredTrips.sort((a, b) {
      final dateA = _parseTripDate(a['schedule_date']?.toString());
      final dateB = _parseTripDate(b['schedule_date']?.toString());
      switch (_currentSort) {
        case 'Date (Oldest)':
          return (dateA ?? DateTime(2100)).compareTo(dateB ?? DateTime(2100));
        case 'Status':
          return ((a['trip_status'] ?? '').toString()).compareTo((b['trip_status'] ?? '').toString());
        case 'Date (Newest)':
        default:
          return (dateB ?? DateTime(0)).compareTo(dateA ?? DateTime(0));
      }
    });

    return filteredTrips;
  }

  int get _totalPages {
    final tripCount = _getSortedTrips().length;
    if (tripCount == 0) return 1;
    return (tripCount / _itemsPerPage).ceil();
  }

  List<dynamic> get _paginatedTrips {
    final sortedTrips = _getSortedTrips();
    if (sortedTrips.isEmpty) return [];
    final start = _currentPage * _itemsPerPage;
    final end = min(start + _itemsPerPage, sortedTrips.length);
    return sortedTrips.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() => _currentPage = page);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day
          ? null
          : date;
      _currentPage = 0;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedTrips = _getSortedTrips();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Schedule',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Keep your assignments organized and review them quickly on the go.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sortedTrips.length} trip${sortedTrips.length == 1 ? '' : 's'} planned',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate == null
                                      ? 'Showing all schedules'
                                      : 'Filtered for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.route, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Live status',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currentSort,
                            decoration: InputDecoration(
                              labelText: 'Sort by',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
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
                                  _currentPage = 0;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _currentPage = 0;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (sortedTrips.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            'No trips found for the selected day.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      ..._paginatedTrips.map((trip) => _buildScheduleCard(trip)),
                      if (_totalPages > 1) ...[
                        const SizedBox(height: 16),
                        _buildPaginationBar(),
                      ],
                    ],
                    const SizedBox(height: 24),
                    _buildCalendarSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _getSortedTrips().length)} of ${_getSortedTrips().length}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          OutlinedButton(
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final tripDates = _myTrips
        .map((trip) => _parseTripDate(trip['schedule_date']?.toString()))
        .whereType<DateTime>()
        .map((date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
        .toSet();

    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_calendarMonth.monthName} ${_calendarMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.1,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              ...['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) => Center(child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)))),
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
                          ? Colors.blue.shade600
                          : (hasTrip ? Colors.blue.shade50 : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: hasTrip ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: Colors.blue.shade100),
              const SizedBox(width: 6),
              const Text('Days with assigned trips', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> trip) {
    final String status = trip['trip_status'] ?? 'Scheduled';
    Color statusColor = Colors.grey;
    Color bgColor = Colors.grey.shade100;

    if (status == 'Ongoing') {
      statusColor = Colors.blue.shade700;
      bgColor = Colors.blue.shade50;
    } else if (status == 'Completed') {
      statusColor = Colors.green.shade700;
      bgColor = Colors.green.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip['schedule_date']?.toString() ?? 'No date',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip['route_name']?.toString() ?? 'Route',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Departure: ${trip['departure_time'] ?? 'Not available'}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (status == 'Scheduled') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateTripStatus(trip['trip_id'], 'Ongoing'),
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                label: const Text('Start Trip', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else if (status == 'Ongoing') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateTripStatus(trip['trip_id'], 'Completed'),
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                label: const Text('Finish Trip', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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
      'December'
    ];
    return names[month - 1];
  }
}
