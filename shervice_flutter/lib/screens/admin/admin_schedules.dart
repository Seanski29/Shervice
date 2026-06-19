import 'package:flutter/material.dart';

class AdminSchedules extends StatelessWidget {
  const AdminSchedules({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // FIX: Replaced Row with Wrap to prevent header overflow
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16, // This drops the button down gracefully on mobile
          children: [
            const Text(
              'Active Routes & Schedules',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Hardcoded List of Active Routes
        _buildRouteCard(
          client: 'LIMA Estate (EPSON)',
          time: '06:00 AM - Shift 1',
          driver: 'Ricardo Ramos',
          vehicle: 'GT-VAN-012 (Toyota Hiace)',
          status: 'In Transit',
          statusColor: Colors.blue,
        ),
        _buildRouteCard(
          client: 'Malvar (Bandai Namco)',
          time: '06:30 AM - Shift 1',
          driver: 'Juan Dela Cruz',
          vehicle: 'GT-VAN-008 (Nissan Urvan)',
          status: 'Departed',
          statusColor: Colors.green,
        ),
        _buildRouteCard(
          client: 'FPIP (NX Logistics)',
          time: '02:00 PM - Shift 2',
          driver: 'Miguel Santos',
          vehicle: 'GT-VAN-022 (Toyota Hiace)',
          status: 'Scheduled',
          statusColor: Colors.orange,
        ),
      ],
    );
  }

Widget _buildRouteCard({
    required String client,
    required String time,
    required String driver,
    required String vehicle,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Using Wrap here so the Client Name and Status Badge don't overflow
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(client, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Using Wrap here fixes the horizontal overflow stripes!
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(driver, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(vehicle, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}