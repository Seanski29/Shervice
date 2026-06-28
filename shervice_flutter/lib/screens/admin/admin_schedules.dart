import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminSchedules extends StatefulWidget {
  const AdminSchedules({super.key});

  @override
  State<AdminSchedules> createState() => _AdminSchedulesState();
}

class _AdminSchedulesState extends State<AdminSchedules> {
  // --- Network Routing Targeting Flask Admin Blueprint ---
  String get _backendFetchUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/trips';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/trips'
        : 'http://127.0.0.1:5000/api/trips';
  }

  // --- State Variables ---
  bool _isLoading = true;
  List<dynamic> _allSchedules = [];
  List<dynamic> _filteredSchedules = [];

  // Filtering & Sorting
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Scheduled', 'In Progress', 'Completed', 'Cancelled'];

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchSchedulesFromDatabase();
  }

  // --- Data Fetching & Processing ---
  Future<void> _fetchSchedulesFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse(_backendFetchUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handling both raw arrays or enveloped JSON responses
        if (data is List) {
          _allSchedules = data;
        } else if (data is Map && data.containsKey('trips')) {
          _allSchedules = data['trips'] ?? [];
        } else if (data is Map && data.containsKey('sample_data_payload')) {
          _allSchedules = data['sample_data_payload'] ?? [];
        } else {
          _allSchedules = [];
        }
      } else {
        debugPrint("⚠️ Server returned non-200 status code: ${response.statusCode}");
        _allSchedules = [];
      }
    } catch (e) {
      debugPrint("❌ Error reading live trip schedule streams: $e");
      _allSchedules = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  void _applyFiltersAndSort() {
    // 1. Filter by Route Name/Driver Name and Status Dropdown
    List<dynamic> temp = _allSchedules.where((trip) {
      final routeName = (trip['route_name'] ?? '').toString().toLowerCase();
      final driverName = (trip['driver_name'] ?? '').toString().toLowerCase();
      final tripStatus = (trip['status'] ?? 'Scheduled').toString();

      final matchesSearch = routeName.contains(_searchQuery.toLowerCase()) || 
                            driverName.contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || 
                            tripStatus.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    // 2. Sort chronologically by schedule time
    temp.sort((a, b) {
      final timeA = DateTime.tryParse(a['scheduled_time']?.toString() ?? '') ?? DateTime.now();
      final timeB = DateTime.tryParse(b['scheduled_time']?.toString() ?? '') ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    setState(() {
      _filteredSchedules = temp;
      _currentPage = 0; // Reset page on filter mutation
      _isLoading = false;
    });
  }

  // --- Pagination Logic ---
  int get _totalPages => (_filteredSchedules.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedSchedules {
    if (_filteredSchedules.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredSchedules.length);
    return _filteredSchedules.sublist(start, end);
  }

  void _nextPage() => setState(() => _currentPage < _totalPages - 1 ? _currentPage++ : null);
  void _prevPage() => setState(() => _currentPage > 0 ? _currentPage-- : null);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.orange;
    }
  }

  // --- UI Layout Engine ---
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Components
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trip Schedules',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              IconButton(
                onPressed: _fetchSchedulesFromDatabase,
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'Refresh Schedules',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Control and Filtering Ribbon
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFiltersAndSort();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search routes or drivers...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    icon: const Icon(Icons.filter_alt_outlined),
                    items: _statusOptions.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _statusFilter = newValue;
                          _applyFiltersAndSort();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Core Stream Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSchedules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No scheduled trips found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _paginatedSchedules.length,
                        itemBuilder: (context, index) {
                          final trip = _paginatedSchedules[index];
                          return _buildTripCard(
                            routeName: trip['route_name'] ?? 'Unassigned Route',
                            driverName: trip['driver_name'] ?? 'No Assigned Driver',
                            vehiclePlate: trip['plate_number'] ?? 'No Shuttle Linked',
                            timeString: trip['scheduled_time'] ?? 'TBD',
                            status: trip['status'] ?? 'Scheduled',
                          );
                        },
                      ),
          ),

          // Pagination System Footnotes
                   if (!_isLoading && _filteredSchedules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredSchedules.length)} of ${_filteredSchedules.length} schedules',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _currentPage > 0 ? _prevPage : null,
                          child: const Text('Previous'),
                        ),
                        const SizedBox(width: 8),
                        Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard({
    required String routeName,
    required String driverName,
    required String vehiclePlate,
    required String timeString,
    required String status,
  }) {
    final statusColor = _getStatusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              Text(routeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _cardIconText(Icons.person_outline, 'Driver: $driverName'),
              _cardIconText(Icons.airport_shuttle_outlined, 'Shuttle: $vehiclePlate'),
              _cardIconText(Icons.access_time, 'Departure: $timeString'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155))),
      ],
    );
  }
}