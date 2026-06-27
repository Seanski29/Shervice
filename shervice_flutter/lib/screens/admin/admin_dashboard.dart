import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalDrivers = 0;
  int activeVehicles = 0;
  double averagePunctuality = 5.0;
  int maintenanceAlerts = 0;
  List<dynamic> maintenanceLogs = [];
  List<dynamic> _companyTripsData = []; // State array linked to dynamic block
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLiveDashboardData();
  }

  // Helper method to procedurally style alternating client tracks
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

  Future<void> fetchLiveDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/dashboard/metrics'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final metrics = data['metrics'];
          setState(() {
            totalDrivers = metrics['totalDrivers'] ?? 0;
            activeVehicles = metrics['activeVehicles'] ?? 0;
            averagePunctuality = (metrics['averagePunctuality'] ?? 5.0).toDouble();
            maintenanceAlerts = metrics['maintenanceAlerts'] ?? 0;
            maintenanceLogs = data['alerts'] ?? [];
            // Extracts client metrics data if delivered alongside summary parameters
            _companyTripsData = data['company_weekly_metrics'] ?? [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed loading network telemetry profiles.');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Could not sync data. Check if your Flask server is running on Port 5000.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double paddingTotal = 32.0;
        double dynamicWidth;

        if (constraints.maxWidth > 1200) {
          dynamicWidth = (constraints.maxWidth - (paddingTotal + 48)) / 4;
        } else if (constraints.maxWidth > 640) {
          dynamicWidth = (constraints.maxWidth - (paddingTotal + 16)) / 2;
        } else {
          dynamicWidth = constraints.maxWidth - paddingTotal;
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

            const Text(
              'Fleet Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                _KpiCard(width: dynamicWidth, title: 'Active Drivers', value: totalDrivers.toString(), subtitle: 'Registered profiles', icon: Icons.people, iconColor: Colors.blue),
                _KpiCard(width: dynamicWidth, title: 'Active Vehicles', value: activeVehicles.toString(), subtitle: 'Status: Good', icon: Icons.directions_car, iconColor: Colors.green),
                _KpiCard(width: dynamicWidth, title: 'Avg Punctuality', value: averagePunctuality.toString(), subtitle: 'Out of 5.0 rating', icon: Icons.star, iconColor: Colors.orange),
                _KpiCard(width: dynamicWidth, title: 'Maintenance Alerts', value: maintenanceAlerts.toString(), subtitle: 'Status: Maintenance', icon: Icons.warning_rounded, iconColor: Colors.red),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Recent Vehicle Maintenance Logs',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Live Database Stream',
                          style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  maintenanceLogs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              "No active maintenance alerts logged in the system.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        )
                      : Column(
                          children: maintenanceLogs.map<Widget>((log) {
                            return _MaintenanceAlertItem(
                              vehicleId: log['plate_number'] ?? 'Unknown Asset',
                              issuePredicted: log['description'] ?? 'Scheduled Checkup',
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // TRIPS DONE PER COMPANY (DYNAMICALLY FETCHED SECTION)
            Container(
              width: double.infinity,
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
                        'Weekly Passenger Trips by Client',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      if (_companyTripsData.isEmpty)
                        Text(
                          'No live data',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _companyTripsData.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No active client records retrieved.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _companyTripsData.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 24, 
                            thickness: 1, 
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final item = _companyTripsData[index];
                            final String name = item['company_name'] ?? 'Unknown Client';
                            final int counts = int.tryParse(item['trip_count']?.toString() ?? '0') ?? 0;
                            final double utilValue = double.tryParse(item['utilization']?.toString() ?? '0.0') ?? 0.0;

                            return _CompanyTripItem(
                              companyName: name,
                              tripCount: '$counts Trips',
                              indicatorColor: _proceduralColorAssigner(index),
                              utilization: utilValue.clamp(0.0, 1.0),
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ─────────── SUPPORT WIDGET: KPI RENDER CARD ───────────
class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─────────── SUPPORT WIDGET: MAINTENANCE LIST ITEM ───────────
class _MaintenanceAlertItem extends StatelessWidget {
  final String vehicleId;
  final String issuePredicted;

  const _MaintenanceAlertItem({
    required this.vehicleId,
    required this.issuePredicted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(Icons.build_circle_outlined, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleId, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Issue: $issuePredicted', 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTripItem extends StatelessWidget {
  final String companyName;
  final String tripCount;
  final Color indicatorColor;
  final double utilization;

  const _CompanyTripItem({
    required this.companyName,
    required this.tripCount,
    required this.indicatorColor,
    required this.utilization,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: indicatorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.business, color: indicatorColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: utilization,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tripCount,
            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}