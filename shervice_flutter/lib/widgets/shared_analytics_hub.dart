import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';
// Adjust this import path if your file is located elsewhere!
import '../../widgets/driver_evaluation_view.dart';

class SharedAnalyticsHub extends StatefulWidget {
  const SharedAnalyticsHub({super.key});

  @override
  State<SharedAnalyticsHub> createState() => _SharedAnalyticsHubState();
}

class _SharedAnalyticsHubState extends State<SharedAnalyticsHub> {
  // 0 = Driver Performance, 1 = Vehicle ML Prediction
  int _activeTab = 0;

  bool _isLoading = true;
  List<dynamic> _allDrivers = [];
  List<dynamic> _filteredDrivers = [];

  List<dynamic> _allVehicles = [];
  List<dynamic> _filteredVehicles = [];

  // Search, Filter & Pagination
  String _searchQuery = '';
  String _currentSort = 'A to Z';

  // 👇 FIX: Added "Excellent" to the Vehicle dropdown option
  List<String> get _currentSortOptions {
    return _activeTab == 0
        ? ['A to Z', 'Z to A', 'Rating (High-Low)', 'Rating (Low-High)']
        : [
            'A to Z',
            'Z to A',
            'Condition: Good/Excellent',
            'Condition: Needs Maint.',
          ];
  }

  int _currentPage = 0;
  final int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Fetch Drivers (Using test-db which aggregates ratings)
      final dRes = await http.get(Uri.parse('$backendUrl/test-db'));
      if (dRes.statusCode == 200) {
        final dData = jsonDecode(dRes.body);
        _allDrivers = dData['sample_data_payload'] ?? [];
      }

      // 2. Fetch Vehicles
      final vRes = await http.get(Uri.parse('$backendUrl/vehicles'));
      if (vRes.statusCode == 200) {
        final vData = jsonDecode(vRes.body);
        _allVehicles = vData['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Analytics Fetch Error: $e");
    } finally {
      if (mounted) {
        _applyFilters();
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    // ─── FILTER & SORT DRIVERS ───
    List<dynamic> tempD = _allDrivers.where((d) {
      final name = (d['full_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    tempD.sort((a, b) {
      if (_currentSort == 'Rating (High-Low)') {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rB.compareTo(rA); // Highest first
      } else if (_currentSort == 'Rating (Low-High)') {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rA.compareTo(rB); // Lowest first
      } else {
        final nameA = (a['full_name'] ?? '').toString().toLowerCase();
        final nameB = (b['full_name'] ?? '').toString().toLowerCase();
        return _currentSort == 'Z to A'
            ? nameB.compareTo(nameA)
            : nameA.compareTo(nameB);
      }
    });

    // ─── FILTER & SORT VEHICLES ───
    List<dynamic> tempV = _allVehicles.where((v) {
      final plate = (v['plate_number'] ?? '').toString().toLowerCase();
      final type = (v['bus_type'] ?? '').toString().toLowerCase();
      final status = (v['health_status'] ?? 'Good').toString().toLowerCase();

      bool matchesSearch =
          plate.contains(_searchQuery.toLowerCase()) ||
          type.contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;

      // 👇 FIX: Logic properly groups both 'good' and 'excellent'
      if (_currentSort == 'Condition: Good/Excellent') {
        matchesFilter = status == 'good' || status == 'excellent';
      } else if (_currentSort == 'Condition: Needs Maint.') {
        matchesFilter = status != 'good' && status != 'excellent';
      }

      return matchesSearch && matchesFilter;
    }).toList();

    tempV.sort((a, b) {
      final plateA = (a['plate_number'] ?? '').toString().toLowerCase();
      final plateB = (b['plate_number'] ?? '').toString().toLowerCase();
      return _currentSort == 'Z to A'
          ? plateB.compareTo(plateA)
          : plateA.compareTo(plateB);
    });

    setState(() {
      _filteredDrivers = tempD;
      _filteredVehicles = tempV;
      _currentPage = 0;
    });
  }

  int get _totalPages {
    final list = _activeTab == 0 ? _filteredDrivers : _filteredVehicles;
    return (list.length / _itemsPerPage).ceil();
  }

  List<dynamic> get _paginatedItems {
    final list = _activeTab == 0 ? _filteredDrivers : _filteredVehicles;
    if (list.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, list.length);
    return list.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final double padding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Evaluate driver performance scores and execute predictive maintenance algorithms.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── TOGGLE BUTTONS ──
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          0,
                          'Driver Performance',
                          Icons.person,
                        ),
                        _buildToggleButton(
                          1,
                          'Vehicle Predictive ML',
                          Icons.memory,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SEARCH & SORT BAR ──
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 350,
                          minWidth: isMobile ? double.infinity : 200,
                        ),
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            onChanged: (value) {
                              _searchQuery = value;
                              _applyFilters();
                            },
                            decoration: InputDecoration(
                              hintText: _activeTab == 0
                                  ? 'Search drivers...'
                                  : 'Search vehicles...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 230,
                          minWidth: isMobile ? double.infinity : 150,
                        ),
                        child: SizedBox(
                          height: 42,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _currentSort,
                                icon: const Icon(
                                  Icons.sort,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                items: _currentSortOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _currentSort = val;
                                    _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── LIST CONTENT ──
                  Expanded(
                    child: _paginatedItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _activeTab == 0
                                      ? Icons.group_off
                                      : Icons.car_crash,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No records found matching your filter.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _paginatedItems.length,
                            itemBuilder: (context, index) {
                              final item = _paginatedItems[index];
                              return _activeTab == 0
                                  ? _buildDriverCard(item)
                                  : _buildVehicleCard(item);
                            },
                          ),
                  ),

                  // ── PAGINATION ──
                  if (_totalPages > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _activeTab == 0 ? _filteredDrivers.length : _filteredVehicles.length)} of ${_activeTab == 0 ? _filteredDrivers.length : _filteredVehicles.length} records',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_currentPage + 1} / $_totalPages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B82F6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < _totalPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleButton(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
            _searchQuery = ''; // Reset search query string
            _currentSort =
                'A to Z'; // Safely reset sort to default when switching tabs
            _applyFilters();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isActive
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DRIVER CARD ───
  Widget _buildDriverCard(dynamic driver) {
    final double rating = (driver['rating'] as num?)?.toDouble() ?? 0.0;
    final String status = driver['employment_status'] ?? 'Active';
    final Color statusColor = status.toLowerCase() == 'active'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDriverEvalModal(driver['user_id']),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating == 0.0 ? 'New' : rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver['license_no'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ─── VEHICLE CARD ───
  Widget _buildVehicleCard(dynamic vehicle) {
    final String status = vehicle['health_status'] ?? 'Good';

    // 👇 FIX: Color badge turns Green for both 'Good' AND 'Excellent'
    final Color statusColor =
        (status.toLowerCase() == 'good' || status.toLowerCase() == 'excellent')
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMlPredictionModal(vehicle),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['plate_number'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle['bus_type'] ?? 'Unknown Type',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.memory, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MODAL LAUNCHERS ───
  void _showDriverEvalModal(String driverId) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: isMobile ? double.infinity : 600,
          height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DriverEvaluationView(
                    driverUuid: driverId,
                    backendUrl: backendUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMlPredictionModal(dynamic vehicle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          MlPredictionDialog(vehicle: vehicle, backendUrl: backendUrl),
    );
  }
}

// ─── DEDICATED ML PREDICTION DIALOG ───
class MlPredictionDialog extends StatefulWidget {
  final dynamic vehicle;
  final String backendUrl;

  const MlPredictionDialog({
    super.key,
    required this.vehicle,
    required this.backendUrl,
  });

  @override
  State<MlPredictionDialog> createState() => _MlPredictionDialogState();
}

class _MlPredictionDialogState extends State<MlPredictionDialog> {
  bool _isRunning = true;
  Map<String, dynamic>? _results;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              '${widget.backendUrl}/vehicles/predict/${widget.vehicle['vehicle_id']}',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _results = jsonDecode(res.body);
          _isRunning = false;
        });
      } else {
        if (mounted)
          setState(() {
            _error =
                "Failed to run diagnostics. Server returned ${res.statusCode}.";
            _isRunning = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = "Connection error. Ensure Python backend is running.";
          _isRunning = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? double.infinity : 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ML Diagnostics: ${widget.vehicle['plate_number']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_isRunning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.purple),
                      SizedBox(height: 16),
                      Text(
                        "Compiling Logistic Regression Model...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildResultsView(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(bool isMobile) {
    final double riskIndex = (_results!['risk_index'] ?? 0.0) * 100;
    final Map<String, dynamic> telemetry = _results!['telemetry_metrics'] ?? {};

    // Apply the 80% business logic threshold
    final bool isLockout = riskIndex >= 80.0;
    final bool isWarning = riskIndex >= 50.0 && riskIndex < 80.0;

    Color statusColor;
    Color bgColor;
    String statusLabel;
    String statusDesc;

    if (isLockout) {
      statusColor = const Color(0xFFEF4444); // Red
      bgColor = const Color(0xFFFEF2F2);
      statusLabel = 'CLASS 1: CRITICAL RISK';
      statusDesc =
          'Algorithm dictates an imminent breakdown risk. Asset lockout triggered.';
    } else if (isWarning) {
      statusColor = const Color(0xFFF59E0B); // Orange
      bgColor = const Color(0xFFFFFBEB);
      statusLabel = 'WARNING: ELEVATED RISK';
      statusDesc =
          'Asset is operational, but structural wear is increasing. Monitor closely.';
    } else {
      statusColor = const Color(0xFF10B981); // Green
      bgColor = const Color(0xFFECFDF5);
      statusLabel = 'CLASS 0: SAFE';
      statusDesc =
          'Baseline structural integrity is normal. Asset is cleared for operations.';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                'LOGISTIC REGRESSION CLASSIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = isMobile
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatCard(
                  'Risk Prob.',
                  '${riskIndex.toStringAsFixed(1)}%',
                  Icons.analytics,
                  statusColor,
                  cardWidth,
                ),
                _buildStatCard(
                  'Odometer',
                  '${telemetry['total_mileage_km']} km',
                  Icons.speed,
                  const Color(0xFF3B82F6),
                  cardWidth,
                ),
                _buildStatCard(
                  'Fleet Age',
                  '${telemetry['age_years']} yrs',
                  Icons.calendar_today,
                  const Color(0xFFF59E0B),
                  cardWidth,
                ),
                _buildStatCard(
                  'Repairs',
                  '${telemetry['past_repairs_count']} logs',
                  Icons.build,
                  const Color(0xFF8B5CF6),
                  cardWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
