import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constant.dart';
import 'driver_performance_tab.dart';
import 'fleet_overview_tab.dart';
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
      final driversResponse = await http.get(Uri.parse('$backendUrl/test-db'));
      if (driversResponse.statusCode == 200) {
        final data = jsonDecode(driversResponse.body);
        _allDrivers = data is Map ? data['sample_data_payload'] ?? [] : [];
      }

      final tripsResponse = await http.get(Uri.parse('$backendUrl/trips'));
      if (tripsResponse.statusCode == 200) {
        final data = jsonDecode(tripsResponse.body);
        _allTrips = data is List
            ? data
            : data['trips'] ?? data['sample_data_payload'] ?? [];
      }

      final maintenanceResponse = await http.get(
        Uri.parse('$backendUrl/vehicles/maintenance'),
      );
      if (maintenanceResponse.statusCode == 200) {
        final data = jsonDecode(maintenanceResponse.body);
        _allMaintenanceLogs = data is Map
            ? data['data'] ?? data['logs'] ?? []
            : [];
      }

      final vehiclesResponse = await http.get(
        Uri.parse('$backendUrl/vehicles'),
      );
      if (vehiclesResponse.statusCode == 200) {
        final data = jsonDecode(vehiclesResponse.body);
        final vehicles = data is Map ? data['data'] : null;
        if (vehicles is List) {
          await Future.wait(
            vehicles.whereType<Map>().map((vehicle) async {
              final vehicleId = vehicle['vehicle_id'];
              try {
                final predictionResponse = await http.get(
                  Uri.parse('$backendUrl/vehicles/predict/$vehicleId'),
                );
                if (predictionResponse.statusCode == 200) {
                  final prediction = jsonDecode(predictionResponse.body);
                  vehicle['live_risk_score'] =
                      (prediction['risk_index'] as num?)?.toDouble() ?? 0.0;
                } else {
                  vehicle['live_risk_score'] = 0.0;
                }
              } catch (_) {
                vehicle['live_risk_score'] = 0.0;
              }
            }),
          );
          _allVehicles = vehicles;
        }
      }
    } catch (error) {
      debugPrint('Global analytics request failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManualSync() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/vehicles/predict/fleet-sweep'),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Fleet sync returned ${response.statusCode}');
      }
      await _fetchGlobalAnalyticsPayload();
    } catch (error) {
      debugPrint('Manual fleet sync failed: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark
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
              Text(
                'Intelligence & Analytics Hub',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Evaluate driver feedback, monitor fleet metrics, and execute predictive diagnostics.',
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),
              const SizedBox(height: 16),
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
                      Icons.memory,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                          ),
                          DriverPerformanceTab(
                            drivers: _allDrivers,
                            backendUrl: backendUrl,
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
    final isActive = _activeTab == index;
    final activeBackground = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inactiveText = isDark
        ? Colors.grey.shade500
        : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
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
