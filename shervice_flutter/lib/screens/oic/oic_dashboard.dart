import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';

class OicDashboard extends StatefulWidget {
  final String oicName;
  final String companyName;
  final String oicId; // 👈 REQUIRED FOR PERSONALIZED FLEET ROUTING

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
  String _currentPath = 'view_status';
  String _passengerCount = '';
  int _rating = 5;
  String _comments = '';
  Map<String, dynamic>? _selectedTrip;
  
  bool _isLoading = true;
  List<dynamic> _trips = [];
  
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveSchedules();
  }

  // ─── ALIGNED ACTION: IDENTICAL DATA ENGINE FETCH ───
  Future<void> _fetchLiveSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final res = await http.get(
        Uri.parse('$_backendUrl/schedules/oic/${widget.oicId}'),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _trips = data['data'] ?? []; // Maps cleanly against data root arrays
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ OIC Schedule Sync Error: $e");
      _showSnackBar("Failed to sync latest trip schedules.", Colors.red);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dispatchTripWithHeadcount() async {
    if (_selectedTrip == null || _passengerCount.trim().isEmpty) {
      _showSnackBar("Please enter a valid passenger headcount.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_backendUrl/dispatch/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trip_id': _selectedTrip!['trip_id'] ?? _selectedTrip!['id'],
          'passenger_count': int.tryParse(_passengerCount) ?? 0,
          'company_name': widget.companyName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar("Trip successfully dispatched!", Colors.green);
        _resetFormState();
        _fetchLiveSchedules();
      }
    } catch (e) {
      _showSnackBar("Dispatch pipeline transmission failure.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOicEvaluation() async {
    if (_selectedTrip == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_backendUrl/evaluations/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trip_id': _selectedTrip!['trip_id'] ?? _selectedTrip!['id'],
          'score': _rating,
          'comments': _comments.trim(),
          'evaluated_by': widget.oicName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar("Evaluation successfully recorded!", Colors.purple);
        _resetFormState();
        _fetchLiveSchedules();
      }
    } catch (e) {
      _showSnackBar("Evaluation transmission failure.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFormState() {
    setState(() {
      _currentPath = 'view_status';
      _selectedTrip = null;
      _passengerCount = '';
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
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? activeColor : Colors.grey.shade500)),
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
      body: SingleChildScrollView(
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
            Text('OIC Dispatch Management | Manage trip departures, passenger logs, and driver evaluations.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _buildTabButton('view_status', 'Schedules', Icons.calendar_month, Colors.blue.shade600),
                  _buildTabButton('manage_trip', 'Dispatch', Icons.send, Colors.green.shade600),
                  _buildTabButton('give_feedback', 'Feedback', Icons.feedback, Colors.purple.shade600),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _isLoading 
                ? const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator()))
                : _currentPath == 'view_status' 
                    ? _buildSchedulesView()
                    : _currentPath == 'manage_trip' 
                        ? _buildDispatchView() 
                        : _buildFeedbackView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesView() {
    if (_trips.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("No trips scheduled for your fleet records.", style: TextStyle(color: Colors.grey.shade600))));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.2,
      ),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        final String status = trip['status'] ?? 'Scheduled';
        final isScheduled = status == 'Scheduled';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text((trip['trip_id'] ?? trip['id'] ?? 'TBD').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isScheduled ? Colors.blue.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isScheduled ? Colors.blue.shade700 : Colors.orange.shade700)),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(trip['schedule_time'] ?? trip['time'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(trip['route_name'] ?? trip['route'] ?? 'Route Unassigned', style: TextStyle(color: Colors.grey.shade700, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Driver: ${trip['driver_name'] ?? trip['driver'] ?? 'Unassigned'}', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDispatchView() {
    final scheduledTrips = _trips.where((t) => (t['status'] ?? 'Scheduled') == 'Scheduled').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Scheduled Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              if (scheduledTrips.isEmpty)
                Text("No pending scheduled departures.", style: TextStyle(color: Colors.grey.shade500))
              else
                ...scheduledTrips.map((trip) {
                  final tripId = trip['trip_id'] ?? trip['id'];
                  final isSelected = _selectedTrip?['trip_id'] == tripId || _selectedTrip?['id'] == tripId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTrip = trip),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.green.shade500 : Colors.grey.shade300, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$tripId - ${trip['schedule_time'] ?? trip['time']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${trip['route_name'] ?? trip['route']} | Driver: ${trip['driver_name'] ?? trip['driver']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _selectedTrip == null
              ? Center(child: Text("Select a trip row from the list to prompt headcount configuration.", style: TextStyle(color: Colors.grey.shade500)))
              : Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Confirm Passenger Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Dispatching ${_selectedTrip!['trip_id'] ?? _selectedTrip!['id']}', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 24),
                      Text('HEADCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _passengerCount = val,
                        decoration: InputDecoration(hintText: '0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: _dispatchTripWithHeadcount,
                          child: const Text('Dispatch Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFeedbackView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Trip for Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              if (_trips.isEmpty)
                Text("No system records found to evaluate.", style: TextStyle(color: Colors.grey.shade500))
              else
                ..._trips.map((trip) {
                  final tripId = trip['trip_id'] ?? trip['id'];
                  final isSelected = _selectedTrip?['trip_id'] == tripId || _selectedTrip?['id'] == tripId;
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
                          Text('$tripId', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Driver: ${trip['driver_name'] ?? trip['driver'] ?? 'Unknown'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _selectedTrip == null
              ? Center(child: Text("Select a trip from the registry index to open feedback fields.", style: TextStyle(color: Colors.grey.shade500)))
              : Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OIC Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 24),
                      Text('PERFORMANCE RATING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _rating,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5 - Excellent')),
                          DropdownMenuItem(value: 4, child: Text('4 - Good')),
                          DropdownMenuItem(value: 3, child: Text('3 - Average')),
                          DropdownMenuItem(value: 1, child: Text('1 - Poor')),
                        ],
                        onChanged: (val) => setState(() => _rating = val!),
                      ),
                      const SizedBox(height: 16),
                      Text('COMMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 4,
                        onChanged: (val) => _comments = val,
                        decoration: InputDecoration(hintText: 'Log incident details or praise...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, padding: const EdgeInsets.symmetric(vertical: 16)),
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
}