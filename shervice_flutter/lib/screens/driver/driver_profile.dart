import 'package:flutter/material.dart';

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text(
          'Profile & Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 24),

        // Profile Header
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  'RR', // Initials
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Ricardo Ramos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Driver ID: DRV-001', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Account Settings Group
        const Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF0F172A)),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  // Add your Change Password modal/navigation here later
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
                title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFF0F172A)),
                title: const Text('Support & Help', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // System Actions Group
        const Text('SYSTEM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Add your logout logic here later
            },
          ),
        ),
      ],
    );
  }
}