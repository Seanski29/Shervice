import 'dart:math';
import 'package:flutter/material.dart';

class FleetOverviewTab extends StatefulWidget {
  final List<dynamic> vehicles;
  final List<dynamic> drivers;
  final List<dynamic> trips;
  final List<dynamic> maintenanceLogs;
  final VoidCallback onSyncAction;

  const FleetOverviewTab({
    super.key,
    required this.vehicles,
    required this.drivers,
    required this.trips,
    required this.maintenanceLogs,
    required this.onSyncAction,
  });

  @override
  State<FleetOverviewTab> createState() => _FleetOverviewTabState();
}

class _FleetOverviewTabState extends State<FleetOverviewTab> {
  String _timeFrame = 'Last 30 Days';
  final List<String> _timeOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'This Year',
    'All Time',
  ];

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    DateTime now = DateTime.now();
    DateTime start = DateTime(2000);
    if (_timeFrame == 'Last 7 Days') {
      start = now.subtract(const Duration(days: 7));
    } else if (_timeFrame == 'Last 30 Days') {
      start = now.subtract(const Duration(days: 30));
    } else if (_timeFrame == 'This Year') {
      start = DateTime(now.year, 1, 1);
    }

    List<dynamic> fTrips = widget.trips.where((t) {
      DateTime? d = DateTime.tryParse((t['schedule_date'] ?? '').toString());
      return d != null && (d.isAfter(start) || d.isAtSameMomentAs(start));
    }).toList();

    List<dynamic> fMaint = widget.maintenanceLogs.where((m) {
      DateTime? d = DateTime.tryParse(
        (m['incident_date'] ?? m['repair_date'] ?? '').toString(),
      );
      return d != null && (d.isAfter(start) || d.isAtSameMomentAs(start));
    }).toList();

    // --- KPIs ---
    double totalDist = fTrips.fold(
      0.0,
      (s, t) => s + _parseDouble(t['route_distance']),
    );
    int totalPax = fTrips.fold(
      0,
      (s, t) =>
          s + (int.tryParse(t['passenger_count']?.toString() ?? '0') ?? 0),
    );

    int readyV = widget.vehicles.where((v) {
      double daysRemaining = (v['live_risk_score'] as num?)?.toDouble() ?? 0.0;
      String st = (v['health_status'] ?? '').toString().toLowerCase();
      return !st.contains('maintenance') &&
          !st.contains('repair') &&
          daysRemaining > 7.0;
    }).length;

    // Safety Fallback: Because backend /trips lacks rating info, we use the global driver average
    List<dynamic> evaluatedTrips = fTrips
        .where(
          (t) =>
              t['rating'] != null ||
              t['csat'] != null ||
              t['evaluation_score'] != null,
        )
        .toList();

    double csat = 0.0;
    if (evaluatedTrips.isNotEmpty) {
      csat =
          evaluatedTrips.fold(
            0.0,
            (s, t) =>
                s +
                _parseDouble(t['rating'] ?? t['csat'] ?? t['evaluation_score']),
          ) /
          evaluatedTrips.length;
    } else {
      csat = widget.drivers.isEmpty
          ? 0.0
          : widget.drivers.fold(0.0, (s, d) => s + _parseDouble(d['rating'])) /
                widget.drivers.length;
    }

    // --- CHART DATA GROUPING ---
    Map<String, int> dateCounts = {};
    for (var t in fTrips) {
      String d = t['schedule_date']?.toString().split(' ').first ?? 'Unknown';
      dateCounts[d] = (dateCounts[d] ?? 0) + 1;
    }
    var sortedDates = dateCounts.keys.toList()..sort();
    var last7Dates = sortedDates.reversed.take(7).toList()..sort();
    List<MapEntry<String, int>> tripVolData = last7Dates
        .map((d) => MapEntry(d.substring(5), dateCounts[d]!))
        .toList();

    Map<String, int> routeCounts = {};
    for (var t in fTrips) {
      String r = t['route_name'] ?? 'Unknown Route';
      routeCounts[r] = (routeCounts[r] ?? 0) + 1;
    }
    var sortedRoutes = routeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, int>> topRoutesData = sortedRoutes.take(5).toList();

    Map<String, int> maintCounts = {};
    for (var m in fMaint) {
      String c = m['category'] ?? 'General';
      maintCounts[c] = (maintCounts[c] ?? 0) + 1;
    }
    var sortedMaint = maintCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, int>> maintData = sortedMaint.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Executive Operations Dashboard",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeFrame,
                    dropdownColor: cardBg,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _timeOptions
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _timeFrame = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildKpiCard(
                'Total Distance',
                '${totalDist.toStringAsFixed(0)} km',
                Icons.route,
                const Color(0xFF3B82F6),
                isDark,
              ),
              _buildKpiCard(
                'Passengers Received',
                totalPax.toString(),
                Icons.people,
                const Color(0xFF8B5CF6),
                isDark,
              ),
              _buildKpiCard(
                'Fleet Readiness',
                '$readyV / ${widget.vehicles.length}',
                Icons.check_circle,
                const Color(0xFF10B981),
                isDark,
              ),
              _buildKpiCard(
                'Average CSAT',
                '${csat.toStringAsFixed(1)} ★',
                Icons.star,
                const Color(0xFFF59E0B),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;
              return Column(
                children: [
                  if (isMobile) ...[
                    _buildVerticalBarChart(
                      'Trip Volume History (Active Days)',
                      tripVolData,
                      const Color(0xFF3B82F6),
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildRiskDistributionBar(widget.vehicles, isDark),
                    const SizedBox(height: 16),
                    _buildHorizontalBarChart(
                      'High-Demand Routes',
                      topRoutesData,
                      const Color(0xFF8B5CF6),
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildHorizontalBarChart(
                      'Maintenance Categories',
                      maintData,
                      const Color(0xFFEF4444),
                      isDark,
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildVerticalBarChart(
                            'Trip Volume History',
                            tripVolData,
                            const Color(0xFF3B82F6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildRiskDistributionBar(
                            widget.vehicles,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildHorizontalBarChart(
                            'High-Demand Routes',
                            topRoutesData,
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHorizontalBarChart(
                            'Maintenance by Category',
                            maintData,
                            const Color(0xFFEF4444),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBarChart(
    String title,
    List<MapEntry<String, int>> data,
    Color color,
    bool isDark,
  ) {
    int maxVal = data.isEmpty ? 1 : data.map((e) => e.value).reduce(max);
    return Container(
      padding: const EdgeInsets.all(16),
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      "No data for this timeframe",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((e) {
                      double fillHeight = e.value / maxVal;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            e.value.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Container(
                              width: 24,
                              alignment: Alignment.bottomCenter,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                heightFactor: fillHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionBar(List<dynamic> vehicles, bool isDark) {
    int optimal = 0, fair = 0, risk = 0, maint = 0;
    for (var v in vehicles) {
      double daysRemaining = (v['live_risk_score'] as num?)?.toDouble() ?? 0.0;
      String dbStatus = (v['health_status'] ?? '').toString().toLowerCase();
      if (dbStatus.contains('maintenance') ||
          dbStatus.contains('repair') ||
          daysRemaining <= 7.0) {
        maint++;
      } else if (daysRemaining <= 30.0) {
        risk++;
      } else if (daysRemaining <= 90.0) {
        fair++;
      } else {
        optimal++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Forecasted Maintenance Cycle Distribution",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  if (optimal > 0)
                    Expanded(
                      flex: optimal,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (fair > 0)
                    Expanded(
                      flex: fair,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (risk > 0)
                    Expanded(
                      flex: risk,
                      child: Container(color: const Color(0xFFF97316)),
                    ),
                  if (maint > 0)
                    Expanded(
                      flex: maint,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _legendItem(
                'Optimal (>90d)',
                optimal,
                const Color(0xFF10B981),
                isDark,
              ),
              _legendItem('Fair (<90d)', fair, const Color(0xFFF59E0B), isDark),
              _legendItem(
                'High Risk (<30d)',
                risk,
                const Color(0xFFF97316),
                isDark,
              ),
              _legendItem(
                'Critical (<7d)',
                maint,
                const Color(0xFFEF4444),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color c, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "$label ($count)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBarChart(
    String title,
    List<MapEntry<String, int>> data,
    Color color,
    bool isDark,
  ) {
    int maxVal = data.isEmpty ? 1 : data.map((e) => e.value).reduce(max);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No records available.",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...data.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          e.value.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / maxVal,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
