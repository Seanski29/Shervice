import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';
import '../../../constant.dart';
import '../../../widgets/driver/driver_evaluation_view.dart';

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
      final dRes = await http.get(Uri.parse('$backendUrl/test-db'));
      if (dRes.statusCode == 200) {
        final dData = jsonDecode(dRes.body);
        _allDrivers = dData['sample_data_payload'] ?? [];
      }

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
    List<dynamic> tempD = _allDrivers.where((d) {
      final name = (d['full_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    tempD.sort((a, b) {
      if (_currentSort == 'Rating (High-Low)') {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rB.compareTo(rA);
      } else if (_currentSort == 'Rating (Low-High)') {
        final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return rA.compareTo(rB);
      } else {
        final nameA = (a['full_name'] ?? '').toString().toLowerCase();
        final nameB = (b['full_name'] ?? '').toString().toLowerCase();
        return _currentSort == 'Z to A'
            ? nameB.compareTo(nameA)
            : nameA.compareTo(nameB);
      }
    });

    List<dynamic> tempV = _allVehicles.where((v) {
      final plate = (v['plate_number'] ?? '').toString().toLowerCase();
      final type = (v['bus_type'] ?? '').toString().toLowerCase();
      final status = (v['health_status'] ?? 'Good').toString().toLowerCase();

      bool matchesSearch =
          plate.contains(_searchQuery.toLowerCase()) ||
          type.contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;

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
    if (_isLoading) {
      return List.generate(5, (index) => _activeTab == 0
          ? {
              'user_id': index + 1, 'full_name': 'Loading Driver', 'rating': 0.0,
              'employment_status': 'Active', 'license_no': 'Loading',
            }
          : {
              'vehicle_id': index + 1, 'plate_number': 'LOADING-${index + 1}',
              'bus_type': 'Loading Vehicle', 'health_status': 'Good',
            });
    }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Skeletonizer(
        enabled: _isLoading,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Evaluate driver performance scores and execute predictive maintenance algorithms.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),

              // ── TOGGLE BUTTONS ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark ? Border.all(color: Colors.grey.shade800) : null,
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      0,
                      'Driver Performance',
                      Icons.person,
                      isDark,
                    ),
                    _buildToggleButton(
                      1,
                      'Vehicle Predictive ML',
                      Icons.memory,
                      isDark,
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
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _activeTab == 0
                              ? 'Search drivers...'
                              : 'Search vehicles...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: subtitleColor,
                          ),
                          filled: true,
                          fillColor: cardBg,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
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
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _currentSort,
                            dropdownColor: cardBg,
                            icon: Icon(
                              Icons.sort,
                              size: 18,
                              color: subtitleColor,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
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
                child: !_isLoading && _paginatedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activeTab == 0
                                  ? Icons.group_off
                                  : Icons.car_crash,
                              size: 48,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                              ? _buildDriverCard(item, isDark)
                              : _buildVehicleCard(item, isDark);
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
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: textColor),
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
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
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
                              icon: Icon(Icons.chevron_right, color: textColor),
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
      ),
    );
  }

  Widget _buildToggleButton(int index, String label, IconData icon, bool isDark) {
    final bool isActive = _activeTab == index;
    final Color activeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color inactiveText = isDark ? Colors.grey.shade500 : const Color(0xFF64748B);
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
            _searchQuery = ''; 
            _currentSort = 'A to Z'; 
            _applyFilters();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark ? Colors.black45 : Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                color: isActive ? const Color(0xFF3B82F6) : inactiveText,
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
                      color: isActive ? const Color(0xFF3B82F6) : inactiveText,
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

  Widget _buildDriverCard(dynamic driver, bool isDark) {
    final double rating = (driver['rating'] as num?)?.toDouble() ?? 0.0;
    final String status = driver['employment_status'] ?? 'Active';
    final Color statusColor = status.toLowerCase() == 'active'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final Color iconBg = isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: cardBg,
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
                  color: iconBg,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge,
                              size: 14,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver['license_no'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: subTextColor,
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
                  color: statusColor.withValues(alpha: 0.1),
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

  Widget _buildVehicleCard(dynamic vehicle, bool isDark) {
    final String status = vehicle['health_status'] ?? 'Good';

    final Color statusColor =
        (status.toLowerCase() == 'good' || status.toLowerCase() == 'excellent')
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final Color iconBg = isDark ? Colors.purple.withValues(alpha: 0.15) : Colors.purple.shade50;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: cardBg,
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
                  color: iconBg,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle['bus_type'] ?? 'Unknown Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
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
                  color: statusColor.withValues(alpha: 0.1),
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

  void _showDriverEvalModal(String driverId) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: isMobile ? double.infinity : 600,
          height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.grey.shade400 : Colors.black87),
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
        if (mounted) {
          setState(() {
            _error =
                "Failed to run diagnostics. Server returned ${res.statusCode}.";
            _isRunning = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Connection error. Ensure Python backend is running.";
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color iconColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final Color dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: iconColor),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Divider(height: 24, color: dividerColor),

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
              _buildResultsView(isMobile, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(bool isMobile, bool isDark) {
    final double riskIndex = (_results!['risk_index'] ?? 0.0) * 100;
    final Map<String, dynamic> telemetry = _results!['telemetry_metrics'] ?? {};

    final bool isLockout = riskIndex >= 80.0;
    final bool isWarning = riskIndex >= 50.0 && riskIndex < 80.0;

    Color statusColor;
    Color bgColor;
    String statusLabel;
    String statusDesc;

    if (isLockout) {
      statusColor = const Color(0xFFEF4444); 
      bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      statusLabel = 'CLASS 1: CRITICAL RISK';
      statusDesc =
          'Algorithm dictates an imminent breakdown risk. Asset lockout triggered.';
    } else if (isWarning) {
      statusColor = const Color(0xFFF59E0B); 
      bgColor = isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
      statusLabel = 'WARNING: ELEVATED RISK';
      statusDesc =
          'Asset is operational, but structural wear is increasing. Monitor closely.';
    } else {
      statusColor = const Color(0xFF10B981);
      bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
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
            border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
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
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
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
                  isDark,
                ),
                _buildStatCard(
                  'Odometer',
                  '${telemetry['total_mileage_km']} km',
                  Icons.speed,
                  const Color(0xFF3B82F6),
                  cardWidth,
                  isDark,
                ),
                _buildStatCard(
                  'Fleet Age',
                  '${telemetry['age_years']} yrs',
                  Icons.calendar_today,
                  const Color(0xFFF59E0B),
                  cardWidth,
                  isDark,
                ),
                _buildStatCard(
                  'Repairs',
                  '${telemetry['past_repairs_count']} logs',
                  Icons.build,
                  const Color(0xFF8B5CF6),
                  cardWidth,
                  isDark,
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
    bool isDark,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
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