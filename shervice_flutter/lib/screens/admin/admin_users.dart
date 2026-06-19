import 'package:flutter/material.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User & Role Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Invite User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                DataColumn(label: Text('EMPLOYEE')),
                DataColumn(label: Text('EMAIL ADDRESS')),
                DataColumn(label: Text('SYSTEM ROLE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: [
                _buildUserRow('Admin User', 'admin@gtlantin.com', 'System Admin', Colors.deepPurple, 'Active', Colors.green),
                _buildUserRow('Duty Officer', 'oic@gtlantin.com', 'OIC Dispatch', Colors.blue, 'Active', Colors.green),
                _buildUserRow('Sean Dela Cruz', 'sean.staff@gtlantin.com', 'Staff User', Colors.orange, 'Offline', Colors.grey),
                _buildUserRow('Maria Santos', 'maria.hr@gtlantin.com', 'HR Viewer', Colors.teal, 'Pending', Colors.amber),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildUserRow(String name, String email, String role, Color roleColor, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(email, style: TextStyle(color: Colors.grey.shade600))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(role, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        DataCell(
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
        ),
      ],
    );
  }
}