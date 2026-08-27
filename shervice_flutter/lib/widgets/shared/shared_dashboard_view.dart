import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_metric.dart';
import 'maintenance_alert.dart';
import '../oic/company_trip_metric.dart';
import '../../../constant.dart';

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

  int _currentAlertPage = 0;
  final int _alertsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Color _proceduralColorAssigner(int index) {
    final List<Color> designPalette = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
    ];
    return designPalette[index % designPalette.length];
  }

  Future<void> _fetchLiveDashboardData() async {
    try {
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
            _metrics = [
              DashboardMetric(
                title: 'Active Drivers',
                value: (metricsMap['totalDrivers'] ?? 0).toString(),
                subTitle: 'Registered profiles',
                icon: Icons.people_alt,
                baseColor: const Color(0xFF3B82F6),
              ),
              DashboardMetric(
                title: 'Active Vehicles',
                value: (metricsMap['activeVehicles'] ?? 0).toString(),
                subTitle: 'Ready for operation',
                icon: Icons.directions_car,
                baseColor: const Color(0xFF10B981),
              ),
              DashboardMetric(
                title: 'Ongoing Trips',
                value: (metricsMap['ongoingTrips'] ?? 0).toString(),
                subTitle: 'Currently in transit',
                icon: Icons.directions_bus,
                baseColor: const Color(0xFF8B5CF6),
              ),
              DashboardMetric(
                title: 'Unscheduled',
                value: (metricsMap['unassignedSchedules'] ?? 0).toString(),
                subTitle: 'Pending assignment',
                icon: Icons.assignment_late,
                baseColor: const Color(0xFFF59E0B),
              ),
              DashboardMetric(
                title: 'Maintenance Alerts',
                value: (metricsMap['maintenanceAlerts'] ?? 0).toString(),
                subTitle: 'Attention required',
                icon: Icons.build_circle,
                baseColor: const Color(0xFFEF4444),
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        final double horizontalPadding = isMobile ? 10.0 : 16.0;
        final double spacing = isMobile ? 8.0 : 12.0;

        int columns = constraints.maxWidth > 1200
            ? 5
            : constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 640
            ? 2
            : 1;

        double dynamicWidth =
            (constraints.maxWidth -
                (horizontalPadding * 2) -
                (spacing * (columns - 1))) /
            columns;
        dynamicWidth = dynamicWidth.floorToDouble();

        return RefreshIndicator(
          onRefresh: _fetchLiveDashboardData,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12.0,
            ),
            children: [
              if (_errorMessage != null) _buildErrorBanner(),
              widget.headerWidget,
              const SizedBox(height: 12),
              _buildKpiGrid(context, dynamicWidth, spacing),
              const SizedBox(height: 12),
              // ─── Row: Maintenance + Client Trips ───
              isMobile
                  ? Column(
                      children: [
                        _buildMaintenanceCard(),
                        if (widget.showClientTrips) ...[
                          const SizedBox(height: 12),
                          _buildClientTripsCard(),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildMaintenanceCard(),
                        ),
                        if (widget.showClientTrips) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildClientTripsCard(),
                          ),
                        ],
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, double width, double spacing) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: _metrics.map((m) {
        final Color color = m.baseColor;
        return Container(
          width: width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(m.icon, color: color, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                m.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                m.subTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaintenanceCard() {
    final theme = Theme.of(context);
    final paginatedList = _paginatedAlerts;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Maintenance Alerts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_alerts.length}',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
            _alerts.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      "All vehicles are optimal.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ...paginatedList.map(
                      (log) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.car_repair,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.vehicleId,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    log.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
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
                    if (_alerts.length > _alertsPerPage) ...[
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_currentAlertPage * _alertsPerPage) + 1} - ${min((_currentAlertPage + 1) * _alertsPerPage, _alerts.length)} of ${_alerts.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: _currentAlertPage > 0
                                    ? () => setState(() => _currentAlertPage--)
                                    : null,
                                color: _currentAlertPage > 0
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey.shade300,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_currentAlertPage + 1} / $_totalAlertPages',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed:
                                    _currentAlertPage < _totalAlertPages - 1
                                    ? () => setState(() => _currentAlertPage++)
                                    : null,
                                color: _currentAlertPage < _totalAlertPages - 1
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildClientTripsCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Weekly Dispatches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
            _companyTrips.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'No client trips this week.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _companyTrips.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 12,
                    thickness: 0.5,
                    color: theme.dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    final item = _companyTrips[index];
                    final Color color = _proceduralColorAssigner(index);
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.business_center,
                            color: color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: item.utilization,
                                        backgroundColor:
                                            theme.colorScheme.surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                        minHeight: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.tripCount}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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