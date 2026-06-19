import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // A scrollable ListView prevents the hazard tape overflow error on mobile screens
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Fleet Overview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        
        // 1. Top KPI Cards
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: const [
            _KpiCard(title: 'Active Drivers', value: '42', subtitle: 'Out of 59 total', icon: Icons.people, iconColor: Colors.blue),
            _KpiCard(title: 'Active Vehicles', value: '38', subtitle: 'Currently on route', icon: Icons.directions_car, iconColor: Colors.green),
            _KpiCard(title: 'Avg Punctuality', value: '4.8', subtitle: 'Out of 5.0 rating', icon: Icons.star, iconColor: Colors.orange),
            _KpiCard(title: 'Maintenance Alerts', value: '3', subtitle: 'Requires attention', icon: Icons.warning_rounded, iconColor: Colors.red),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 2. Predictive Maintenance Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Predictive Maintenance Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Linear Regression Model Active',
                      style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // The Hardcoded List of Alerts
              const Column(
                children: [
                  _MaintenanceAlertItem(
                    vehicleId: 'GT-VAN-014',
                    issuePredicted: 'Brake Pad Wear',
                    daysRemaining: 2,
                    urgencyLevel: 0.9, // 90% worn out
                    alertColor: Colors.red,
                  ),
                  _MaintenanceAlertItem(
                    vehicleId: 'GT-VAN-008',
                    issuePredicted: 'Transmission Fluid Degradation',
                    daysRemaining: 5,
                    urgencyLevel: 0.75, // 75% worn out
                    alertColor: Colors.orange,
                  ),
                  _MaintenanceAlertItem(
                    vehicleId: 'GT-VAN-022',
                    issuePredicted: 'Battery Life Depletion',
                    daysRemaining: 12,
                    urgencyLevel: 0.4, // 40% worn out
                    alertColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// CUSTOM WIDGET: Maintenance Alert Item
// ---------------------------------------------------------
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.build_circle_outlined, color: alertColor, size: 28),
          ),
          const SizedBox(width: 16),
          
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Predicted Issue: $issuePredicted',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Visual Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: urgencyLevel,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Remaining Days Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$daysRemaining Days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: alertColor,
                ),
              ),
              Text(
                'Est. Remaining',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM WIDGET: KPI Card 
// ---------------------------------------------------------
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}