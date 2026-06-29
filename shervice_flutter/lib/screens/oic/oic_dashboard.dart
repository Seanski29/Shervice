import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // 5 tabs: pending, approved, dispatched, manage_trip, give_feedback
  String _currentPath = 'pending';

  // ─── FORM STATE ───
  String _passengerCount = '';
  int _rating = 5;
  String _comments = '';
  Map<String, dynamic>? _selectedTrip;

  // ─── DATA STATE ───
  bool _isLoading = true;
  List<dynamic> _allTrips = [];
  Set<int> _evaluatedTripIds = {};

  // ─── PAGINATION STATE (one per paginated tab) ───
  int _pendingPage = 0;
  int _approvedPage = 0;
  int _dispatchedPage = 0;
  int _feedbackPage = 0;
  final int _itemsPerPage = 4;

  // ─── BACKEND URL (adaptive per platform) ───
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveSchedules();
  }

  // ─── DATA FETCH: trips + already-evaluated IDs ───
  Future<void> _fetchLiveSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final tripsRes = await http.get(Uri.parse('$_backendUrl/trips'));
      final evalsRes =
          await http.get(Uri.parse('$_backendUrl/evaluations/mutual'));

      if (tripsRes.statusCode == 200 && evalsRes.statusCode == 200) {
        final tripsData = jsonDecode(tripsRes.body);
        final evalsData = jsonDecode(evalsRes.body);

        final List<dynamic> fetchedTrips = tripsData['trips'] ?? [];
        final List<dynamic> fetchedEvals = evalsData['evaluations'] ?? [];

        // Build set of trip IDs already evaluated by OIC
        final evaluatedIds = fetchedEvals
            .where((e) => e['evaluator_type'] == 'OIC')
            .map<int>(
                (e) => int.tryParse(e['trip_id'].toString()) ?? -1)
            .toSet();

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
          _evaluatedTripIds = evaluatedIds;
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
            Uri.parse('$_backendUrl/dispatch/submit'),
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

  // ─── EVALUATION SUBMIT ───
  Future<void> _submitOicEvaluation() async {
    if (_selectedTrip == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$_backendUrl/evaluations/mutual'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'trip_id': int.tryParse(
                      (_selectedTrip!['trip_id'] ?? _selectedTrip!['id'])
                          .toString()) ??
                  1,
              'oic_id': int.tryParse(widget.oicId) ?? 1,
              'overall_rating': _rating,
              'comments': _comments.trim(),
              'evaluator_type': 'OIC',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar('Evaluation successfully recorded!', Colors.purple);
        _resetFormState();
        await _fetchLiveSchedules();
      } else {
        _showSnackBar('Server error: ${res.statusCode}', Colors.red);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Evaluation transmission failure: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _resetFormState() {
    setState(() {
      _selectedTrip = null;
      _passengerCount = '';
      _comments = '';
      _rating = 5;
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
      String path, String label, IconData icon, Color activeColor) {
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
                Icon(icon,
                    size: 18,
                    color: isActive ? activeColor : Colors.grey.shade500),
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
                        horizontal: 12, vertical: 4),
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
                'OIC Dispatch Management | Monitor rotations, dispatch fleets, and evaluate service logs.',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                    _buildTabButton('pending', 'Pending',
                        Icons.hourglass_top, Colors.orange.shade700),
                    _buildTabButton('approved', 'Approved',
                        Icons.event_available, Colors.blue.shade700),
                    _buildTabButton('dispatched', 'Ongoing',
                        Icons.local_shipping, Colors.green.shade700),
                    _buildTabButton('manage_trip', 'Dispatch',
                        Icons.send, Colors.teal.shade700),
                    _buildTabButton('give_feedback', 'Feedback',
                        Icons.rate_review, Colors.purple.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tab Content ──
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(60.0),
                      child:
                          Center(child: CircularProgressIndicator()),
                    )
                  : _currentPath == 'pending'
                      ? _buildPendingView(isMobile)
                      : _currentPath == 'approved'
                          ? _buildApprovedView(isMobile)
                          : _currentPath == 'dispatched'
                              ? _buildDispatchedView(isMobile)
                              : _currentPath == 'manage_trip'
                                  ? _buildManageTripView(isMobile)
                                  : _buildFeedbackView(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // ─── REUSABLE TRIP CARD (Code 2 design) ───
  Widget _buildTripCard(dynamic trip,
      {Color statusColor = Colors.blue,
      String? overrideStatus,
      Widget? extraRow}) {
    final String status =
        overrideStatus ?? (trip['trip_status'] ?? 'Scheduled').toString();

    Color chipColor;
    Color chipTextColor;
    if (status.toLowerCase().contains('pending')) {
      chipColor = Colors.orange.shade50;
      chipTextColor = Colors.orange.shade800;
    } else if (status.toLowerCase() == 'scheduled') {
      chipColor = Colors.blue.shade50;
      chipTextColor = Colors.blue.shade700;
    } else if (status.toLowerCase() == 'ongoing') {
      chipColor = Colors.green.shade50;
      chipTextColor = Colors.green.shade700;
    } else {
      chipColor = Colors.grey.shade100;
      chipTextColor = Colors.grey.shade700;
    }

    final departure = _formatTimeString(trip['departure_time']);
    final arrival = _formatTimeString(trip['estimated_arrival_time']);
    final driverName =
        (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
    final vehiclePlate =
        (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRIP ID: ${trip['trip_id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: chipTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _iconTextRow(Icons.access_time,
              '${trip['schedule_date']} | $departure - $arrival'),
          const SizedBox(height: 4),
          _iconTextRow(
              Icons.location_on, trip['route_name'] ?? 'Unassigned Route'),
          const SizedBox(height: 4),
          _iconTextRow(Icons.airport_shuttle,
              'Shuttle: $vehiclePlate | Driver: $driverName'),
          if (extraRow != null) ...[
            const SizedBox(height: 4),
            extraRow,
          ],
        ],
      ),
    );
  }

  // ─── TAB 1: PENDING ───
  Widget _buildPendingView(bool isMobile) {
    final filtered = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'pending staff assignment';
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No trips currently pending staff assignment.');
    }

    return _buildPaginatedGrid(
      items: filtered,
      isMobile: isMobile,
      currentPage: _pendingPage,
      onPageChanged: (p) => setState(() => _pendingPage = p),
      itemBuilder: (trip) => _buildTripCard(trip,
          overrideStatus: 'Pending Staff Assignment'),
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

    return _buildPaginatedGrid(
      items: filtered,
      isMobile: isMobile,
      currentPage: _approvedPage,
      onPageChanged: (p) => setState(() => _approvedPage = p),
      itemBuilder: (trip) => _buildTripCard(trip, overrideStatus: 'Scheduled'),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

    Widget tripSelectionList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Scheduled Trip to Dispatch',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (scheduledTrips.isEmpty)
          Text('No scheduled trips available to dispatch.',
              style: TextStyle(color: Colors.grey.shade500))
        else
          ...scheduledTrips.map((trip) {
            final tripId = trip['trip_id'];
            final isSelected = _selectedTrip?['trip_id'] == tripId;
            final driverName =
                (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final departure = _formatTimeString(trip['departure_time']);

            return GestureDetector(
              onTap: () => setState(() => _selectedTrip = trip),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.teal.shade500
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRIP ID: $tripId | $departure',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${trip['route_name'] ?? 'No Route'} | Driver: $driverName',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );

    Widget actionPanel = _selectedTrip == null
        ? Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Text(
              'Select a trip from the list to configure headcount.',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Dispatch — Trip #${_selectedTrip!['trip_id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  _selectedTrip!['route_name'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Text('PASSENGER HEADCOUNT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _passengerCount = val,
                  decoration: InputDecoration(
                    hintText: 'Enter total passengers onboard',
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _dispatchTripWithHeadcount,
                    child: const Text('Dispatch Trip',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tripSelectionList,
          const SizedBox(height: 32),
          actionPanel,
        ],
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

  // ─── TAB 5: FEEDBACK ───
  Widget _buildFeedbackView(bool isMobile) {
    final unevaluated = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      final tripId =
          int.tryParse(t['trip_id'].toString()) ?? -1;
      return status == 'completed' &&
          !_evaluatedTripIds.contains(tripId);
    }).toList();

    Widget tripSelectionList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Completed Trip for Evaluation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (unevaluated.isEmpty)
          Text(
            'All completed routes have been evaluated!',
            style: TextStyle(
                color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          )
        else
          Builder(builder: (context) {
            int totalPages =
                (unevaluated.length / _itemsPerPage).ceil();
            int startIdx = _feedbackPage * _itemsPerPage;
            int endIdx = min(startIdx + _itemsPerPage, unevaluated.length);
            final pageItems = unevaluated.sublist(startIdx, endIdx);

            return Column(
              children: [
                ...pageItems.map((trip) {
                  final tripId = trip['trip_id'];
                  final isSelected = _selectedTrip?['trip_id'] == tripId;
                  final driverName =
                      (trip['user_account'] ?? {})['full_name'] ??
                          'Unassigned';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTrip = trip),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.purple.shade500
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TRIP ID: $tripId',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                'Driver: $driverName | ${trip['route_name'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Icon(Icons.stars,
                              size: 18,
                              color: isSelected
                                  ? Colors.purple
                                  : Colors.grey.shade400),
                        ],
                      ),
                    ),
                  );
                }),
                _buildPaginationControls(
                  unevaluated.length,
                  startIdx,
                  endIdx,
                  totalPages,
                  _feedbackPage,
                  (p) => setState(() => _feedbackPage = p),
                ),
              ],
            );
          }),
      ],
    );

    Widget actionPanel = _selectedTrip == null
        ? Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Text(
              'Select a completed trip to open the evaluation form.',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluate Trip #${_selectedTrip!['trip_id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                Text('PERFORMANCE RATING',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _rating,
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 5,
                        child: Text('⭐⭐⭐⭐⭐  5 — Excellent')),
                    DropdownMenuItem(
                        value: 4, child: Text('⭐⭐⭐⭐  4 — Good')),
                    DropdownMenuItem(
                        value: 3, child: Text('⭐⭐⭐  3 — Average')),
                    DropdownMenuItem(
                        value: 1, child: Text('⭐  1 — Poor')),
                  ],
                  onChanged: (val) => setState(() => _rating = val!),
                ),
                const SizedBox(height: 20),
                Text('COMMENTS & REMARKS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  onChanged: (val) => _comments = val,
                  decoration: InputDecoration(
                    hintText:
                        'Log service quality, driver compliance, or incident notes...',
                    fillColor: const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _submitOicEvaluation,
                    child: const Text('Submit Evaluation',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tripSelectionList,
          const SizedBox(height: 32),
          actionPanel,
        ],
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
            separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  // ─── REUSABLE: EMPTY STATE ───
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(
          message,
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─── REUSABLE: ICON + TEXT ROW ───
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
              overflow: TextOverflow.ellipsis,
            ),
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
              Text('${currentPage + 1} / $totalPages',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ─── REUSABLE: TIME FORMATTER ───
  String _formatTimeString(dynamic timeVal) {
    if (timeVal == null || timeVal.toString().trim().isEmpty) return 'TBD';
    final t = timeVal.toString();
    return t.length >= 5 ? t.substring(0, 5) : t;
  }
}