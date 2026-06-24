import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StaffDrivers extends StatefulWidget {
  const StaffDrivers({super.key});

  @override
  State<StaffDrivers> createState() => _StaffDriverState();
}

class _StaffDriverState extends State<StaffDrivers> {
  // Central network routing gateway matching your running Flask server configuration
  String get _backendRegisterUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/auth/register-driver';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/auth/register-driver'
        : 'http://127.0.0.1:5000/api/auth/register-driver';
  }

  // Diagnostic path used to dynamically pull down all active database rows
  String get _backendFetchUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/test-db';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/test-db'
        : 'http://127.0.0.1:5000/api/test-db';
  }

  /// Dispatches a GET request to the Flask server to retrieve live data rows
  Future<List<dynamic>> _fetchDriversFromDatabase() async {
    try {
      final response = await http
          .get(Uri.parse(_backendFetchUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['connection_status'] == 'SUCCESS') {
          return data['sample_data_payload'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error reading live driver profile streams: $e");
      return [];
    }
  }

  void _showNewDriverModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final licenseController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Register New Driver',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Field required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.card_membership),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Field required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Account Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Field required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Account Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be >= 6 chars'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final DateTime now = DateTime.now();
                    final String formattedDateHired =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                    final response = await http
                        .post(
                          Uri.parse(_backendRegisterUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'email': emailController.text.trim(),
                            'password': passwordController.text,
                            'full_name': nameController.text.trim(),
                            'license_no': licenseController.text.trim(),
                            'birthday': '1995-05-15',
                            'license_expiry': '2031-12-31',
                            'date_hired': formattedDateHired,
                          }),
                        )
                        .timeout(const Duration(seconds: 10));

                    if (!context.mounted) return;
                    Navigator.pop(context); // Pop loader safely

                    final responseData = jsonDecode(response.body);

                    if (response.statusCode == 201 ||
                        responseData['success'] == true) {
                      Navigator.pop(context); // Dismiss alert modal
                      _showSnackBar(
                        'Driver registered securely in live system database!',
                        Colors.green,
                      );

                      // CRITICAL: Forces the UI page state to reload and paint the new driver immediately
                      setState(() {});
                    } else {
                      final serverMsg =
                          responseData['message'] ?? 'Registration rejected.';
                      _showSnackBar('Server Error: $serverMsg', Colors.red);
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    _showSnackBar(
                      'Network Failure: Cannot connect to Python backend.',
                      Colors.red,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Register Driver',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row Component
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text(
                'Driver Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewDriverModal(context),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'Add Driver',
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
          const SizedBox(height: 24),

          // Dynamic Database Future Pipeline Container
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchDriversFromDatabase(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active drivers connected in database.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final drivers = snapshot.data!;

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return _buildDriverCard(
                      context: context,
                      name: driver['full_name'] ?? 'Unnamed Driver',
                      rating:
                          '5.0', // Standard baseline default rating for presentation
                      driverId: 'DRV-${driver['driver_id']}',
                      license: driver['license_no'] ?? 'No License Records',
                      status: driver['employment_status'] ?? 'Active',
                      statusColor: (driver['employment_status'] == 'Active')
                          ? Colors.green
                          : Colors.orange,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard({
    required BuildContext context,
    required String name,
    required String rating,
    required String driverId,
    required String license,
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
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
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
              _iconText(Icons.badge_outlined, 'ID: $driverId'),
              _iconText(Icons.card_membership, 'License: $license'),
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
}
