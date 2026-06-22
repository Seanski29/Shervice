import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate safe width configurations across desktop, tablet, and mobile views
        double paddingTotal = 32.0; // Left + Right screen padding bounds
        double dynamicWidth;

        if (constraints.maxWidth > 1200) {
          dynamicWidth = (constraints.maxWidth - (paddingTotal + 48)) / 4; // 4 Columns
        } else if (constraints.maxWidth > 640) {
          dynamicWidth = (constraints.maxWidth - (paddingTotal + 16)) / 2; // 2 Columns
        } else {
          dynamicWidth = constraints.maxWidth - paddingTotal; // 1 Column (Full Width Mobile)
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
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
            
            // Wrap automatically handles grid behavior safely
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                _KpiCard(width: dynamicWidth, title: 'Active Drivers', value: '42', subtitle: 'Out of 59 total', icon: Icons.people, iconColor: Colors.blue),
                _KpiCard(width: dynamicWidth, title: 'Active Vehicles', value: '38', subtitle: 'Currently on route', icon: Icons.directions_car, iconColor: Colors.green),
                _KpiCard(width: dynamicWidth, title: 'Avg Punctuality', value: '4.8', subtitle: 'Out of 5.0 rating', icon: Icons.star, iconColor: Colors.orange),
                _KpiCard(width: dynamicWidth, title: 'Maintenance Alerts', value: '3', subtitle: 'Requires attention', icon: Icons.warning_rounded, iconColor: Colors.red),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Predictive Model Card Wrapper
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
                  // Header section converts cleanly to column layout on tight screens
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Predictive Maintenance Alerts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Linear Regression Active',
                          style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Alert list execution
                  const Column(
                    children: [
                      _MaintenanceAlertItem(vehicleId: 'GT-VAN-014', issuePredicted: 'Brake Pad Wear', daysRemaining: 2, urgencyLevel: 0.9, alertColor: Colors.red),
                      _MaintenanceAlertItem(vehicleId: 'GT-VAN-008', issuePredicted: 'Transmission Fluid', daysRemaining: 5, urgencyLevel: 0.75, alertColor: Colors.orange),
                      _MaintenanceAlertItem(vehicleId: 'GT-VAN-022', issuePredicted: 'Battery Life Depletion', daysRemaining: 12, urgencyLevel: 0.4, alertColor: Colors.amber),
                    ],
                  ),
                ],
              ),
            )
          ],
        );
      }
    );
  }
}

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
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
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

class _MaintenanceAlertItem extends StatelessWidget {
  final String vehicleId;
  final String issuePredicted;
  final int daysRemaining;
  final double urgencyLevel;
  final Color alertColor;

  const _MaintenanceAlertItem({
    required this.vehicleId,
    required this.issuePredicted,
    required this.daysRemaining,
    required this.urgencyLevel,
    required this.alertColor,
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
            decoration: BoxDecoration(color: alertColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(Icons.build_circle_outlined, color: alertColor, size: 20),
          ),
          const SizedBox(width: 12),
          
          // Expanded forces middle strings to occupy relative space rather than overflow bounds
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
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: urgencyLevel,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Trailing alert telemetry statistics
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$daysRemaining Days', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: alertColor),
              ),
              Text(
                'Left', 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}