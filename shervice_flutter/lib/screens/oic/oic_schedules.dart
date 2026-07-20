import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class OicSchedules extends StatefulWidget {
  final String oicId;

  const OicSchedules({super.key, required this.oicId});

  @override
  State<OicSchedules> createState() => _OicSchedulesState();
}

class _OicSchedulesState extends State<OicSchedules> {
  bool _isLoading = true;
  List<dynamic> _myTrips = [];
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/schedules/oic/${widget.oicId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _myTrips = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewScheduleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          CreateTripRequestDialog(oicId: widget.oicId),
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchMyTrips();
      }
    });
  }

  void _showEditScheduleModal(BuildContext context, Map<String, dynamic> trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          EditTripRequestDialog(trip: trip, backendUrl: backendUrl),
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchMyTrips();
      }
    });
  }

  List<dynamic> get _recentSchedules {
    final sorted = [..._myTrips]
      ..sort((a, b) {
        final aDate = _parseDate(a['schedule_date']);
        final bDate = _parseDate(b['schedule_date']);
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
    return sorted.take(4).toList();
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

  String _formatDateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  List<dynamic> _schedulesForDate(DateTime day) {
    return _myTrips.where((trip) {
      final date = _parseDate(trip['schedule_date']);
      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  void _showDayDetailsDialog(DateTime day, List<dynamic> schedules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_formatDateLabel(day)),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final trip = schedules[index];
              final statusStr = trip['trip_status']?.toString() ?? 'Unknown';
              final isPending = statusStr.toLowerCase().contains('pending');
              final isRejected = statusStr.toLowerCase().contains('rejected');
              Color statusColor = isRejected ? const Color(0xFFEF4444) : (isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
              Color statusBg = isRejected ? const Color(0xFFFEF2F2) : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5));

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['route_name'] ?? 'Unknown Route',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${trip['schedule_date']} • ${_formatTime(trip['departure_time'])} → ${_formatTime(trip['estimated_arrival_time'])}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '👥 ${trip['passenger_count'] ?? 0}  •  📍 ${trip['route_distance'] ?? 0} km',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusStr,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPending || isRejected)
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditScheduleModal(context, trip);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int get _totalTrips => _myTrips.length;
  int get _pendingTrips => _myTrips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase().contains('pending')).length;
  int get _rejectedTrips => _myTrips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase().contains('rejected')).length;
  int get _scheduledTrips => _myTrips.where((t) => (t['trip_status'] ?? '').toString().toLowerCase() == 'scheduled').length;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchMyTrips,
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
                          'My Trip Requests',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Calendar view of your schedules and dispatches.',
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
                        _fetchMyTrips();
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 20),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showNewScheduleModal(context),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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
                  _statChip(Icons.hourglass_top, _pendingTrips.toString(), 'Pending', const Color(0xFFF59E0B)),
                  _statChip(Icons.event_available, _scheduledTrips.toString(), 'Scheduled', const Color(0xFF10B981)),
                  _statChip(Icons.cancel, _rejectedTrips.toString(), 'Rejected', const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 12),

              // ── RECENT SCHEDULES ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Schedules',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                      )
                    else if (_recentSchedules.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text('No schedules yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ),
                      )
                    else
                      Column(
                        children: _recentSchedules.map((trip) => _buildRecentCard(trip)).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── COMPACT CALENDAR ──
              Container(
                padding: const EdgeInsets.all(8),
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
                child: _buildCalendar(),
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

  Widget _buildRecentCard(Map<String, dynamic> trip) {
    final statusStr = trip['trip_status']?.toString() ?? 'Unknown';
    final isPending = statusStr.toLowerCase().contains('pending');
    final isRejected = statusStr.toLowerCase().contains('rejected');
    final isScheduled = statusStr.toLowerCase() == 'scheduled';

    Color statusColor;
    String statusLabel;
    if (isRejected) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'REJECTED';
    } else if (isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'PENDING';
    } else if (isScheduled) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'SCHEDULED';
    } else {
      statusColor = const Color(0xFF64748B);
      statusLabel = statusStr.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['route_name'] ?? 'Unknown Route',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${trip['schedule_date']} • ${_formatTime(trip['departure_time'])} → ${_formatTime(trip['estimated_arrival_time'])}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
          if (isPending || isRejected)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 14),
              onPressed: () => _showEditScheduleModal(context, trip),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  // ─── COMPACT CALENDAR ───
  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysBefore = firstDay.weekday % 7;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = ((daysBefore + daysInMonth) / 7).ceil() * 7;
    final now = DateTime.now();

    return Column(
      children: [
        // ── Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        // ── Weekday headers ──
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Color(0xFF475569)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        // ── Days grid (compact) ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, index - daysBefore + 1);
            final isCurrentMonth = date.month == _focusedMonth.month;
            final schedules = _schedulesForDate(date);
            final isOccupied = schedules.isNotEmpty;
            final isSelected = _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day;
            final isToday = now.year == date.year && now.month == date.month && now.day == date.day;

            return InkWell(
              onTap: isOccupied
                  ? () {
                      setState(() => _selectedDate = date);
                      _showDayDetailsDialog(date, schedules);
                    }
                  : () => setState(() => _selectedDate = date),
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
                padding: const EdgeInsets.all(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 9,
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
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          schedules.length > 1 ? '${schedules.length}' : '•',
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── CREATE TRIP REQUEST DIALOG (unchanged) ───
class CreateTripRequestDialog extends StatefulWidget {
  final String oicId;

  const CreateTripRequestDialog({super.key, required this.oicId});

  @override
  State<CreateTripRequestDialog> createState() =>
      _CreateTripRequestDialogState();
}

class _CreateTripRequestDialogState extends State<CreateTripRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _loadingStaff = true;

  List<dynamic> _staffMembers = [];
  String? _selectedStaffId;

  final _destinationController = TextEditingController();
  final _passengerController = TextEditingController();
  final _distanceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedArrivalTime;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/schedules/staff-options'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && mounted) {
        setState(() {
          _staffMembers = data['data'];
          _loadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null ||
        _selectedArrivalTime == null || _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
    final formattedETA = "${_selectedArrivalTime!.hour.toString().padLeft(2, '0')}:${_selectedArrivalTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/schedules/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "oic_id": widget.oicId,
          "staff_id": _selectedStaffId,
          "destination": _destinationController.text.trim(),
          "passenger_count": _passengerController.text.trim(),
          "route_distance": _distanceController.text.trim(),
          "departure_date": formattedDate,
          "departure_time": formattedTime,
          "estimated_arrival_time": formattedETA,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip requested!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(data['message'] ?? "Failed to submit request.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Request Schedule",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingStaff)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Dispatch Staff",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.support_agent, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    value: _selectedStaffId,
                    items: _staffMembers
                        .map((s) => DropdownMenuItem<String>(
                              value: s['user_id'],
                              child: Text(s['full_name'] ?? 'Staff'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedStaffId = val),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(
                    labelText: "Route / Destination",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid";
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: "Distance (km)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passengerController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          final count = int.tryParse(val);
                          if (count == null) return "Invalid";
                          if (count > 20) return "Max 20";
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: "Passengers",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? "Select Date"
                                : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Depart',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedTime == null ? "Time" : _selectedTime!.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null) setState(() => _selectedArrivalTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'ETA',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedArrivalTime == null ? "Arrival" : _selectedArrivalTime!.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

// ─── EDIT TRIP REQUEST DIALOG (unchanged) ───
class EditTripRequestDialog extends StatefulWidget {
  final Map<String, dynamic> trip;
  final String backendUrl;

  const EditTripRequestDialog({
    super.key,
    required this.trip,
    required this.backendUrl,
  });

  @override
  State<EditTripRequestDialog> createState() => _EditTripRequestDialogState();
}

class _EditTripRequestDialogState extends State<EditTripRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _destinationController;
  late TextEditingController _passengerController;
  late TextEditingController _distanceController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedArrivalTime;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: widget.trip['route_name']);
    _passengerController = TextEditingController(text: widget.trip['passenger_count'].toString());
    _distanceController = TextEditingController(text: widget.trip['route_distance'].toString());

    if (widget.trip['schedule_date'] != null) {
      _selectedDate = DateTime.parse(widget.trip['schedule_date'].toString().split(' ').first);
    }
    _selectedTime = _parseTimeOfDay(widget.trip['departure_time']);
    _selectedArrivalTime = _parseTimeOfDay(widget.trip['estimated_arrival_time']);
  }

  TimeOfDay? _parseTimeOfDay(dynamic timeString) {
    if (timeString == null) return null;
    final parts = timeString.toString().split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedArrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";
    final formattedETA = "${_selectedArrivalTime!.hour.toString().padLeft(2, '0')}:${_selectedArrivalTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      final response = await http.put(
        Uri.parse('${widget.backendUrl}/schedules/update-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "trip_id": widget.trip['trip_id'],
          "staff_id": widget.trip['staff_id'],
          "destination": _destinationController.text.trim(),
          "passenger_count": _passengerController.text.trim(),
          "route_distance": _distanceController.text.trim(),
          "departure_date": formattedDate,
          "departure_time": formattedTime,
          "estimated_arrival_time": formattedETA,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip updated!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(data['message'] ?? "Failed to update request.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Edit Request",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _destinationController,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(
                    labelText: "Route / Destination",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || val.isEmpty
                            ? "Required"
                            : (double.tryParse(val) == null ? "Invalid" : null),
                        decoration: const InputDecoration(
                          labelText: "Distance (km)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passengerController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          final count = int.tryParse(val);
                          if (count == null) return "Invalid";
                          if (count > 20) return "Max 20";
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: "Passengers",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? "Select Date"
                                : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Depart',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedTime == null ? "Time" : _selectedTime!.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedArrivalTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null) setState(() => _selectedArrivalTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'ETA',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: Text(
                            _selectedArrivalTime == null ? "Arrival" : _selectedArrivalTime!.format(context),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}