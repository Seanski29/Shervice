import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';

// Your Global Constants
import '../../../constant.dart';

// The separated local tab files
import 'fleet_overview_tab.dart';
import 'driver_performance_tab.dart';
import 'vehicle_ml_tab.dart';

class SharedAnalyticsHub extends StatefulWidget {
  const SharedAnalyticsHub({super.key});

  @override
  State<SharedAnalyticsHub> createState() => _SharedAnalyticsHubState();
}

class _SharedAnalyticsHubState extends State<SharedAnalyticsHub> {
  int _activeTab = 0;
  bool _isLoading = true;

  List<dynamic> _allDrivers = [];
  List<dynamic> _allVehicles = [];
  List<dynamic> _allTrips = [];
  List<dynamic> _allMaintenanceLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchGlobalAnalyticsPayload();
  }

  Future<void> _fetchGlobalAnalyticsPayload() async {
    try {
      // 1. Fetch Drivers (Sequential fetch to prevent crashing Flask)
      final dRes = await http.get(Uri.parse('$backendUrl/test-db'));
      if (dRes.statusCode == 200) {
        List<dynamic> drivers =
            jsonDecode(dRes.body)['sample_data_payload'] ?? [];
        for (var d in drivers) {
          final String dId = (d['user_id'] ?? d['id'] ?? '').toString();
          if (dId.isNotEmpty) {
            try {
              final String cacheBuster = DateTime.now().millisecondsSinceEpoch
                  .toString();
              final mlRes = await http.get(
                Uri.parse('$backendUrl/drivers/classify/$dId?cb=$cacheBuster'),
              );
              if (mlRes.statusCode == 200) {
                d['ml_classification'] =
                    jsonDecode(mlRes.body)['classification'] ??
                    'Insufficient Data';
              } else {
                d['ml_classification'] = 'Unavailable';
              }
            } catch (_) {
              d['ml_classification'] = 'Unavailable';
            }
          }
        }
        _allDrivers = drivers;
      }

      // 2. Fetch Trips
      final tRes = await http.get(Uri.parse('$backendUrl/trips'));
      if (tRes.statusCode == 200) {
        final tData = jsonDecode(tRes.body);
        _allTrips = tData is List
            ? tData
            : (tData['trips'] ?? tData['sample_data_payload'] ?? []);
      }

      // 3. Fetch Maintenance Logs
      final mRes = await http.get(
        Uri.parse('$backendUrl/vehicles/maintenance'),
      );
      if (mRes.statusCode == 200) {
        final mData = jsonDecode(mRes.body);
        _allMaintenanceLogs = mData['data'] ?? mData['logs'] ?? [];
      }

      // 4. Fetch Vehicles (Read DB risk score instead of pinging ML endpoint again)
      final vRes = await http.get(Uri.parse('$backendUrl/vehicles'));
      if (vRes.statusCode == 200) {
        List<dynamic> vehicles = jsonDecode(vRes.body)['data'] ?? [];
        for (var v in vehicles) {
          v['live_risk_score'] = (v['risk_score'] as num?)?.toDouble() ?? 0.0;
        }
        _allVehicles = vehicles;
      }
    } catch (e) {
      debugPrint("Global Analytics Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManualSync() async {
    setState(() => _isLoading = true);
    try {
      await http.post(Uri.parse('$backendUrl/vehicles/predict/fleet-sweep'));
      await _fetchGlobalAnalyticsPayload();
    } catch (e) {
      debugPrint("Manual sweep failed: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark
        ? Colors.grey.shade400
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Skeletonizer(
        enabled: _isLoading,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── UNIVERSAL HEADER WITH MASTER SYNC ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics Hub',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evaluate granular driver feedback logs, monitor live fleet metrics, and execute predictive ML diagnostics.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleManualSync,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.memory,
                            size: 18,
                            color: Colors.white,
                          ),
                    label: const Text(
                      "Run AI Sweep",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 3-TAB NAVIGATOR ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(color: Colors.grey.shade800)
                      : null,
                ),
                child: Row(
                  children: [
                    _buildNavTab(0, 'Fleet Overview', Icons.dashboard, isDark),
                    _buildNavTab(1, 'Driver Performance', Icons.person, isDark),
                    _buildNavTab(
                      2,
                      'Vehicle Predictive ML',
                      Icons.directions_bus,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── FAST RENDERING TABS ──
              Expanded(
                child: _isLoading && _allVehicles.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _activeTab,
                        children: [
                          FleetOverviewTab(
                            vehicles: _allVehicles,
                            drivers: _allDrivers,
                            trips: _allTrips,
                            maintenanceLogs: _allMaintenanceLogs,
                            onSyncAction: _handleManualSync,
                          ),
                          DriverPerformanceTab(
                            drivers: _allDrivers,
                            backendUrl: backendUrl,
                            onSyncAction: _handleManualSync,
                          ),
                          VehicleMlTab(
                            vehicles: _allVehicles,
                            backendUrl: backendUrl,
                            onSyncAction: _handleManualSync,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, String label, IconData icon, bool isDark) {
    final bool isActive = _activeTab == index;
    final Color activeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color inactiveText = isDark
        ? Colors.grey.shade500
        : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
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
}
