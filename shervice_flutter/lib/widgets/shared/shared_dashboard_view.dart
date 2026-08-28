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
  Map<String, List<dynamic>> _metricDetails = {};
  DateTime _selectedDispatchMonth = DateTime.now();
  bool _isDispatchLoading = false;

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
              data['company_monthly_metrics'] ?? [];
          final Map<String, dynamic> detailsMap = Map<String, dynamic>.from(
            data['details'] ?? {},
          );

          if (!mounted) return;
          setState(() {
            _metrics = [
              DashboardMetric(
                title: 'All Drivers',
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
            _metricDetails = detailsMap.map(
              (key, value) =>
                  MapEntry(key, value is List ? value : <dynamic>[]),
            );
            _currentAlertPage = 0;
            _errorMessage = null;
            _isLoading = false;
          });
          _loadMonthlyDispatches();
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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        final double horizontalPadding = isMobile ? 12.0 : 24.0;
        final double spacing = isMobile ? 12.0 : 16.0;

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
              vertical: 24.0,
            ),
            children: [
              if (_errorMessage != null) _buildErrorBanner(),
              widget.headerWidget,
              const SizedBox(height: 24),
              _buildKpiGrid(context, dynamicWidth, spacing),
              const SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        if (widget.showClientTrips) _buildClientTripsCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showClientTrips) ...[
                          Expanded(child: _buildClientTripsCard()),
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
        return InkWell(
          onTap: () => _showMetricDetails(m),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(16),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(m.icon, color: color, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  m.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 22,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showMetricDetails(DashboardMetric metric) async {
    var details = _metricDetails[metric.title] ?? const <dynamic>[];
    if (metric.title == 'All Drivers' ||
        (details.isEmpty && metric.value != '0')) {
      final fetchedDetails = await _fetchDetailsForMetric(metric.title);
      if (fetchedDetails.isNotEmpty || details.isEmpty) {
        details = fetchedDetails;
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _DetailsDialog(
        title: metric.title,
        color: metric.baseColor,
        items: details,
      ),
    );
  }

  Future<List<dynamic>> _fetchDetailsForMetric(String title) async {
    try {
      if (title == 'Maintenance Alerts') return _alertsAsDetails();
      if (title == 'Client Monthly Dispatches') return _companyTripsAsDetails();

      final endpoint = title == 'All Drivers'
          ? '/test-db'
          : title == 'Active Vehicles'
          ? '/vehicles'
          : '/schedules/all';
      final response = await http
          .get(Uri.parse('$backendUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawItems =
          data['data'] ??
          data['sample_data_payload'] ??
          data['drivers'] ??
          data['vehicles'] ??
          [];
      if (rawItems is! List) return [];

      if (title == 'All Drivers') {
        return rawItems
            .whereType<Map>()
            .map(
              (item) => {
                'label': item['full_name'] ?? 'Unnamed Driver',
                ...Map<String, dynamic>.from(item),
              },
            )
            .toList();
      }

      if (title == 'Active Vehicles') {
        return rawItems
            .whereType<Map>()
            .where((item) => item['is_available'] == true)
            .map(
              (item) => {
                'label': item['plate_number'] ?? 'Unknown Vehicle',
                ...Map<String, dynamic>.from(item),
              },
            )
            .toList();
      }

      return rawItems
          .whereType<Map>()
          .where((item) {
            final status = item['trip_status']?.toString().toLowerCase();
            if (title == 'Ongoing Trips') {
              return status == 'ongoing' || status == 'in progress';
            }
            return const {
                  'pending staff assignment',
                  'pending',
                  'scheduled',
                }.contains(status) &&
                (item['user_id'] == null || item['vehicle_id'] == null);
          })
          .map((item) {
            return {
              'label': 'Trip ${item['trip_id'] ?? 'Unknown'}',
              'status': item['trip_status'] ?? 'Needs assignment',
              ...Map<String, dynamic>.from(item),
            };
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _alertsAsDetails() => _alerts
      .map(
        (alert) => {'label': alert.vehicleId, 'description': alert.description},
      )
      .toList();

  List<dynamic> _companyTripsAsDetails() => _companyTrips
      .map(
        (trip) => {
          'label': trip.companyName,
          'status': '${trip.tripCount} trips',
        },
      )
      .toList();

  Widget _buildMaintenanceCard() {
    final theme = Theme.of(context);
    final paginatedList = _paginatedAlerts;

    return InkWell(
      onTap: () => _showMetricDetails(
        DashboardMetric(
          title: 'Maintenance Alerts',
          value: _alerts.length.toString(),
          subTitle: 'Attention required',
          icon: Icons.build_circle,
          baseColor: const Color(0xFFEF4444),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                    ),
                                    Text(
                                      log.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12),
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
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed: _currentAlertPage > 0
                                      ? () =>
                                            setState(() => _currentAlertPage--)
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
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed:
                                      _currentAlertPage < _totalAlertPages - 1
                                      ? () =>
                                            setState(() => _currentAlertPage++)
                                      : null,
                                  color:
                                      _currentAlertPage < _totalAlertPages - 1
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
      ),
    );
  }

  Widget _buildClientTripsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: _showClientTripDetails,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              children: [
                Expanded(
                  child: Text(
                    'Client Monthly Dispatches',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDispatchMonthPicker(isDark),
              ],
            ),
            const SizedBox(height: 20),
            _isDispatchLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _companyTrips.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Text(
                        'No client trips for this month.',
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
                                    fontSize: 13,
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
                                          backgroundColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
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
                                        fontSize: 12,
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
      ),
    );
  }

  Widget _buildDispatchMonthPicker(bool isDark) {
    final years = List<int>.generate(
      7,
      (index) => DateTime.now().year - 3 + index,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<int>(
          value: _selectedDispatchMonth.month,
          underline: const SizedBox.shrink(),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          items: List.generate(
            12,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text(_monthName(index + 1)),
            ),
          ),
          onChanged: (month) {
            if (month != null)
              _changeDispatchMonth(month, _selectedDispatchMonth.year);
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: years.contains(_selectedDispatchMonth.year)
              ? _selectedDispatchMonth.year
              : years.last,
          underline: const SizedBox.shrink(),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          items: years
              .map(
                (year) =>
                    DropdownMenuItem(value: year, child: Text(year.toString())),
              )
              .toList(),
          onChanged: (year) {
            if (year != null)
              _changeDispatchMonth(_selectedDispatchMonth.month, year);
          },
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Future<void> _changeDispatchMonth(int month, int year) async {
    setState(() {
      _selectedDispatchMonth = DateTime(year, month);
    });
    await _loadMonthlyDispatches();
  }

  Future<void> _loadMonthlyDispatches() async {
    if (!mounted) return;
    setState(() => _isDispatchLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/trips'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final rawTrips = decoded is Map ? decoded['trips'] : decoded;
        if (rawTrips is List) {
          final selectedPeriod =
              '${_selectedDispatchMonth.year}-${_selectedDispatchMonth.month.toString().padLeft(2, '0')}';
          final counts = <String, int>{};
          for (final rawTrip in rawTrips) {
            if (rawTrip is! Map) continue;
            final tripDate = rawTrip['schedule_date']?.toString() ?? '';
            final status = rawTrip['trip_status']?.toString().toLowerCase();
            if (!tripDate.startsWith(selectedPeriod) || status != 'completed') {
              continue;
            }
            final profile = rawTrip['oic_profile'];
            final company = profile is Map
                ? profile['company_name']?.toString()
                : (rawTrip['client_company'] ?? rawTrip['company_name'])
                      ?.toString();
            final companyName = (company == null || company.isEmpty)
                ? 'Unassigned Client'
                : company;
            counts[companyName] = (counts[companyName] ?? 0) + 1;
          }
          final highestCount = counts.values.fold<int>(0, max);
          if (mounted) {
            setState(() {
              _companyTrips = counts.entries
                  .map(
                    (entry) => CompanyTripMetric(
                      companyName: entry.key,
                      tripCount: entry.value,
                      utilization: highestCount == 0
                          ? 0
                          : entry.value / highestCount,
                    ),
                  )
                  .toList();
            });
          }
        }
      }
    } catch (_) {
      // Keep the previous month visible when a refresh fails.
    } finally {
      if (mounted) setState(() => _isDispatchLoading = false);
    }
  }

  Future<void> _showClientTripDetails() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DetailsDialog(
        title: 'Client Monthly Dispatches',
        color: const Color(0xFF3B82F6),
        items: _companyTrips
            .map(
              (trip) => {
                'label': trip.companyName,
                'status': '${trip.tripCount} trips',
              },
            )
            .toList(),
      ),
    );
  }
}

class _DetailsDialog extends StatefulWidget {
  final String title;
  final Color color;
  final List<dynamic> items;

  const _DetailsDialog({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  int get _totalPages => max(1, (widget.items.length / _itemsPerPage).ceil());

  List<dynamic> get _paginatedItems {
    final start = _currentPage * _itemsPerPage;
    final end = min(start + _itemsPerPage, widget.items.length);
    return start >= widget.items.length ? [] : widget.items.sublist(start, end);
  }

  IconData get _itemIcon {
    switch (widget.title) {
      case 'Active Vehicles':
        return Icons.directions_car;
      case 'All Drivers':
        return Icons.person_outline;
      case 'Maintenance Alerts':
        return Icons.car_repair;
      default:
        return Icons.directions_bus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: widget.items.isEmpty
            ? const Text('No matching records found.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _paginatedItems.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rawItem = _paginatedItems[index];
                  final item = rawItem is Map
                      ? Map<String, dynamic>.from(rawItem)
                      : <String, dynamic>{'label': rawItem.toString()};
                  final label = item['label']?.toString() ?? 'Unknown record';
                  final status = item['status']?.toString();
                  final description = item['description']?.toString();
                  final extraDetails = item.entries
                      .where(
                        (entry) => entry.key != 'label' && entry.value != null,
                      )
                      .map(
                        (entry) =>
                            '${_formatDetailLabel(entry.key)}: ${entry.value}',
                      )
                      .toList();
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Icon(_itemIcon, color: widget.color),
                    title: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: description != null
                        ? Text(description)
                        : status != null
                        ? Text(status)
                        : null,
                    children: extraDetails.isEmpty
                        ? [
                            const ListTile(
                              dense: true,
                              title: Text(
                                'No additional information available.',
                              ),
                            ),
                          ]
                        : extraDetails
                              .map(
                                (detail) => ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(
                                    left: 56,
                                  ),
                                  title: Text(detail),
                                ),
                              )
                              .toList(),
                  );
                },
              ),
      ),
      actions: [
        if (widget.items.length > _itemsPerPage)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_currentPage + 1} / $_totalPages'),
              IconButton(
                tooltip: 'Next page',
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDetailLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
