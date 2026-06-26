import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_feedbacks.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  bool _isLoading = true;
  
  // Categorized Data Lists
  List<dynamic> _adminUsers = [];
  List<dynamic> _staffUsers = [];
  List<dynamic> _oicUsers = [];

  // Centralized local network gateway
  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchSystemUsers();
  }

  Future<void> _fetchSystemUsers() async {
    setState(() => _isLoading = true);

    try {
      // CACHE BUSTER: Prevents Flutter Web from aggressively caching the JSON response
      final String fetchUrl = '$_backendUrl/users/system-users?v=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Assuming your backend returns a list in "data" or "sample_data_payload"
        final List<dynamic> allUsers = data['data'] ?? data['sample_data_payload'] ?? [];

        setState(() {
          // Dynamically categorize based on the role string returned from the database
          _adminUsers = allUsers.where((u) => 
            u['role'].toString().toLowerCase() == 'admin' || 
            u['role'].toString().toLowerCase() == 'administrator'
          ).toList();
          
          _staffUsers = allUsers.where((u) => 
            u['role'].toString().toLowerCase() == 'staff' || 
            u['role'].toString().toLowerCase() == 'dispatch staff'
          ).toList();
          
          _oicUsers = allUsers.where((u) => 
            u['role'].toString().toLowerCase() == 'oic' || 
            u['role'].toString().toLowerCase() == 'officer-in-charge'
          ).toList();
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load users from database.', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Network error: Could not reach backend server.', Colors.red);
      debugPrint("❌ User Fetch Error: $e");
    }
  }

  void _showNewUserModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (BuildContext context) {
        return RegisterUserDialog(onUserRegistered: _fetchSystemUsers);
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalUsers = _adminUsers.length + _staffUsers.length + _oicUsers.length;

    return _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- HEADER ---
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFeedbacks()));
                      },
                      icon: const Icon(Icons.forum_outlined, size: 20),
                      label: const Text('View Feedbacks', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade600),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showNewUserModal(context),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                      label: const Text('Register User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- SYSTEM ADMINS DYNAMIC LIST ---
            if (_adminUsers.isNotEmpty) ...[
              _buildSectionHeader('SYSTEM ADMINISTRATORS'),
              ..._adminUsers.map((user) => _buildUserCard(
                    name: user['full_name'] ?? user['username'] ?? 'Unknown Admin',
                    email: user['username'] ?? 'No Email',
                    role: 'Administrator',
                    company: user['company_name'] ?? 'GT Lantin Internal',
                    permission: 'Full Access',
                    status: user['status'] ?? 'Active',
                    statusColor: Colors.green,
                  )),
            ],

            // --- DISPATCH STAFF DYNAMIC LIST ---
            if (_staffUsers.isNotEmpty) ...[
              _buildSectionHeader('DISPATCH STAFF'),
              ..._staffUsers.map((user) => _buildUserCard(
                    name: user['full_name'] ?? user['username'] ?? 'Unknown Staff',
                    email: user['username'] ?? 'No Email Provided',
                    role: 'Dispatch Staff',
                    company: user['company_name'] ?? 'Assigned Account',
                    permission: 'Logistics Only',
                    status: user['status'] ?? 'Active',
                    statusColor: Colors.green,
                  )),
            ],

            // --- OIC DYNAMIC LIST ---
            if (_oicUsers.isNotEmpty) ...[
              _buildSectionHeader('CLIENT OFFICERS (OIC)'),
              ..._oicUsers.map((user) => _buildUserCard(
                    name: user['full_name'] ?? user['username'] ?? 'Unknown OIC',
                    email: user['username'] ?? 'No Email Provided',
                    role: 'Officer-in-Charge',
                    company: user['company_name'] ?? 'Client Company',
                    permission: 'Schedules & Feedback',
                    status: user['status'] ?? 'Active',
                    statusColor: Colors.blue,
                  )),
            ],

            // Empty State Handling
            if (_adminUsers.isEmpty && _staffUsers.isEmpty && _oicUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No system users found in the database.", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            _buildResponsivePagination('1 to $totalUsers of $totalUsers system users'),
          ],
        );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
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
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Prev', style: TextStyle(color: Colors.black87))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Next', style: TextStyle(color: Colors.black87))),
          ],
        ),
      ],
    );
  }
}

// ─── REGISTER USER MODAL ───
class RegisterUserDialog extends StatefulWidget {
  final VoidCallback onUserRegistered; // Callback to refresh UI after success

  const RegisterUserDialog({super.key, required this.onUserRegistered});

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
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/register-staff-oic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
          'company_name': _selectedCompany ?? 'None (Internal)',
          'full_name': _nameController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context); // Close the modal
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User registered securely!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        
        // Trigger the parent refresh to paint the new user immediately!
        widget.onUserRegistered(); 
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'] ?? "Registration failed."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network error: Could not reach backend server."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      title: const Text('Register System User', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  validator: (val) => val == null || !val.contains('@') ? "Enter a valid email" : null,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6 ? "Minimum 6 characters" : null,
                  decoration: const InputDecoration(labelText: 'Secure Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  validator: (val) => val == null ? "Select a role" : null,
                  decoration: const InputDecoration(labelText: 'Assign Role', border: OutlineInputBorder(), prefixIcon: Icon(Icons.admin_panel_settings)),
                  items: ['Administrator', 'Dispatch Staff', 'Officer-in-Charge'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Assign Company Account', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                  items: ['None (Internal)', 'EPSON', 'Bandai', 'NX Logistics'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _selectedCompany = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: _isLoading ? null : _registerUser,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Register User', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}