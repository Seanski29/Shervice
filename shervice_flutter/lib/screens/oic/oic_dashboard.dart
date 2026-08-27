import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class OicDashboard extends StatefulWidget {
  final String oicName;
  final String companyName;
  final String oicId;

  const OicDashboard({
    super.key,
    required this.oicName,
    required this.companyName,
    required this.oicId,
  });

  @override
  State<OicDashboard> createState() => _OicDashboardState();
}

class _OicDashboardState extends State<OicDashboard> {
  // ─── STATE ───
  String _currentPath = 'pending';
  String _passengerCount = '';
  Map<String, dynamic>? _selectedTrip;
  bool _isLoading = true;
  List<dynamic> _allTrips = [];

  // ─── DATE FILTER ───
  DateTime? _filterDate = DateTime.now(); // default to today

  // ─── PAGINATION ───
  int _pendingPage = 0;
  int _approvedPage = 0;
  int _dispatchedPage = 0;
  int _completedPage = 0;
  final int _itemsPerPage = 10;

  // ─── SORT & SEARCH ───
  String _pendingSort = 'Date (Newest)';
  String _approvedSort = 'Date (Newest)';
  String _dispatchedSort = 'Date (Newest)';
  String _completedSort = 'Date (Newest)';
  final List<String> _sortOptions = ['Date (Newest)', 'Date (Oldest)', 'Trip ID'];

  String _pendingSearch = '';
  String _approvedSearch = '';
  String _dispatchedSearch = '';
  String _completedSearch = '';

  // ─── LIFECYCLE ───
  @override
  void initState() {
    super.initState();
    _fetchLiveSchedules();
  }

  // ─── DATA FETCH ───
  Future<void> _fetchLiveSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/schedules/oic/${widget.oicId}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> fetchedTrips = data['data'] ?? [];
        setState(() {
          _allTrips = fetchedTrips;
          _isLoading = false;
        });
      } else {
        _showSnackBar('Failed to load trips. Server error ${res.statusCode}.', Colors.red);
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ OIC sync error: $e');
      _showSnackBar('Failed to sync schedules.', Colors.red);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── DISPATCH ───
  Future<void> _dispatchTripWithHeadcount() async {
    if (_selectedTrip == null || _passengerCount.trim().isEmpty) {
      _showSnackBar('Enter passenger headcount.', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$backendUrl/dispatch/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'trip_id': _selectedTrip!['trip_id'] ?? _selectedTrip!['id'],
              'passenger_count': int.tryParse(_passengerCount) ?? 0,
              'company_name': widget.companyName,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar('Trip dispatched!', Colors.green);
        _resetFormState();
        await _fetchLiveSchedules();
      } else {
        _showSnackBar('Error: ${res.statusCode}', Colors.red);
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Dispatch failed.', Colors.red);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFormState() {
    setState(() {
      _selectedTrip = null;
      _passengerCount = '';
    });
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── SORTING ───
  List<dynamic> _sortTrips(List<dynamic> trips, String sortBy) {
    final sorted = List<dynamic>.from(trips);
    switch (sortBy) {
      case 'Date (Newest)':
        sorted.sort((a, b) {
          final da = a['schedule_date'] ?? '';
          final db = b['schedule_date'] ?? '';
          return db.compareTo(da);
        });
        break;
      case 'Date (Oldest)':
        sorted.sort((a, b) {
          final da = a['schedule_date'] ?? '';
          final db = b['schedule_date'] ?? '';
          return da.compareTo(db);
        });
        break;
      case 'Trip ID':
        sorted.sort((a, b) {
          final idA = (a['trip_id'] ?? 0).toString();
          final idB = (b['trip_id'] ?? 0).toString();
          return idA.compareTo(idB);
        });
        break;
    }
    return sorted;
  }

  // ─── TAB BUTTON ───
  Widget _buildTabButton(String path, String label, IconData icon, Color activeColor) {
    final isActive = _currentPath == path;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _currentPath = path;
          _selectedTrip = null;
        }),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isActive ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: isActive ? activeColor : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11,
                    color: isActive ? activeColor : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── DATE FILTER TOGGLE ───
  Widget _buildDateFilterChip() {
    final isToday = _filterDate != null;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterDate = _filterDate == null ? DateTime.now() : null;
          // Reset pagination for all tabs
          _pendingPage = 0;
          _approvedPage = 0;
          _dispatchedPage = 0;
          _completedPage = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday ? const Color(0xFF3B82F6) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF3B82F6)),
            const SizedBox(width: 4),
            Text(
              isToday ? 'Today' : 'All Dates',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;
    final double pad = isMobile ? 8.0 : 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchLiveSchedules,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 8.0),
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
                          'Welcome, ${widget.oicName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dispatch Management',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
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
                        _fetchLiveSchedules();
                      },
                      icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 18),
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── COMPANY CHIP ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: Text(
                  widget.companyName,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── TABS ──
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildTabButton('pending', 'Pending', Icons.hourglass_top, Colors.orange.shade700),
                    _buildTabButton('approved', 'Scheduled', Icons.event_available, Colors.blue.shade700),
                    _buildTabButton('dispatched', 'Ongoing', Icons.local_shipping, Colors.green.shade700),
                    _buildTabButton('completed', 'Completed', Icons.check_circle, Colors.purple.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── DATE FILTER CHIP ──
              _buildDateFilterChip(),
              const SizedBox(height: 8),

              // ── CONTENT ──
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                    )
                  : _currentPath == 'pending'
                      ? _buildPendingView(isMobile)
                      : _currentPath == 'approved'
                          ? _buildApprovedView(isMobile)
                          : _currentPath == 'dispatched'
                              ? _buildDispatchedView(isMobile)
                              : _currentPath == 'manage_trip'
                                  ? _buildManageTripView(isMobile)
                                  : _buildCompletedView(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB VIEWS ───
  Widget _buildPendingView(bool isMobile) =>
      _buildTabContent('pending staff assignment', 'Pending', isMobile, _pendingPage, (p) => setState(() => _pendingPage = p), _pendingSort, (s) => setState(() => _pendingSort = s), _pendingSearch, (s) => setState(() => _pendingSearch = s));

  Widget _buildApprovedView(bool isMobile) =>
      _buildTabContent('scheduled', 'Scheduled', isMobile, _approvedPage, (p) => setState(() => _approvedPage = p), _approvedSort, (s) => setState(() => _approvedSort = s), _approvedSearch, (s) => setState(() => _approvedSearch = s));

  Widget _buildDispatchedView(bool isMobile) =>
      _buildTabContent('ongoing', 'Ongoing', isMobile, _dispatchedPage, (p) => setState(() => _dispatchedPage = p), _dispatchedSort, (s) => setState(() => _dispatchedSort = s), _dispatchedSearch, (s) => setState(() => _dispatchedSearch = s));

  Widget _buildCompletedView(bool isMobile) =>
      _buildTabContent('completed', 'Completed', isMobile, _completedPage, (p) => setState(() => _completedPage = p), _completedSort, (s) => setState(() => _completedSort = s), _completedSearch, (s) => setState(() => _completedSearch = s));

  Widget _buildTabContent(
    String statusFilter,
    String statusLabel,
    bool isMobile,
    int currentPage,
    Function(int) onPageChanged,
    String currentSort,
    Function(String) onSortChanged,
    String searchQuery,
    Function(String) onSearchChanged,
  ) {
    // Apply date filter, status filter, and search filter
    final filtered = _allTrips.where((t) {
      // Status filter
      final s = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      if (s != statusFilter) return false;

      // Date filter
      if (_filterDate != null) {
        final dateStr = t['schedule_date']?.toString() ?? '';
        final todayStr =
            '${_filterDate!.year}-${_filterDate!.month.toString().padLeft(2, '0')}-${_filterDate!.day.toString().padLeft(2, '0')}';
        if (!dateStr.startsWith(todayStr)) return false;
      }

      // Search filter
      final route = (t['route_name'] ?? '').toString().toLowerCase();
      final driver = (t['driver_name'] ?? t['user_account']?['full_name'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return route.contains(query) || driver.contains(query);
    }).toList();

    final sorted = _sortTrips(filtered, currentSort);

    return Column(
      children: [
        // ─── SEARCH + SORT ROW ───
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  controller: TextEditingController(text: searchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
                  decoration: InputDecoration(
                    hintText: 'Search trips...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF64748B)),
                    suffixIcon: searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => onSearchChanged(''),
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
                  value: currentSort,
                  icon: const Icon(Icons.sort, size: 14, color: Color(0xFF64748B)),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                  items: _sortOptions.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onSortChanged(val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ─── GRID OR EMPTY STATE ───
        filtered.isEmpty
            ? _buildEmptyState('No $statusLabel trips match your search')
            : _buildPaginatedGrid(
                items: sorted,
                isMobile: isMobile,
                currentPage: currentPage,
                onPageChanged: onPageChanged,
                itemBuilder: (trip) => _buildUltraCompactCard(trip, overrideStatus: statusLabel),
              ),
      ],
    );
  }

  // ─── DISPATCH TAB (unchanged) ───
  Widget _buildManageTripView(bool isMobile) {
    final scheduled = _allTrips.where((t) {
      final s = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return s == 'scheduled';
    }).toList();

    final selectedId = _selectedTrip?['trip_id'];

    Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Scheduled Trip',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        if (scheduled.isEmpty)
          _buildEmptyState('No scheduled trips to dispatch.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduled.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) {
              final trip = scheduled[i];
              final driver = trip['driver_name'] ?? trip['user_account']?['full_name'] ?? 'Unassigned';
              final vehicle = trip['plate_number'] ?? trip['vehicle']?['plate_number'] ?? 'No Shuttle';
              final pax = trip['passenger_count'] ?? 0;
              final isSelected = selectedId == trip['trip_id'];

              return GestureDetector(
                onTap: () => setState(() => _selectedTrip = trip),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRIP-${trip['trip_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              trip['route_name'] ?? 'Unassigned',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Wrap(
                              spacing: 4,
                              children: [
                                _infoChip(Icons.person, driver),
                                _infoChip(Icons.directions_car, vehicle),
                                _infoChip(Icons.people, '$pax pax'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SCHEDULED',
                          style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.green.shade700),
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

    Widget panel = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _selectedTrip == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dispatch Trip',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a trip above.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispatch #${_selectedTrip!['trip_id']}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Passenger Count',
                    hintText: 'Enter count',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                  onChanged: (v) => _passengerCount = v,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    onPressed: _dispatchTripWithHeadcount,
                    child: const Text(
                      'Dispatch',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
    );

    return isMobile
        ? Column(children: [list, const SizedBox(height: 12), panel])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: list),
              const SizedBox(width: 16),
              Expanded(child: panel),
            ],
          );
  }

  // ─── ULTRA-COMPACT CARD ───
  Widget _buildUltraCompactCard(dynamic trip, {String? overrideStatus}) {
    final status = (overrideStatus ?? trip['trip_status'] ?? 'Scheduled').toString().toLowerCase();
    final driver = trip['driver_name'] ?? trip['user_account']?['full_name'] ?? 'Unassigned';
    final vehicle = trip['plate_number'] ?? trip['vehicle']?['plate_number'] ?? 'No Shuttle';
    final dep = _formatTime(trip['departure_time']);
    final arr = _formatTime(trip['estimated_arrival_time']);
    final pax = trip['passenger_count'] ?? 0;
    final distance = trip['route_distance'] ?? 0;

    Color statusColor;
    Color bgColor;
    String statusLabel;
    switch (status) {
      case 'ongoing':
        statusColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        statusLabel = 'ONGOING';
        break;
      case 'scheduled':
        statusColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        statusLabel = 'SCHEDULED';
        break;
      case 'completed':
        statusColor = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF3E8FF);
        statusLabel = 'COMPLETED';
        break;
      case 'pending staff assignment':
        statusColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        statusLabel = 'PENDING';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        statusLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'TRIP-${trip['trip_id']} • ${trip['route_name'] ?? 'Unassigned'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _tinyChip(Icons.person, driver),
                    _tinyChip(Icons.directions_car, vehicle),
                    _tinyChip(Icons.access_time, '$dep → $arr'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  _tinyChip(Icons.people, '$pax pax'),
                  const SizedBox(width: 6),
                  _tinyChip(Icons.straighten, '$distance km'),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      );

  Widget _infoChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF64748B)),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  // ─── HELPERS ───
  Widget _buildEmptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      );

  String _formatTime(dynamic t) {
    if (t == null || t.toString().trim().isEmpty) return 'TBD';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  // ─── PAGINATED GRID ───
  Widget _buildPaginatedGrid({
    required List<dynamic> items,
    required bool isMobile,
    required int currentPage,
    required Function(int) onPageChanged,
    required Widget Function(dynamic) itemBuilder,
  }) {
    final totalPages = (items.length / _itemsPerPage).ceil();
    final start = currentPage * _itemsPerPage;
    final end = min(start + _itemsPerPage, items.length);
    final pageItems = items.sublist(start, end);

    Widget grid;
    if (isMobile) {
      grid = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pageItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, i) => itemBuilder(pageItems[i]),
      );
    } else {
      grid = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.8,
        ),
        itemCount: pageItems.length,
        itemBuilder: (_, i) => itemBuilder(pageItems[i]),
      );
    }

    return Column(
      children: [
        grid,
        if (items.length > _itemsPerPage)
          _buildPagination(start, end, totalPages, currentPage, onPageChanged, items.length),
      ],
    );
  }

  Widget _buildPagination(int start, int end, int totalPages, int currentPage, Function(int) onChanged, int total) =>
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${start + 1}–$end of $total', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 14),
                  onPressed: currentPage > 0 ? () => onChanged(currentPage - 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  color: currentPage > 0 ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${currentPage + 1}/$totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 10),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 14),
                  onPressed: currentPage < totalPages - 1 ? () => onChanged(currentPage + 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  color: currentPage < totalPages - 1 ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      );
}