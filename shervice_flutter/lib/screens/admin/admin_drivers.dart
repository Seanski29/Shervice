import 'package:flutter/material.dart';

class AdminDrivers extends StatelessWidget {
  const AdminDrivers({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // FIX: Swapped Row for Wrap to prevent header overflow on mobile
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            const Text(
              'Driver Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          // SingleChildScrollView ensures the wide table scrolls left/right instead of overflowing
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              columns: const [
                DataColumn(label: Text('DRIVER ID')),
                DataColumn(label: Text('FULL NAME')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('PUNCTUALITY RATING')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: [
                _buildDriverRow('DRV-001', 'Ricardo Ramos', 'On Route', 4.9, Colors.green),
                _buildDriverRow('DRV-002', 'Juan Dela Cruz', 'Available', 4.5, Colors.blue),
                _buildDriverRow('DRV-003', 'Miguel Santos', 'Off Duty', 4.8, Colors.grey),
                _buildDriverRow('DRV-004', 'Carlos Mendoza', 'Under Review', 3.2, Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDriverRow(String id, String name, String status, double rating, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(name)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber.shade400, size: 18),
              const SizedBox(width: 4),
              Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        DataCell(
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
        ),
      ],
    );
  }
}