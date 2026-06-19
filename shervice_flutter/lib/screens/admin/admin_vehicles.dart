import 'package:flutter/material.dart';

class AdminVehicles extends StatelessWidget {
  const AdminVehicles({super.key});

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
              'Fleet Health & Maintenance',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Register Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              columns: const [
                DataColumn(label: Text('UNIT ID')),
                DataColumn(label: Text('MODEL / PLATE')),
                DataColumn(label: Text('MILEAGE')),
                DataColumn(label: Text('ML HEALTH SCORE')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: [
                _buildVehicleRow('GT-VAN-012', 'Toyota Hiace (ABC-1234)', '45,200 km', 0.95, Colors.green, 'Operational'),
                _buildVehicleRow('GT-VAN-008', 'Nissan Urvan (XYZ-9876)', '82,100 km', 0.60, Colors.orange, 'Warning'),
                _buildVehicleRow('GT-VAN-014', 'Toyota Commuter (DEF-5678)', '110,500 km', 0.15, Colors.red, 'Maintenance Required'),
                _buildVehicleRow('GT-VAN-022', 'Toyota Hiace (GHI-9012)', '15,000 km', 0.99, Colors.green, 'Operational'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildVehicleRow(String id, String model, String mileage, double health, Color healthColor, String status) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(model)),
        DataCell(Text(mileage, style: TextStyle(color: Colors.grey.shade600))),
        DataCell(
          Row(
            children: [
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: health,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(health * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: healthColor)),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: healthColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: healthColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}