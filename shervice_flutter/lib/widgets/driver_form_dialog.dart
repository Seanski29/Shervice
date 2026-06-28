import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/driver_profile_model.dart';

class DriverFormDialog extends StatefulWidget {
  final DriverProfileModel? driver;
  final VoidCallback? onDelete;
  final VoidCallback? onSuccess; // Notifies the parent screen to refresh immediately
  final String backendUrl;

  const DriverFormDialog({
    super.key,
    this.driver,
    this.onDelete,
    this.onSuccess,
    required this.backendUrl,
  });

  @override
  State<DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isWritingUnlocked = false;

  late TextEditingController _nameController;
  late TextEditingController _licenseController;
  late TextEditingController _emailController;
  late TextEditingController _birthdayController;
  final _passwordController = TextEditingController();

  String _currentStatus = 'Active';

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.driver != null;
    _isWritingUnlocked = !isEdit;

    _nameController = TextEditingController(text: isEdit ? widget.driver!.name : '');
    _licenseController = TextEditingController(text: isEdit ? widget.driver!.licenseNumber : '');
    _emailController = TextEditingController(text: isEdit ? widget.driver!.email : '');
    _birthdayController = TextEditingController(text: isEdit ? widget.driver!.birthday : '1995-05-15');
    _currentStatus = isEdit ? widget.driver!.status : 'Active';
  }

  InputDecoration _fieldStyle({required String label, required IconData icon, bool forcesDisabled = false}) {
    final bool editable = _isWritingUnlocked && !forcesDisabled;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF475569)),
      filled: true,
      fillColor: editable ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime parsed = DateTime.tryParse(controller.text) ?? DateTime(1995, 5, 15);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(1950),
      lastDate: DateTime(2045),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitDataStream() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final bool isEdit = widget.driver != null;

    try {
      final http.Response res;
      final Map<String, dynamic> payload = {
        'full_name': _nameController.text.trim(),
        'license_no': _licenseController.text.trim(),
        'email': _emailController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'employment_status': _currentStatus,
      };

      if (isEdit) {
        res = await http.put(
          Uri.parse('${widget.backendUrl}/auth/update-driver/${widget.driver!.userId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));
      } else {
        final DateTime now = DateTime.now();
        final String formattedHired = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        payload['password'] = _passwordController.text;
        payload['license_expiry'] = '2031-12-31';
        payload['date_hired'] = formattedHired;

        res = await http.post(
          Uri.parse('${widget.backendUrl}/auth/register-driver'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      final responseData = jsonDecode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && responseData['success'] != false) {
        // Trigger screen refresh immediately before closing the dialog
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Database properties saved!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rejection: ${responseData['message'] ?? 'Server validation error.'}"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      debugPrint("❌ Form pipeline execution exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Sync Fault: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.driver != null;

    return AlertDialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEdit ? 'Driver Profile (DRV-${widget.driver!.id})' : 'Register New Driver',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameController, readOnly: !_isWritingUnlocked, decoration: _fieldStyle(label: 'Full Name', icon: Icons.person), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _licenseController, readOnly: !_isWritingUnlocked, decoration: _fieldStyle(label: 'License Number', icon: Icons.card_membership), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _emailController, readOnly: !_isWritingUnlocked, decoration: _fieldStyle(label: 'Account Email', icon: Icons.email), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _birthdayController, readOnly: true, decoration: _fieldStyle(label: 'Date of Birth (YYYY-MM-DD)', icon: Icons.cake), onTap: !_isWritingUnlocked ? null : () => _selectDate(_birthdayController)),
                const SizedBox(height: 16),
                if (!isEdit) ...[
                  TextFormField(controller: _passwordController, obscureText: true, decoration: _fieldStyle(label: 'Account Password', icon: Icons.lock), validator: (v) => v == null || v.length < 6 ? 'Password must be >= 6 chars' : null),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: _currentStatus,
                    decoration: _fieldStyle(label: 'Employment Status', icon: Icons.info_outline),
                    dropdownColor: const Color(0xFFF8FAFC),
                    onChanged: !_isWritingUnlocked ? null : (val) => setState(() => _currentStatus = val!),
                    items: ['Active', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(initialValue: widget.driver!.dateHired, readOnly: true, decoration: _fieldStyle(label: 'Date Hired', icon: Icons.event_available, forcesDisabled: true)),
                  const SizedBox(height: 16),
                  TextFormField(initialValue: widget.driver!.licenseExpiry, readOnly: true, decoration: _fieldStyle(label: 'License Expiration', icon: Icons.assignment_late, forcesDisabled: true)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            isEdit && widget.onDelete != null
                ? TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete!();
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                : const SizedBox.shrink(),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                if (isEdit && !_isWritingUnlocked)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => setState(() => _isWritingUnlocked = true),
                    child: const Text('Edit Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D83E4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : _submitDataStream,
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text(isEdit ? 'Save Changes' : 'Register Driver', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            )
          ],
        )
      ],
    );
  }
}