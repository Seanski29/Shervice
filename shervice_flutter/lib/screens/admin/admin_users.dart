import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_feedbacks.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  void _showNewUserModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (BuildContext context) {
        return const RegisterUserDialog();
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
              'User Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFeedbacks(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.forum_outlined, size: 20),
                  label: const Text(
                    'View Feedbacks',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade600),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewUserModal(context),
                  icon: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Register User',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Admin
        _buildUserCard(
          name: 'System Admin',
          email: 'admin@gtlantin.com',
          role: 'Administrator',
          company: 'GT Lantin Internal',
          permission: 'Full Access',
          status: 'Active',
          statusColor: Colors.green,
        ),

        // Dispatch Staff
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'DISPATCH STAFF',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildUserCard(
          name: 'Mark Reyes',
          email: 'staff.epson@gtlantin.com',
          role: 'Dispatch Staff',
          company: 'EPSON Account',
          permission: 'Logistics Only',
          status: 'Active',
          statusColor: Colors.green,
        ),
        _buildUserCard(
          name: 'Sarah Lim',
          email: 'staff.bandai@gtlantin.com',
          role: 'Dispatch Staff',
          company: 'Bandai Account',
          permission: 'Logistics Only',
          status: 'Active',
          statusColor: Colors.green,
        ),
        _buildUserCard(
          name: 'John Torres',
          email: 'staff.nx@gtlantin.com',
          role: 'Dispatch Staff',
          company: 'NX Logistics Account',
          permission: 'Logistics Only',
          status: 'Active',
          statusColor: Colors.green,
        ),

        // Officers in Charge
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'CLIENT OFFICERS (OIC)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildUserCard(
          name: 'Elena Cruz',
          email: 'elena.cruz@epson.com',
          role: 'Officer-in-Charge',
          company: 'EPSON',
          permission: 'Schedules & Feedback',
          status: 'Active',
          statusColor: Colors.blue,
        ),
        _buildUserCard(
          name: 'Kenji Sato',
          email: 'k.sato@bandai.com',
          role: 'Officer-in-Charge',
          company: 'Bandai',
          permission: 'Schedules & Feedback',
          status: 'Active',
          statusColor: Colors.blue,
        ),
        _buildUserCard(
          name: 'Maria Santos',
          email: 'msantos@nxlogistics.com',
          role: 'Officer-in-Charge',
          company: 'NX Logistics',
          permission: 'Schedules & Feedback',
          status: 'Offline',
          statusColor: Colors.grey,
        ),

        const SizedBox(height: 16),
        _buildResponsivePagination('1 to 7 of 15 system users'),
      ],
    );
  }

  Widget _buildUserCard({
    required String name,
    required String email,
    required String role,
    required String company,
    required String permission,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _iconText(Icons.business, company),
              _iconText(Icons.email_outlined, email),
              _iconText(Icons.admin_panel_settings_outlined, role),
              _iconText(Icons.verified_user_outlined, permission),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildResponsivePagination(String text) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Text(
          'Showing $text',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Prev',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── NEW STATEFUL WIDGET FOR THE MODAL ───
class RegisterUserDialog extends StatefulWidget {
  const RegisterUserDialog({super.key});

  @override
  State<RegisterUserDialog> createState() => _RegisterUserDialogState();
}

class _RegisterUserDialogState extends State<RegisterUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  String? _selectedCompany;
  bool _isLoading = false;

  // Centralized local network gateway
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/auth/register-staff-oic'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'role': _selectedRole,
              'company_name': _selectedCompany ?? 'None (Internal)',
              'full_name': _nameController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context); // Close the modal
        _showSnackBar(
          "User registered securely in the Auth Vault!",
          Colors.green,
        );
      } else {
        _showSnackBar(
          responseData['message'] ?? "Registration failed.",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Network error: Could not reach backend server.",
        Colors.red,
      );
      debugPrint("❌ OIC/Staff Registration Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Register System User',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  validator: (val) => val == null || !val.contains('@')
                      ? "Enter a valid email"
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── NEW SECURE PASSWORD FIELD ───
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6
                      ? "Minimum 6 characters"
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Secure Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  validator: (val) => val == null ? "Select a role" : null,
                  decoration: const InputDecoration(
                    labelText: 'Assign Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items:
                      ['Administrator', 'Dispatch Staff', 'Officer-in-Charge']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Assign Company Account',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: ['None (Internal)', 'EPSON', 'Bandai', 'NX Logistics']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCompany = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _registerUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Register User',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
