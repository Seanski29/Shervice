import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';

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
  String _currentPath = 'pending'; 
  int _rating = 5;
  String _comments = '';
  Map<String, dynamic>? _selectedTrip;
  
  bool _isLoading = true;
  List<dynamic> _allTrips = [];
  Set<int> _evaluatedTripIds = {}; 

  // ─── FOUR-WAY SEPARATED PAGINATION INDICES ───
  int _pendingPage = 0;
  int _approvedPage = 0;
  int _dispatchedPage = 0;
  int _feedbackPage = 0;
  final int _itemsPerPage = 4;
  
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveSchedules();
  }

  Future<void> _fetchLiveSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final tripsRes = await http.get(Uri.parse('$_backendUrl/trips'));
      final evalsRes = await http.get(Uri.parse('$_backendUrl/evaluations/mutual'));
      
      if (tripsRes.statusCode == 200 && evalsRes.statusCode == 200) {
        final tripsData = jsonDecode(tripsRes.body);
        final evalsData = jsonDecode(evalsRes.body);
        
        final List<dynamic> fetchedTrips = tripsData['trips'] ?? [];
        final List<dynamic> fetchedEvals = evalsData['evaluations'] ?? [];

        final evaluatedIds = fetchedEvals
            .where((e) => e['evaluator_type'] == 'OIC')
            .map<int>((e) => int.tryParse(e['trip_id'].toString()) ?? -1)
            .toSet();

        final matchingTrips = fetchedTrips.where((t) {
          final dbOicId = t['oic_id']?.toString() ?? '';
          final targetOicId = widget.oicId.toString().trim();
          
          if (dbOicId == targetOicId) return true;
          
          final dbCompanyName = (t['oic_profile'] ?? {})['company_name']?.toString().toLowerCase().trim();
          final targetCompanyName = widget.companyName.toLowerCase().trim();
          return dbCompanyName == targetCompanyName;
        }).toList();
        
        setState(() {
          _allTrips = matchingTrips;
          _evaluatedTripIds = evaluatedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ OIC Schedule Sync Error: $e");
      _showSnackBar("Failed to sync latest trip schedules.", Colors.red);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOicEvaluation() async {
    if (_selectedTrip == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_backendUrl/evaluations/mutual'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trip_id': int.tryParse((_selectedTrip!['trip_id'] ?? _selectedTrip!['id']).toString()) ?? 1,
          'oic_id': int.tryParse(widget.oicId) ?? 1,
          'overall_rating': _rating, 
          'comments': _comments.trim(),
          'evaluator_type': 'OIC',
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar("Evaluation successfully recorded!", Colors.purple);
        _resetFormState();
        await _fetchLiveSchedules(); 
      } else {
        _showSnackBar("Server error: ${res.statusCode}", Colors.red);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar("Evaluation transmission network failure: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _resetFormState() {
    setState(() {
      _selectedTrip = null;
      _comments = '';
      _rating = 5;
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildTabButton(String path, String label, IconData icon, Color activeColor) {
    final isActive = _currentPath == path;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _currentPath = path;
          _selectedTrip = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: isActive ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? activeColor : Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? activeColor : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchLiveSchedules,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Welcome, ${widget.oicName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade200)),
                    child: Text(widget.companyName, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('OIC Dispatch Management | Monitor upcoming rotations, dispatch fleets, and evaluate service logs.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildTabButton('pending', 'Pending', Icons.hourglass_top, Colors.orange.shade700),
                    _buildTabButton('approved', 'Approved', Icons.event_available, Colors.blue.shade700),
                    _buildTabButton('dispatched', 'Ongoing', Icons.local_shipping, Colors.green.shade700),
                    _buildTabButton('give_feedback', 'Feedback', Icons.rate_review, Colors.purple.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _isLoading 
                  ? const Padding(padding: EdgeInsets.all(60.0), child: Center(child: CircularProgressIndicator()))
                  : _currentPath == 'pending' 
                      ? _buildPendingView()
                      : _currentPath == 'approved'
                          ? _buildApprovedView()
                          : _currentPath == 'dispatched' 
                              ? _buildDispatchedView() 
                              : _buildFeedbackView(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: PENDING VIEW (Pending Staff Assignment) ───
  Widget _buildPendingView() {
    final pendingTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'pending staff assignment';
    }).toList();

    if (pendingTrips.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("No trips currently pending staff assignment layouts.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))));
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
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
          ),
          itemCount: activePageList.length,
          itemBuilder: (context, index) {
            final trip = activePageList[index];
            final driverName = (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final vehiclePlate = (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';

            final departure = _formatTimeString(trip['departure_time']);
            final arrival = _formatTimeString(trip['estimated_arrival_time']);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TRIP ID: ${trip['trip_id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text("PENDING ASSIGNMENT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconTextRow(Icons.access_time, "${trip['schedule_date']} | $departure - $arrival"),
                  const SizedBox(height: 4),
                  _iconTextRow(Icons.location_on, trip['route_name'] ?? 'Unassigned Route'),
                  const SizedBox(height: 4),
                  _iconTextRow(Icons.airport_shuttle, "Shuttle: $vehiclePlate | Driver: $driverName"),
                ],
              ),
            );
          },
        ),
        _buildPaginationControls(pendingTrips.length, startIdx, endIdx, totalPages, _pendingPage, (newPage) {
          setState(() => _pendingPage = newPage);
        }),
      ],
    );
  }

  // ─── TAB 2: APPROVED VIEW (Scheduled) ───
  Widget _buildApprovedView() {
    final approvedTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'scheduled';
    }).toList();

    if (approvedTrips.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("No upcoming approved scheduled runs found.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))));
    }

    int totalPages = (approvedTrips.length / _itemsPerPage).ceil();
    int startIdx = _approvedPage * _itemsPerPage;
    int endIdx = min(startIdx + _itemsPerPage, approvedTrips.length);
    List<dynamic> activePageList = approvedTrips.sublist(startIdx, endIdx);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
          ),
          itemCount: activePageList.length,
          itemBuilder: (context, index) {
            final trip = activePageList[index];
            final driverName = (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final vehiclePlate = (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';

            final departure = _formatTimeString(trip['departure_time']);
            final arrival = _formatTimeString(trip['estimated_arrival_time']);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TRIP ID: ${trip['trip_id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text("SCHEDULED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconTextRow(Icons.access_time, "${trip['schedule_date']} | $departure - $arrival"),
                  const SizedBox(height: 4),
                  _iconTextRow(Icons.location_on, trip['route_name'] ?? 'Unassigned Route'),
                  const SizedBox(height: 4),
                  _iconTextRow(Icons.airport_shuttle, "Shuttle: $vehiclePlate | Driver: $driverName"),
                ],
              ),
            );
          },
        ),
        _buildPaginationControls(approvedTrips.length, startIdx, endIdx, totalPages, _approvedPage, (newPage) {
          setState(() => _approvedPage = newPage);
        }),
      ],
    );
  }

  // ─── TAB 3: ONGOING DISPATCHED VIEW (Read-Only) ───
  Widget _buildDispatchedView() {
    final ongoingTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      return status == 'ongoing';
    }).toList();

    if (ongoingTrips.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("No ongoing departures actively operating in routing rotation.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))));
    }

    int totalPages = (ongoingTrips.length / _itemsPerPage).ceil();
    int startIdx = _dispatchedPage * _itemsPerPage;
    int endIdx = min(startIdx + _itemsPerPage, ongoingTrips.length);
    List<dynamic> activePageList = ongoingTrips.sublist(startIdx, endIdx);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Ongoing Transits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
          ),
          itemCount: activePageList.length,
          itemBuilder: (context, index) {
            final trip = activePageList[index];
            final driverName = (trip['user_account'] ?? {})['full_name'] ?? 'Unassigned';
            final vehiclePlate = (trip['vehicle'] ?? {})['plate_number'] ?? 'No Shuttle Linked';
            final passengerCount = trip['passenger_count'] ?? 0;

            final departure = _formatTimeString(trip['departure_time']);
            final arrival = _formatTimeString(trip['estimated_arrival_time']);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TRIP ID: ${trip['trip_id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text("ONGOING", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _iconTextRow(Icons.access_time, "${trip['schedule_date']} | $departure - $arrival"),
                  const SizedBox(height: 4),
                  _iconTextRow(Icons.location_on, trip['route_name'] ?? 'Unassigned Route'),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _iconTextRow(Icons.airport_shuttle, "Shuttle: $vehiclePlate | Driver: $driverName")),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text("👥 $passengerCount Passengers", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        _buildPaginationControls(ongoingTrips.length, startIdx, endIdx, totalPages, _dispatchedPage, (newPage) {
          setState(() => _dispatchedPage = newPage);
        }),
      ],
    );
  }

  // ─── TAB 4: COMPLETED TRIP EVALUATIONS VIEW (Excludes evaluated IDs) ───
  Widget _buildFeedbackView() {
    final uncompletedTrips = _allTrips.where((t) {
      final status = (t['trip_status'] ?? '').toString().toLowerCase().trim();
      final currentTripId = int.tryParse(t['trip_id'].toString()) ?? -1;
      return status == 'completed' && !_evaluatedTripIds.contains(currentTripId);
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Completed Trip for Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              if (uncompletedTrips.isEmpty)
                Text("All completed routes evaluated! No pending logs remaining.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500))
              else ...[
                Builder(
                  builder: (context) {
                    int totalPages = (uncompletedTrips.length / _itemsPerPage).ceil();
                    int startIdx = _feedbackPage * _itemsPerPage;
                    int endIdx = min(startIdx + _itemsPerPage, uncompletedTrips.length);
                    List<dynamic> activePageList = uncompletedTrips.sublist(startIdx, endIdx);

                    return Column(
                      children: [
                        ...activePageList.map((trip) {
                          final tripId = trip['trip_id'];
                          final isSelected = _selectedTrip?['trip_id'] == tripId;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTrip = trip),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.purple.shade50 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? Colors.purple.shade500 : Colors.grey.shade300, width: 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('TRIP ID: $tripId', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Icon(Icons.stars, size: 16, color: isSelected ? Colors.purple : Colors.grey),
                                    ],
                                  ),
                                  Text('Route: ${trip['route_name']} | Driver: ${(trip['user_account'] ?? {})['full_name'] ?? 'Unassigned'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          );
                        }),
                        _buildPaginationControls(uncompletedTrips.length, startIdx, endIdx, totalPages, _feedbackPage, (newPage) {
                          setState(() => _feedbackPage = newPage);
                        }),
                      ],
                    );
                  }
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _selectedTrip == null
              ? Center(child: Text("Select an un-evaluated route row to open your feedback fields.", style: TextStyle(color: Colors.grey.shade500)))
              : Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evaluate Trip #${_selectedTrip!['trip_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      const SizedBox(height: 24),
                      Text('PERFORMANCE RATING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _rating,
                        decoration: InputDecoration(fillColor: const Color(0xFFF1F5F9), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('⭐⭐⭐⭐⭐  5 - Excellent')),
                          DropdownMenuItem(value: 4, child: Text('⭐⭐⭐⭐  4 - Good')),
                          DropdownMenuItem(value: 3, child: Text('⭐⭐⭐  3 - Average')),
                          DropdownMenuItem(value: 1, child: Text('⭐  1 - Poor')),
                        ],
                        onChanged: (val) => setState(() => _rating = val!),
                      ),
                      const SizedBox(height: 20),
                      Text('COMMENTS & REMARKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 4,
                        onChanged: (val) => _comments = val,
                        decoration: InputDecoration(hintText: 'Log service quality metrics, driver compliance notes, or contract feedback...', fillColor: const Color(0xFFF1F5F9), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                          onPressed: _submitOicEvaluation,
                          child: const Text('Submit Evaluation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ─── REUSABLE UI FORMATTING HELPERS ───
  
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
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis))),
      ],
    );
  }

  Widget _buildPaginationControls(int totalItems, int start, int end, int totalPages, int currentPage, Function(int) onPageChanged) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing ${start + 1} - $end of $totalItems items', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Row(
            children: [
              OutlinedButton(
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                child: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              Text('${currentPage + 1} / $totalPages', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
                child: const Text('Next'),
              ),
            ],
          )
        ],
      ),
    );
  }
}