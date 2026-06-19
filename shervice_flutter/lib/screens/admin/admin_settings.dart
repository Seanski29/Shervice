import 'package:flutter/material.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'System Configuration',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        
        _buildSettingsSection(
          title: 'Analytics & Machine Learning',
          icon: Icons.auto_graph,
          children: [
            _buildSwitchTile('Enable Predictive Maintenance Alerts', 'Uses Linear Regression on historical vehicle data', true),
            _buildSwitchTile('Automated Driver Scoring', 'Updates punctuality ratings after every completed route', true),
          ],
        ),
        
        const SizedBox(height: 24),
        
        _buildSettingsSection(
          title: 'Notifications & Dispatch',
          icon: Icons.notifications_active_outlined,
          children: [
            _buildSwitchTile('SMS Alerts to Drivers', 'Send text messages when a new route is assigned', false),
            _buildSwitchTile('OIC Email Summaries', 'Send end-of-day fleet status reports to Duty Officers', true),
          ],
        ),

        const SizedBox(height: 24),
        
        _buildSettingsSection(
          title: 'Security',
          icon: Icons.security,
          children: [
            const ListTile(
              title: Text('Change Admin Password', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(height: 1),
            const ListTile(
              title: Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text('Disabled', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildSettingsSection({required String title, required IconData icon, required List<Widget> children}) {
    // Replaced Container with Material to fix the ink splash warning
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      // Clip behavior ensures the ripple effect doesn't bleed outside the rounded corners
      clipBehavior: Clip.antiAlias, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0F172A)),
                const SizedBox(width: 12),
                // Using Expanded so long titles don't cause stripe errors
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
  Widget _buildSwitchTile(String title, String subtitle, bool initialValue) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          value: initialValue,
          activeColor: Colors.blue.shade600,
          onChanged: (bool value) {},
        ),
        const Divider(height: 1),
      ],
    );
  }
}