import 'package:flutter/material.dart';

class AdminDrivers extends StatelessWidget {
  const AdminDrivers({super.key});

  // Modal Function for Adding a Driver
  void _showAddDriverModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Driver', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., Jose Rizal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      hintText: 'e.g., N01-12-345678',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      hintText: 'e.g., 0912 345 6789',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Initial Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.traffic),
                    ),
                    items: ['Available', 'Off Duty', 'Under Review']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Driver', style: TextStyle(color: Colors.white)),
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
              'Driver Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddDriverModal(context),
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
        const SizedBox(height: 16),
        
        // Pagination Component
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Showing 1 to 4 of 59 entries', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Previous', style: TextStyle(color: Colors.black87)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)),
                  child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Next', style: TextStyle(color: Colors.black87)),
                ),
              ],
            )
          ],
        )
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