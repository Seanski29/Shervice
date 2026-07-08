import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';
import '../../widgets/driver_rating_badge.dart';

class DriverProfile extends StatefulWidget {
  final String driverName;
  final String driverId;

  const DriverProfile({
    super.key,
    required this.driverName,
    required this.driverId,
  });

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLinkingFacebook = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchPersonalDriverProfile();
  }

  /// Queries the database using the logged-in name framework context
  Future<void> _fetchPersonalDriverProfile() async {
    try {
      // Endpoint retrieves full record data by matching full_name text criteria
      final response = await http
          .get(Uri.parse('$backendUrl/test-db'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['connection_status'] == 'SUCCESS') {
          final List<dynamic> profiles = data['sample_data_payload'] ?? [];

          // Match the active profile in the dataset array
          final matchingRow = profiles.firstWhere(
            (p) =>
                p['full_name'].toString().trim().toLowerCase() ==
                widget.driverName.trim().toLowerCase(),
            orElse: () => null,
          );

          setState(() {
            _profileData = matchingRow;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("❌ Profile loader intercept mismatch anomaly: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Pushes password changes directly to the driver's local directory rows
  /// Pushes password changes directly to the secure Supabase Auth Vault via Python
  Future<void> _updateAccountPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String targetUserId = _profileData?['user_id'] ?? '';

      if (targetUserId.isEmpty) {
        _showSnackBar(
          "Profile sync failed. Cannot resolve user identity.",
          Colors.red,
        );
        setState(() => _isSaving = false);
        return;
      }

      // Pointing to the REAL authentication endpoint we just created
      final response = await http
          .post(
            Uri.parse('$backendUrl/auth/update-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': targetUserId,
              'new_password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _showSnackBar(
          "Password updated securely in the cloud vault!",
          Colors.green,
        );
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showSnackBar(
          responseData['message'] ?? "Failed to update password.",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar("Network error: Could not reach the server.", Colors.red);
      debugPrint("Password update failed: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _linkFacebookAccount() async {
    if (_profileData == null) {
      _showSnackBar("Profile not loaded yet.", Colors.red);
      return;
    }

    setState(() => _isLinkingFacebook = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final fbUser = await FacebookAuth.instance.getUserData(
          fields: "name,email",
        );
        final String facebookEmail = (fbUser['email'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (facebookEmail.isEmpty) {
          _showSnackBar(
            "Facebook did not return an email address.",
            Colors.red,
          );
          return;
        }

        final response = await http.post(
          Uri.parse('$backendUrl/auth/link-facebook'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _profileData!['user_id'],
            'facebook_email': facebookEmail,
          }),
        );

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 && responseData['success'] == true) {
          setState(() {
            _profileData!['facebook_email'] = facebookEmail;
          });
          _showSnackBar("Facebook account linked successfully.", Colors.green);
        } else {
          _showSnackBar(
            responseData['message'] ?? "Failed to link Facebook account.",
            Colors.red,
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        _showSnackBar("Facebook linking cancelled.", Colors.orange);
      } else {
        _showSnackBar("Facebook login failed: ${result.message}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Unable to link Facebook account. $e", Colors.red);
      debugPrint("Facebook link error: $e");
    } finally {
      setState(() => _isLinkingFacebook = false);
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Set fallback display data if database properties read empty or uninitialized
    final license = _profileData?['license_no'] ?? 'N/A';
    final hiredDate = _profileData?['date_hired'] ?? 'Not Recorded';
    final status = _profileData?['employment_status'] ?? 'Active';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card Header Layout
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      widget.driverName
                          .substring(0, widget.driverName.contains(' ') ? 2 : 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 👈 NEW: The Smart Badge inside a matching amber container!
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DriverRatingBadge(
                                key: UniqueKey(),
                                driverUuid: widget.driverId,
                                backendUrl: backendUrl,
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
            const SizedBox(height: 24),

            // Driver Information Block
            const Text(
              "OPERATIONAL RECORDS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.card_membership, "License Number", license),
                  const Divider(height: 24),
                  _infoRow(Icons.calendar_today, "Date Hired", hiredDate),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Facebook Integration Block
            const Text(
              "SOCIAL INTEGRATION",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.facebook,
                      color: Color(0xFF1877F2),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Facebook Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profileData?['facebook_email'] != null &&
                                  _profileData!['facebook_email']
                                      .toString()
                                      .isNotEmpty
                              ? "Linked to ${_profileData!['facebook_email']}"
                              : "Use Facebook to sign in instantly without typing your password.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLinkingFacebook ? null : _linkFacebookAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      elevation: 0,
                    ),
                    child: _isLinkingFacebook
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Link Account",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Password Update Form Section
            const Text(
              "SECURITY & SETTINGS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Change Account Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? "Password must contain at least 6 characters"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirm New Password",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (val) => val != _passwordController.text
                          ? "Passwords do not match"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateAccountPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Update System Password",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
