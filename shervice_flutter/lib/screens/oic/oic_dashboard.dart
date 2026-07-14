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
  // ─── TAB STATE ───
  // 5 tabs: pending, approved, dispatched, manage_trip, completed
  String _currentPath = 'pending';

  // ─── FORM STATE ───
  String _passengerCount = '';
  Map<String, dynamic>? _selectedTrip;

  // ─── DATA STATE ───
  bool _isLoading = true;
  List<dynamic> _allTrips = [];

  // ─── PAGINATION STATE (one per paginated tab) ───
  int _pendingPage = 0;
  int _approvedPage = 0;
  int _dispatchedPage = 0;
  int _completedPage = 0;
  final int _itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _fetchLiveSchedules();
  }

  // ─── DATA FETCH: trips ───
  Future<void> _fetchLiveSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final tripsRes = await http.get(Uri.parse('$backendUrl/trips'));

      if (tripsRes.statusCode == 200) {
        final tripsData = jsonDecode(tripsRes.body);
        final List<dynamic> fetchedTrips = tripsData['trips'] ?? [];

        // Filter trips belonging to this OIC by ID or company name
        final matchingTrips = fetchedTrips.where((t) {
          final dbOicId = t['oic_id']?.toString() ?? '';
          final targetOicId = widget.oicId.toString().trim();
          if (dbOicId == targetOicId) return true;

          final dbCompany = (t['oic_profile'] ?? {})['company_name']
                  ?.toString()
                  .toLowerCase()
                  .trim() ??
              '';
          return dbCompany == widget.companyName.toLowerCase().trim();
        }).toList();

        setState(() {
          _allTrips = matchingTrips;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ OIC Schedule Sync Error: $e');
      _showSnackBar('Failed to sync latest trip schedules.', Colors.red);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── DISPATCH ACTION ───
  Future<void> _dispatchTripWithHeadcount() async {
    if (_selectedTrip == null || _passengerCount.trim().isEmpty) {
      _showSnackBar('Please enter a valid passenger headcount.', Colors.orange);
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
        _showSnackBar('Trip successfully dispatched!', Colors.green);
        _resetFormState();
        await _fetchLiveSchedules();
      } else {
        _showSnackBar('Server error: ${res.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Dispatch transmission failure.', Colors.red);
    } finally {
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
      ),
    );
  }

  // ─── TAB BUTTON BUILDER (Code 2 design with FittedBox) ───
  Widget _buildTabButton(
    String path,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isActive = _currentPath == path;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _currentPath = path;
          _selectedTrip = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: isActive
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeColor : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

  // ─── ROOT BUILD ───
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchLiveSchedules,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Code 2 Wrap design) ──
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Welcome, ${widget.oicName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      widget.companyName,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'OIC Dispatch Management | Monitor rotations, dispatch fleets, and review completed trips.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // ── 5-Tab Navigation ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      'pending',
                      'Pending',
                      Icons.hourglass_top,
                      Colors.orange.shade700,
                    ),
                    _buildTabButton(
                      'approved',
                      'Approved',
                      Icons.event_available,
                      Colors.blue.shade700,
                    ),
                    _buildTabButton(
                      'dispatched',
                      'Ongoing',
                      Icons.local_shipping,
                      Colors.green.shade700,
                    ),
                    _buildTabButton(
                      'manage_trip',
                      'Dispatch',
                      Icons.send,
                      Colors.teal.shade700,
                    ),
                    _buildTabButton(
                      'completed',
                      'Completed',
                      Icons.check_circle,
                      Colors.purple.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tab Content ──
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(60.0),
                      child: Center(child: CircularProgressIndicator()),
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

  // ─── TAB 1: PENDING VIEW (Pending Staff Assignment) ───
  Widget _buildPendingView(bool isMobile) {
    final pendingTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'pending staff assignment';
    }).toList();

    if (pendingTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "No trips currently pending staff assignment layouts.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    int totalPages = (pendingTrips.length / _itemsPerPage).ceil();
    int startIdx = _pendingPage * _itemsPerPage;
    int endIdx = min(startIdx + _itemsPerPage, pendingTrips.length);
    List<dynamic> activePageList = pendingTrips.sublist(startIdx, endIdx);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: activePageList.length,
          itemBuilder: (context, index) {
            final trip = activePageList[index];
            final driverName =
                (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final vehiclePlate =
                (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';

            final departure = _formatTimeString(trip['departure_time']);
            final arrival = _formatTimeString(trip['estimated_arrival_time']);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TRIP ID: ${trip['trip_id']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "PENDING ASSIGNMENT",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconTextRow(
                    Icons.access_time,
                    "${trip['schedule_date']} | $departure - $arrival",
                  ),
                  const SizedBox(height: 4),
                  _iconTextRow(
                    Icons.location_on,
                    trip['route_name'] ?? 'Unassigned Route',
                  ),
                  const SizedBox(height: 4),
                  _iconTextRow(
                    Icons.airport_shuttle,
                    "Shuttle: $vehiclePlate | Driver: $driverName",
                  ),
                ],
              ),
            );
          },
        ),
        _buildPaginationControls(
          pendingTrips.length,
          startIdx,
          endIdx,
          totalPages,
          _pendingPage,
          (newPage) {
            setState(() => _pendingPage = newPage);
          },
        ),
      ],
    );
  }

  // ─── TAB 2: APPROVED ───
  Widget _buildApprovedView(bool isMobile) {
    final filtered = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'scheduled';
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No upcoming approved scheduled runs found.');
    }

    int totalPages = (filtered.length / _itemsPerPage).ceil();
    int startIdx = _approvedPage * _itemsPerPage;
    int endIdx = min(startIdx + _itemsPerPage, filtered.length);
    List<dynamic> activePageList = filtered.sublist(startIdx, endIdx);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: activePageList.length,
          itemBuilder: (context, index) {
            final trip = activePageList[index];
            final driverName =
                (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final vehiclePlate =
                (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';

            final departure = _formatTimeString(trip['departure_time']);
            final arrival = _formatTimeString(trip['estimated_arrival_time']);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TRIP ID: ${trip['trip_id']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "SCHEDULED",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconTextRow(
                    Icons.access_time,
                    "${trip['schedule_date']} | $departure - $arrival",
                  ),
                  const SizedBox(height: 4),
                  _iconTextRow(
                    Icons.location_on,
                    trip['route_name'] ?? 'Unassigned Route',
                  ),
                  const SizedBox(height: 4),
                  _iconTextRow(
                    Icons.airport_shuttle,
                    "Shuttle: $vehiclePlate | Driver: $driverName",
                  ),
                ],
              ),
            );
          },
        ),
        _buildPaginationControls(
          filtered.length,
          startIdx,
          endIdx,
          totalPages,
          _approvedPage,
          (newPage) {
            setState(() => _approvedPage = newPage);
          },
        ),
      ],
    );
  }

  // ─── TAB 3: ONGOING ───
  Widget _buildDispatchedView(bool isMobile) {
    final filtered = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'ongoing';
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No ongoing departures currently active.');
    }

    return _buildPaginatedGrid(
      items: filtered,
      isMobile: isMobile,
      currentPage: _dispatchedPage,
      onPageChanged: (p) => setState(() => _dispatchedPage = p),
      itemBuilder: (trip) => _buildTripCard(
        trip,
        overrideStatus: 'Ongoing',
        extraRow: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '👥 ${trip['passenger_count'] ?? 0} Passengers',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 4: DISPATCH (no pagination — action-based) ───
  Widget _buildManageTripView(bool isMobile) {
    final scheduledTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'scheduled';
    }).toList();

    final selectedTripId = _selectedTrip?['trip_id'];

    Widget tripSelectionList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Scheduled Trip to Dispatch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (scheduledTrips.isEmpty)
          _buildEmptyState(
            'No scheduled trips are available to dispatch right now.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduledTrips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = scheduledTrips[index];
              final driverName =
                  (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
              final vehiclePlate =
                  (trip['vehicle'] ?? {})['plate_number'] ??
                  'No Shuttle Linked';
              final passengerCount = trip['passenger_count'] ?? 0;

              final departure = _formatTimeString(trip['departure_time']);
              final arrival = _formatTimeString(trip['estimated_arrival_time']);
              final isSelected = selectedTripId == trip['trip_id'];

              return GestureDetector(
                onTap: () => setState(() => _selectedTrip = trip),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.teal.shade300
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "TRIP ID: ${trip['trip_id']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "SCHEDULED",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${trip['schedule_date']} | $departure - $arrival",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip['route_name'] ?? 'Unassigned Route',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Shuttle: $vehiclePlate | Driver: $driverName",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "👥 $passengerCount Passengers",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
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

    Widget actionPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _selectedTrip == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dispatch Trip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a scheduled trip from the list to assign a passenger headcount and dispatch it.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispatch Trip #${_selectedTrip!['trip_id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Passenger Headcount',
                    hintText: 'Enter passenger count',
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => _passengerCount = value,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _dispatchTripWithHeadcount,
                    child: const Text(
                      'Dispatch Trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tripSelectionList, const SizedBox(height: 32), actionPanel],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tripSelectionList),
        const SizedBox(width: 32),
        Expanded(child: actionPanel),
      ],
    );
  }

  // ─── TAB 5: COMPLETED ───
  Widget _buildCompletedView(bool isMobile) {
    final filtered = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'completed';
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No completed trips found.');
    }

    return _buildPaginatedGrid(
      items: filtered,
      isMobile: isMobile,
      currentPage: _completedPage,
      onPageChanged: (p) => setState(() => _completedPage = p),
      itemBuilder: (trip) => _buildTripCard(
        trip,
        overrideStatus: 'Completed',
      ),
    );
  }

  // ─── REUSABLE: PAGINATED GRID/LIST ───
  Widget _buildPaginatedGrid({
    required List<dynamic> items,
    required bool isMobile,
    required int currentPage,
    required Function(int) onPageChanged,
    required Widget Function(dynamic) itemBuilder,
  }) {
    int totalPages = (items.length / _itemsPerPage).ceil();
    int startIdx = currentPage * _itemsPerPage;
    int endIdx = min(startIdx + _itemsPerPage, items.length);
    final pageItems = items.sublist(startIdx, endIdx);

    Widget grid = isMobile
        ? ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, i) => itemBuilder(pageItems[i]),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.4,
            ),
            itemCount: pageItems.length,
            itemBuilder: (_, i) => itemBuilder(pageItems[i]),
          );

    return Column(
      children: [
        grid,
        // Only show pagination controls if there are more items than one page
        if (items.length > _itemsPerPage)
          _buildPaginationControls(
            items.length,
            startIdx,
            endIdx,
            totalPages,
            currentPage,
            onPageChanged,
          ),
      ],
    );
  }

  // ─── REUSABLE UI FORMATTING HELPERS ───
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(
    dynamic trip, {
    String? overrideStatus,
    Widget? extraRow,
  }) {
    final status = (overrideStatus ?? trip['trip_status'] ?? 'Scheduled')
        .toString();
    final driverName =
        (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
    final vehiclePlate =
        (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';
    final departure = _formatTimeString(trip['departure_time']);
    final arrival = _formatTimeString(trip['estimated_arrival_time']);

    Color statusColor = Colors.orange.shade700;
    if (status.toLowerCase() == 'ongoing') {
      statusColor = Colors.green.shade700;
    } else if (status.toLowerCase() == 'scheduled') {
      statusColor = Colors.blue.shade700;
    } else if (status.toLowerCase() == 'completed') {
      statusColor = Colors.purple.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  'TRIP ID: ${trip['trip_id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _iconTextRow(
            Icons.access_time,
            "${trip['schedule_date']} | $departure - $arrival",
          ),
          const SizedBox(height: 4),
          _iconTextRow(
            Icons.location_on,
            trip['route_name'] ?? 'Unassigned Route',
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _iconTextRow(
                  Icons.airport_shuttle,
                  'Shuttle: $vehiclePlate | Driver: $driverName',
                ),
              ),
              extraRow ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  // Safely formats time strings to prevent crashes on unexpectedly short strings
  String _formatTimeString(dynamic timeVal) {
    if (timeVal == null || timeVal.toString().trim().isEmpty) return 'TBD';
    String t = timeVal.toString();
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }

  Widget _iconTextRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── REUSABLE: PAGINATION CONTROLS ───
  Widget _buildPaginationControls(
    int totalItems,
    int start,
    int end,
    int totalPages,
    int currentPage,
    Function(int) onPageChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${start + 1}–$end of $totalItems',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                child: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              Text(
                '${currentPage + 1} / $totalPages',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}