import 'package:flutter/material.dart';

class AdminFleet extends StatelessWidget {
  const AdminFleet({super.key});

  void _showNewVehicleModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Register New Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Plate Number / ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pin)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Vehicle Model', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Seating Capacity', border: OutlineInputBorder(), prefixIcon: Icon(Icons.group)),
                    items: ['12 Seats', '15 Seats', '18 Seats'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Register Vehicle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            const Text(
              'Fleet Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () => _showNewVehicleModal(context),
              icon: const Icon(Icons.directions_bus, color: Colors.white),
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
        
        _buildVehicleCard(plate: 'GT-VAN-012', model: 'Toyota Hiace Commuter', capacity: '15 Seats', condition: 'Excellent', status: 'Active (On Route)', statusColor: Colors.green),
        _buildVehicleCard(plate: 'GT-VAN-008', model: 'Nissan Urvan NV350', capacity: '15 Seats', condition: 'Good', status: 'Active (On Route)', statusColor: Colors.green),
        _buildVehicleCard(plate: 'GT-VAN-022', model: 'Toyota Hiace GL Grandia', capacity: '12 Seats', condition: 'Needs Maintenance', status: 'Garage', statusColor: Colors.red),

        const SizedBox(height: 16),
        _buildResponsivePagination('1 to 3 of 59 vehicles'),
      ],
    );
  }

  Widget _buildVehicleCard({required String plate, required String model, required String capacity, required String condition, required String status, required Color statusColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, runSpacing: 8,
            children: [
              Text(plate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),
          Wrap(
            spacing: 16, runSpacing: 12,
            children: [
              _iconText(Icons.directions_car_outlined, model),
              _iconText(Icons.group_outlined, capacity),
              _iconText(Icons.build_circle_outlined, 'Condition: $condition'),
            ],
          )
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w500))],
    );
  }

  Widget _buildResponsivePagination(String text) {
    return Wrap(
      alignment: WrapAlignment.end, // Anchored purely to the right
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16, runSpacing: 16,
      children: [
        Text('Showing $text', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Prev', style: TextStyle(color: Colors.black87))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Next', style: TextStyle(color: Colors.black87))),
          ],
        )
      ],
    );
  }
}