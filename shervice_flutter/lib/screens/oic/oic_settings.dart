import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class OicSettings extends StatefulWidget {
  final String oicId;
  final String oicName;
  final String companyName;
  final String? email; // Optional: Pass the real email if you have it!

  const OicSettings({
    super.key,
    required this.oicId,
    required this.oicName,
    required this.companyName,
    this.email,
  });

  @override
  State<OicSettings> createState() => _OicSettingsState();
}

class _OicSettingsState extends State<OicSettings> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // Generate a fallback email if one wasn't provided
    final String displayEmail = widget.email ?? 
        "${widget.oicName.split(' ').first.toLowerCase()}@${widget.companyName.replaceAll(' ', '').toLowerCase()}.com";

    // Get the first initial for the avatar
    final String initial = widget.oicName.isNotEmpty ? widget.oicName[0].toUpperCase() : 'O';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── RESPONSIVE HEADER ───
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your profile, security, and portal preferences.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── PROFILE CARD ───
            const Text(
              'MY PROFILE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.oicName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                displayEmail,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: Colors.blue.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.companyName,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── PREFERENCES & FEATURES (COMING SOON) ───
            const Text(
              'PREFERENCES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account security credentials.',
                    iconColor: Colors.orange,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildSettingsTile(
                    icon: Icons.notifications_none,
                    title: 'Notification Preferences',
                    subtitle: 'Manage email and push alerts for trips.',
                    iconColor: Colors.green,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildSettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'App Theme',
                    subtitle: 'Switch between Light and Dark mode.',
                    iconColor: Colors.purple,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: 'Language & Region',
                    subtitle: 'Customize your local portal experience.',
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGET FOR SETTINGS TILES ───
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      onTap: () {
        // Feature coming soon - could show a snackbar here if you wanted!
      },
    );
  }
}