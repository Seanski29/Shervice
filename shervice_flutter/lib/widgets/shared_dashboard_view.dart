import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/dashboard_metric.dart';
import '../../models/maintenance_alert.dart';
import '../../models/company_trip_metric.dart';
// 👇 1. Imported your global backendUrl so it doesn't break on deployment
import '../../constant.dart';

class SharedDashboardView extends StatefulWidget {
  final Widget headerWidget;
  final bool showClientTrips;

  const SharedDashboardView({
    super.key,
    required this.headerWidget,
    required this.showClientTrips,
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

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Color _proceduralColorAssigner(int index) {
    final List<Color> designPalette = [
      Colors.blue.shade600,
      Colors.orange.shade500,
      Colors.green.shade500,
      Colors.purple.shade500,
      Colors.teal.shade500,
    ];
    return designPalette[index % designPalette.length];
  }

  Future<void> _fetchLiveDashboardData() async {
    try {
      // 👇 2. Pointing directly to your global backendUrl constant
      final response = await http
          .get(Uri.parse('$backendUrl/dashboard/metrics'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final metricsMap = data['metrics'] ?? {};
          final List<dynamic> alertsList = data['alerts'] ?? [];
          final List<dynamic> companyList =
              data['company_weekly_metrics'] ?? [];

          if (!mounted) return;
          setState(() {
            // 👇 3. Updated UI cards to match Python's 'ongoingTrips' and 'unassignedSchedules'
            _metrics = [
              DashboardMetric(
                title: 'Active Drivers',
                value: (metricsMap['totalDrivers'] ?? 0).toString(),
                subTitle: 'Registered profiles',
                icon: Icons.people,
                baseColor: Colors.blue,
              ),
              DashboardMetric(
                title: 'Active Vehicles',
                value: (metricsMap['activeVehicles'] ?? 0).toString(),
                subTitle: 'Ready for operation',
                icon: Icons.directions_car,
                baseColor: Colors.green,
              ),
              DashboardMetric(
                title: 'Ongoing Trips',
                value: (metricsMap['ongoingTrips'] ?? 0).toString(),
                subTitle: 'Currently in transit',
                icon: Icons.directions_bus,
                baseColor: Colors.purple,
              ),
              DashboardMetric(
                title: 'Unscheduled',
                value: (metricsMap['unassignedSchedules'] ?? 0).toString(),
                subTitle: 'Pending assignment',
                icon: Icons.assignment_late,
                baseColor: Colors.orange,
              ),
              DashboardMetric(
                title: 'Maintenance Alerts',
                value: (metricsMap['maintenanceAlerts'] ?? 0).toString(),
                subTitle: 'Attention required',
                icon: Icons.warning_rounded,
                baseColor: Colors.red,
              ),
            ];

            _alerts = alertsList
                .map((log) => MaintenanceAlert.fromJson(log))
                .toList();
            _companyTrips = companyList
                .map((json) => CompanyTripMetric.fromJson(json))
                .toList();
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
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double paddingTotal = 32.0;

        // 👇 4. Restored the math to perfectly fit 5 metric cards side-by-side
        double dynamicWidth = constraints.maxWidth > 1200
            ? (constraints.maxWidth - (paddingTotal + 64)) / 5
            : constraints.maxWidth > 900
            ? (constraints.maxWidth - (paddingTotal + 32)) / 3
            : constraints.maxWidth > 640
            ? (constraints.maxWidth - (paddingTotal + 16)) / 2
            : constraints.maxWidth - paddingTotal;

        return RefreshIndicator(
          onRefresh: _fetchLiveDashboardData,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            children: [
              if (_errorMessage != null) _buildErrorBanner(),
              widget.headerWidget,
              const SizedBox(height: 24),
              _buildKpiGrid(dynamicWidth),
              const SizedBox(height: 24),
              _buildMaintenanceCard(),
              if (widget.showClientTrips) ...[
                const SizedBox(height: 24),
                _buildClientTripsCard(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildKpiGrid(double width) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: _metrics
          .map(
            (m) => Container(
              width: width,
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
                      SizedBox(
                        width: 120,
                        child: Text(
                          m.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: m.baseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(m.icon, color: m.baseColor, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.subTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMaintenanceCard() {
    final paginatedList = _paginatedAlerts;

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
              const Text(
                'Recent Vehicle Maintenance Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                child: const Text(
                  'Live Stream',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _alerts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      "No active maintenance alerts logged.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ...paginatedList.map(
                      (log) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.build_circle_outlined,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.vehicleId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Issue: ${log.description}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${(_currentAlertPage * _alertsPerPage) + 1} - ${min((_currentAlertPage + 1) * _alertsPerPage, _alerts.length)} of ${_alerts.length} alerts',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: _currentAlertPage > 0
                                  ? () => setState(() => _currentAlertPage--)
                                  : null,
                              tooltip: 'Previous logs page',
                            ),
                            Text(
                              '${_currentAlertPage + 1} / $_totalAlertPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed:
                                  _currentAlertPage < _totalAlertPages - 1
                                  ? () => setState(() => _currentAlertPage++)
                                  : null,
                              tooltip: 'Next logs page',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildClientTripsCard() {
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
          const Text(
            'Weekly Passenger Trips by Client',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          _companyTrips.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No active client records retrieved.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _companyTrips.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final item = _companyTrips[index];
                    final color = _proceduralColorAssigner(index);
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.business, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: item.utilization,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.tripCount} Trips',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }
}
