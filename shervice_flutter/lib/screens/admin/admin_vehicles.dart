import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminFleet extends StatefulWidget {
  const AdminFleet({super.key});

  @override
  State<AdminFleet> createState() => _AdminFleetState();
}

class _AdminFleetState extends State<AdminFleet> {
  bool _isLoading = true;
  List<dynamic> _vehicles = [];

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/vehicles'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _vehicles = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("❌ Failed to fetch vehicles: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewVehicleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const RegisterVehicleDialog();
      },
    ).then((_) {
      // Refresh the list after the modal closes
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchVehicles();
      }
    });
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
              'Fleet Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showNewVehicleModal(context),
              icon: const Icon(Icons.directions_bus, color: Colors.white),
              label: const Text(
                'Register Vehicle',
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

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_vehicles.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "No vehicles registered yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._vehicles.map((v) {
            return _buildVehicleCard(
              plate: v['plate_number'] ?? 'UNKNOWN',
              model: v['bus_type'] ?? 'Unknown Model',
              capacity: 'Configured Seats',
              condition: v['health_status'] ?? 'Good',
              status: 'Garage', // Can be dynamically linked to trips later
              statusColor: v['health_status'] == 'Excellent'
                  ? Colors.green
                  : Colors.orange,
            );
          }),
      ],
    );
  }

  Widget _buildVehicleCard({
    required String plate,
    required String model,
    required String capacity,
    required String condition,
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
                plate,
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
              _iconText(Icons.directions_car_outlined, model),
              _iconText(Icons.group_outlined, capacity),
              _iconText(Icons.build_circle_outlined, 'Condition: $condition'),
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

// ─── FULL PRODUCTION REGISTRATION MODAL ───
class RegisterVehicleDialog extends StatefulWidget {
  const RegisterVehicleDialog({super.key});

  @override
  State<RegisterVehicleDialog> createState() => _RegisterVehicleDialogState();
}

class _RegisterVehicleDialogState extends State<RegisterVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text Controllers
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _engineController = TextEditingController();
  final _insuranceNoController = TextEditingController();
  final _franchiseNoController = TextEditingController();
  final _crNoController = TextEditingController();
  final _orNoController = TextEditingController();

  // Date Variables
  DateTime? _insuranceExpiry;
  DateTime? _franchiseExpiry;
  DateTime? _crDate;
  DateTime? _orExpiry;

  String _selectedCapacity = '15 Seats';

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  // Helper function to format dates for the database (YYYY-MM-DD)
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Helper function to trigger the calendar popup
  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onPicked,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure dates are selected
    if (_insuranceExpiry == null ||
        _franchiseExpiry == null ||
        _crDate == null ||
        _orExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill out all required dates."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/vehicles/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "role": "admin",
          "plate_number": _plateController.text.trim(),
          "bus_type": "$_selectedCapacity - ${_modelController.text.trim()}",
          "model_year": _modelYearController.text.trim(),
          "engine_no": _engineController.text.trim(),
          "insurance_policy_no": _insuranceNoController.text.trim(),
          "insurance_expiry": _formatDate(_insuranceExpiry),
          "franchise_no": _franchiseNoController.text.trim(),
          "franchise_expiry": _formatDate(_franchiseExpiry),
          "cr_no": _crNoController.text.trim(),
          "cr_date": _formatDate(_crDate),
          "or_no": _orNoController.text.trim(),
          "or_expiry": _formatDate(_orExpiry),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vehicle successfully added!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(responseData['message'] ?? "Registration failed.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _modelYearController.dispose();
    _engineController.dispose();
    _insuranceNoController.dispose();
    _franchiseNoController.dispose();
    _crNoController.dispose();
    _orNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Register New Vehicle',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 650, // Made slightly wider to fit side-by-side columns nicely
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── BASIC INFO ───
                const Text(
                  "Basic Information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plateController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'Plate Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Model',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _modelYearController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'Model Year (e.g. 2024)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCapacity,
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: ['12 Seats', '15 Seats', '18 Seats']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCapacity = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _engineController,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                  decoration: const InputDecoration(
                    labelText: 'Engine Number',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── REGISTRATION & DOCUMENTS ───
                const Text(
                  "Documents & Expirations",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Divider(),

                // Insurance
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _insuranceNoController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'Insurance Policy No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDate(
                          context,
                          _insuranceExpiry,
                          (d) => _insuranceExpiry = d,
                        ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _insuranceExpiry == null
                                ? 'Select Date'
                                : _formatDate(_insuranceExpiry)!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Franchise
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _franchiseNoController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'Franchise No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDate(
                          context,
                          _franchiseExpiry,
                          (d) => _franchiseExpiry = d,
                        ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _franchiseExpiry == null
                                ? 'Select Date'
                                : _formatDate(_franchiseExpiry)!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CR (Certificate of Registration)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _crNoController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'CR No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () =>
                            _selectDate(context, _crDate, (d) => _crDate = d),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'CR Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _crDate == null
                                ? 'Select Date'
                                : _formatDate(_crDate)!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // OR (Official Receipt)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _orNoController,
                        validator: (val) => val!.isEmpty ? "Required" : null,
                        decoration: const InputDecoration(
                          labelText: 'OR No.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDate(
                          context,
                          _orExpiry,
                          (d) => _orExpiry = d,
                        ),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _orExpiry == null
                                ? 'Select Date'
                                : _formatDate(_orExpiry)!,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          onPressed: _isLoading ? null : _submitVehicle,
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
                  'Register Vehicle',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
