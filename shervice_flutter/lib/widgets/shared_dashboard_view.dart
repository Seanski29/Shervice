import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ❌ Removed the hallucinated external model imports so this file is 100% self-contained!

class SharedDashboardView extends StatefulWidget {
  final Widget headerWidget;
  final bool showClientTrips;
  
  // ─── NEW NAVIGATION CALLBACKS ───
  final VoidCallback? onDriverClick;
  final VoidCallback? onVehicleClick;
  final VoidCallback? onPunctualityClick;
  final VoidCallback? onAlertClick;

  const SharedDashboardView({
    super.key,
    required this.headerWidget,
    required this.showClientTrips,
    this.onDriverClick,
    this.onVehicleClick,
    this.onPunctualityClick,
    this.onAlertClick,
  });

  @override
  State<SharedDashboardView> createState() => _SharedDashboardViewState();
}

class _SharedDashboardViewState extends State<SharedDashboardView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DashboardMetric> _metrics = [];
  List<MaintenanceAlert> _alerts = [];
  List<CompanyTripMetric> _companyTrips = [];

  // ─── MAINTENANCE PAGINATION TRACKING PARAMETERS ───
  int _currentAlertPage = 0;
  final int _alertsPerPage = 3;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/dashboard/metrics';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/dashboard/metrics'
        : 'http://127.0.0.1:5000/api/dashboard/metrics';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  // Handles color assignment locally so we don't modify your external models!
  Color _proceduralColorAssigner(int index) {
    final List<Color> designPalette = [
      const Color(0xFF3B82F6), // Blue 500
      const Color(0xFF10B981), // Green 500
      const Color(0xFFF59E0B), // Yellow 500
      const Color(0xFFEF4444), // Red 500
      const Color(0xFF8B5CF6), // Purple 500
    ];
    return designPalette[index % designPalette.length];
  }

  Future<void> _fetchLiveDashboardData() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final metricsMap = data['metrics'] ?? {};
          final List<dynamic> alertsList = data['alerts'] ?? [];
          final List<dynamic> companyList = data['company_weekly_metrics'] ?? [];

          if (!mounted) return;
          setState(() {
            // Reverted to your exact model structure (No hallucinated baseColor property)
            _metrics = [
              DashboardMetric(
                title: 'Active Drivers', 
                value: (metricsMap['totalDrivers'] ?? 0).toString(), 
                subTitle: 'Registered profiles', 
                icon: Icons.people_alt, 
                onTap: widget.onDriverClick, // 👈 Wired up
              ),
              DashboardMetric(
                title: 'Active Vehicles', 
                value: (metricsMap['activeVehicles'] ?? 0).toString(), 
                subTitle: 'Ready for operation', 
                icon: Icons.directions_bus, 
                onTap: widget.onVehicleClick, // 👈 Wired up
              ),
              DashboardMetric(
                title: 'Avg Punctuality', 
                value: (metricsMap['averagePunctuality'] ?? 5.0).toString(), 
                subTitle: 'Out of 5.0 rating', 
                icon: Icons.star_rounded, 
                onTap: widget.onPunctualityClick, // 👈 Wired up
              ),
              DashboardMetric(
                title: 'Maintenance Alerts', 
                value: (metricsMap['maintenanceAlerts'] ?? 0).toString(), 
                subTitle: 'Attention required', 
                icon: Icons.build_circle, 
                onTap: widget.onAlertClick, // 👈 Wired up
              ),
            ];

            _alerts = alertsList.map((log) => MaintenanceAlert.fromJson(log)).toList();
            _companyTrips = companyList.map((json) => CompanyTripMetric.fromJson(json)).toList();
            _currentAlertPage = 0; 
            _errorMessage = null;
            _isLoading = false;
          });
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not sync backend data fields safely.";
          _isLoading = false;
        });
      }
    }
  }

  // ─── MAINTENANCE SUB-PAGINATION DATA SLICERS ───
  int get _totalAlertPages => (_alerts.length / _alertsPerPage).ceil();

  List<MaintenanceAlert> get _paginatedAlerts {
    if (_alerts.isEmpty) return [];
    int start = _currentAlertPage * _alertsPerPage;
    int end = min(start + _alertsPerPage, _alerts.length);
    return _alerts.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop check to place cards side-by-side to save wasted vertical space
        final bool isDesktop = constraints.maxWidth > 1000;

        return RefreshIndicator(
          onRefresh: _fetchLiveDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) _buildErrorBanner(),
                
                widget.headerWidget,
                const SizedBox(height: 24),
                
                _buildKpiGrid(constraints.maxWidth),
                const SizedBox(height: 24),
                
                // Side-by-side layout on desktop, stacked on mobile
                if (isDesktop && widget.showClientTrips)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMaintenanceCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildClientTripsCard()),
                    ],
                  )
                else ...[
                  _buildMaintenanceCard(),
                  if (widget.showClientTrips) ...[
                    const SizedBox(height: 24),
                    _buildClientTripsCard(),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFFCA5A5)) 
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)), 
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!, 
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14, fontWeight: FontWeight.w500)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(double maxWidth) {
    // Dynamic column sizing to fill space effectively
    int crossAxisCount = maxWidth > 1200 ? 4 : maxWidth > 768 ? 2 : 1;
    double spacing = 16.0;
    double childWidth = (maxWidth - 48 - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: _metrics.asMap().entries.map((entry) {
        int index = entry.key;
        DashboardMetric m = entry.value;
        
        // Apply color dynamically here instead of the model
        Color cardColor = _proceduralColorAssigner(index);

        return Container(
          width: childWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Slightly smaller radius
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: m.onTap, // 👈 Makes the card clickable
              child: Padding(
                padding: const EdgeInsets.all(16), // 👈 Reduced padding to shrink cards
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10), // Reduced icon padding
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ), 
                          child: Icon(m.icon, color: cardColor, size: 24) // Smaller icon
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.green.shade600, size: 12),
                              const SizedBox(width: 4),
                              Text('Live', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 👈 Reduced font size from 32 to 26 to tighten white space
                    Text(m.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1)),
                    const SizedBox(height: 2),
                    Text(m.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 2),
                    Text(m.subTitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaintenanceCard() {
    final paginatedList = _paginatedAlerts;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handyman, color: Color(0xFF475569), size: 22),
                    SizedBox(width: 12),
                    Text('Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                if (_alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_alerts.length} Pending', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: _alerts.isEmpty
                ? _buildEmptyState(Icons.check_circle_outline, "All vehicles are operating optimally.", Colors.green)
                : Column(
                    children: [
                      ...paginatedList.map((log) => _buildAlertItem(log)),
                      
                      // Modern Pagination
                      if (_totalAlertPages > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${(_currentAlertPage * _alertsPerPage) + 1}-${min((_currentAlertPage + 1) * _alertsPerPage, _alerts.length)} of ${_alerts.length}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentAlertPage > 0 ? () => setState(() => _currentAlertPage--) : null,
                                  color: _currentAlertPage > 0 ? Colors.blue : Colors.grey.shade300,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentAlertPage < _totalAlertPages - 1 ? () => setState(() => _currentAlertPage++) : null,
                                  color: _currentAlertPage < _totalAlertPages - 1 ? Colors.blue : Colors.grey.shade300,
                                ),
                              ],
                            )
                          ],
                        )
                      ]
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(MaintenanceAlert log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight( 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored indicator bar
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444), 
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12), 
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)), 
                      child: const Icon(Icons.car_repair, color: Color(0xFFDC2626), size: 24)
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(log.vehicleId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))), 
                          const SizedBox(height: 4), 
                          Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4))
                        ]
                      )
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientTripsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
            ),
            child: const Row(
              children: [
                Icon(Icons.business_center, color: Color(0xFF475569), size: 22),
                SizedBox(width: 12),
                Text('Weekly Dispatches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          
          // Body (Using Wrap to avoid wasted space)
          Padding(
            padding: const EdgeInsets.all(24),
            child: _companyTrips.isEmpty
                ? _buildEmptyState(Icons.analytics_outlined, "No client trips recorded this week.", Colors.blue)
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _companyTrips.map((metric) {
                      
                      // ✅ Using the strongly typed fields from our local model below
                      final String companyName = metric.companyName;
                      final String tripCount = metric.totalTrips.toString();

                      return Container(
                        width: 180, // Fixed width for nice grid tiles
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.domain, color: Colors.blueGrey, size: 24),
                            const SizedBox(height: 12),
                            Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(tripCount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                                const SizedBox(width: 4),
                                const Text('trips', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0))
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500))
          ],
        )
      )
    );
  }
}

// ─── LOCAL MODEL DEFINITIONS (Self-Contained) ───

class DashboardMetric {
  final String title;
  final String value;
  final String subTitle;
  final IconData icon;
  final VoidCallback? onTap; // 👈 Added onTap to the model

  DashboardMetric({
    required this.title,
    required this.value,
    required this.subTitle,
    required this.icon,
    this.onTap,
  });
}

class MaintenanceAlert {
  final String vehicleId;
  final String description;

  MaintenanceAlert({required this.vehicleId, required this.description});

  factory MaintenanceAlert.fromJson(Map<String, dynamic> json) {
    return MaintenanceAlert(
      vehicleId: json['plate_number']?.toString() ?? json['vehicleId']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? 'No description provided.',
    );
  }
}

class CompanyTripMetric {
  final String companyName;
  final int totalTrips;

  CompanyTripMetric({required this.companyName, required this.totalTrips});

  factory CompanyTripMetric.fromJson(Map<String, dynamic> json) {
    return CompanyTripMetric(
      companyName: json['company_name']?.toString() ?? json['companyName']?.toString() ?? 'Client',
      totalTrips: int.tryParse(json['totalTrips']?.toString() ?? json['tripCount']?.toString() ?? '0') ?? 0,
    );
  }
}