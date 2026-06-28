import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffVehicle extends StatefulWidget {
  const StaffVehicle({super.key});

  @override
  State<StaffVehicle> createState() => _StaffVehicleState();
}

class _StaffVehicleState extends State<StaffVehicle> {
  bool _isLoading = true;
  List<dynamic> _vehicles = [];

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveFleetData();
  }

  Future<void> _fetchLiveFleetData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await http.get(Uri.parse('$_backendUrl/vehicles'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _vehicles = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Fleet Data Sync Failure: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getHealthColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('need') || s.contains('poor') || s.contains('maintenance') || s.contains('bad')) {
      return Colors.red;
    }
    if (s.contains('good')) return Colors.blue;
    return Colors.green;
  }

  void _showAddMaintenanceDialog() {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles tracked in fleet database system to maintain.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    
    // Safely parse initial value to int to avoid type-mismatch crashes
    int? selectedVehicleId = int.tryParse(_vehicles.first['vehicle_id'].toString());
    String description = '';
    String chosenHealthStatus = 'Excellent';
    final DateTime today = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Log Vehicle Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Target Vehicle Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedVehicleId,
                        decoration: const InputDecoration(labelText: 'Select Target Vehicle (Plate)'),
                        items: _vehicles.map<DropdownMenuItem<int>>((v) {
                          final int currentId = int.tryParse(v['vehicle_id'].toString()) ?? 0;
                          return DropdownMenuItem<int>(
                            value: currentId,
                            child: Text("${v['plate_number'] ?? 'TBD'} (${v['bus_type'] ?? 'Bus'})"),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedVehicleId = val),
                      ),
                      const SizedBox(height: 16),
                      
                      // Health Status Condition Dropdown
                      DropdownButtonFormField<String>(
                        value: chosenHealthStatus,
                        decoration: const InputDecoration(labelText: 'Set Updated Health Condition Status'),
                        items: ['Excellent', 'Good', 'Needs Maintenance'].map((status) {
                          return DropdownMenuItem<String>(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) => setModalState(() => chosenHealthStatus = val ?? 'Excellent'),
                      ),
                      const SizedBox(height: 16),
                      
                      // Issue Action Taken Field Box
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Maintenance Description / Action Taken',
                          hintText: 'e.g., Replaced worn brake pads...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Please outline issue descriptions logs.' : null,
                        onSaved: (val) => description = val ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      
                      try {
                        // Extract authentic user identifier directly from active authentication state session
                        final supabaseClient = Supabase.instance.client;
                        final String? currentUserId = supabaseClient.auth.currentUser?.id;

                        if (currentUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Session expired. Please log in again.')),
                          );
                          return;
                        }
                        
                        final response = await http.post(
                          Uri.parse('$_backendUrl/vehicles/maintenance'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            "repair_date": "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}",
                            "description": description,
                            "vehicle_id": selectedVehicleId,
                            "user_id": currentUserId, 
                            "health_status": chosenHealthStatus
                          }),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          final resData = jsonDecode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resData['message'] ?? 'Action resolved.')),
                          );
                          _fetchLiveFleetData(); 
                        }
                      } catch (err) {
                        debugPrint("❌ Flutter Submission Intercepted Crash: $err");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Submission crash caught: $err')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                  child: const Text('Save Log Entry', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalVehicles = _vehicles.length;
    final int alertVehicles = _vehicles.where((v) {
      final cond = (v['health_status'] ?? '').toString().toLowerCase();
      return cond.contains('need') || cond.contains('poor') || cond.contains('maintenance');
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLiveFleetData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fleet Management', 
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Monitor vehicle configuration metrics, parameters, and structural health.', 
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddMaintenanceDialog,
                          icon: const Icon(Icons.build_circle, color: Colors.white, size: 18),
                          label: const Text('Add Maintenance Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatSummaryCard('TOTAL FLEET SIZE', '$totalVehicles Units', Icons.directions_bus, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatSummaryCard('MAINTENANCE ALERTS', '$alertVehicles Attention', Icons.warning_amber_rounded, alertVehicles > 0 ? Colors.red : Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_vehicles.isEmpty)
                      _buildEmptyFleetPlaceholder()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 16, 
                          mainAxisSpacing: 16, 
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, i) {
                          final v = _vehicles[i];
                          
                          final String plate = v['plate_number'] ?? 'UNASSIGNED';
                          final String type = v['bus_type'] ?? 'Standard Shuttle';
                          final String health = v['health_status'] ?? 'Excellent';
                          final String modelYear = v['model_year'] ?? 'N/A';
                          
                          final hColor = _getHealthColor(health);

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8), 
                                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), 
                                      child: const Icon(Icons.commute, color: Colors.blueGrey),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                      decoration: BoxDecoration(
                                        color: hColor.withOpacity(0.1), 
                                        borderRadius: BorderRadius.circular(20),
                                      ), 
                                      child: Text(
                                        health.toUpperCase(), 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                                Text(type, style: TextStyle(color: Colors.grey.shade500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                  children: [
                                    const Text('Model Year', style: TextStyle(fontSize: 12, color: Colors.grey)), 
                                    Text(modelYear, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                  children: [
                                    const Text('Engine Code', style: TextStyle(fontSize: 12, color: Colors.grey)), 
                                    Text(
                                      v['engine_no'] ?? 'N/A', 
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFleetPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.bus_alert, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No Fleet Vehicles Found', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}