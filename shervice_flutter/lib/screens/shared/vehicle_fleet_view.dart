import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant.dart';

class VehicleFleetView extends StatefulWidget {
  final String userRole;
  final String? userId;
  final VoidCallback onRefreshNeeded;
  final Widget customHeader;

  const VehicleFleetView({
    super.key,
    required this.userRole,
    this.userId,
    required this.onRefreshNeeded,
    required this.customHeader,
  });

  @override
  State<VehicleFleetView> createState() => _VehicleFleetViewState();
}

class _VehicleFleetViewState extends State<VehicleFleetView> {
  bool _isLoading = true;
  List<dynamic> _allVehicles = [];
  List<dynamic> _filteredVehicles = [];

  String _searchQuery = '';
  String _currentSort = 'Plate (A to Z)';
  final List<String> _sortOptions = [
    'Plate (A to Z)',
    'Plate (Z to A)',
    'Vehicle Type',
    'Status Condition',
  ];

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  bool get _isAdmin => widget.userRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _fetchLiveFleetData();
  }

  Future<void> _fetchLiveFleetData() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/vehicles'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _allVehicles = data['data'] ?? [];
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch vehicles payload stack: $e");
      _allVehicles = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  Future<List<dynamic>> _fetchVehicleLogHistory(int vehicleId) async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/vehicles/maintenance'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? [];
        return data.where((log) => log['vehicle_id'] == vehicleId).toList();
      }
    } catch (e) {
      debugPrint("Error fetching log history: $e");
    }
    return [];
  }

  void _applyFiltersAndSort() {
    List<dynamic> temp = _allVehicles.where((v) {
      final plate = (v['plate_number'] ?? '').toString().toLowerCase();
      final type = (v['bus_type'] ?? '').toString().toLowerCase();
      final engine = (v['engine_no'] ?? '').toString().toLowerCase();
      return plate.contains(_searchQuery.toLowerCase()) ||
          type.contains(_searchQuery.toLowerCase()) ||
          engine.contains(_searchQuery.toLowerCase());
    }).toList();

    temp.sort((a, b) {
      final plateA = (a['plate_number'] ?? '').toString().toLowerCase();
      final plateB = (b['plate_number'] ?? '').toString().toLowerCase();
      final typeA = (a['bus_type'] ?? '').toString().toLowerCase();
      final typeB = (b['bus_type'] ?? '').toString().toLowerCase();
      final statusA = (a['health_status'] ?? '').toString().toLowerCase();
      final statusB = (b['health_status'] ?? '').toString().toLowerCase();

      switch (_currentSort) {
        case 'Plate (Z to A)':
          return plateB.compareTo(plateA);
        case 'Vehicle Type':
          return typeA.compareTo(typeB);
        case 'Status Condition':
          return statusA.compareTo(statusB);
        case 'Plate (A to Z)':
        default:
          return plateA.compareTo(plateB);
      }
    });

    setState(() {
      _filteredVehicles = temp;
      _currentPage = 0;
      _isLoading = false;
    });
  }

  int get _totalPages => (_filteredVehicles.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedVehicles {
    if (_filteredVehicles.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredVehicles.length);
    return _filteredVehicles.sublist(start, end);
  }

  void _nextPage() =>
      _currentPage < _totalPages - 1 ? setState(() => _currentPage++) : null;
  void _prevPage() => _currentPage > 0 ? setState(() => _currentPage--) : null;

  void _confirmPurgeVehicle(Map<String, dynamic> vehicle) {
    if (!_isAdmin) return;

    final dynamic rawId =
        vehicle['vehicle_id'] ?? vehicle['id'] ?? vehicle['plate_number'];
    if (rawId == null) {
      _showSnackBar(
        'Error: Could not resolve valid unique vehicle identifier.',
        Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently erase fleet asset record entry ${vehicle['plate_number'] ?? 'this unit'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final res = await http
                    .delete(Uri.parse('$backendUrl/vehicles/$rawId'))
                    .timeout(const Duration(seconds: 10));

                if (res.statusCode == 200) {
                  _showSnackBar(
                    'Fleet unit profile deleted successfully.',
                    Colors.orange,
                  );
                } else {
                  _showSnackBar(
                    'Deletion failed. Server error status: ${res.statusCode}',
                    Colors.red,
                  );
                }
              } catch (e) {
                _showSnackBar('Network connection error: $e', Colors.red);
              } finally {
                widget.onRefreshNeeded();
                _fetchLiveFleetData();
              }
            },
            child: const Text(
              'Delete permanently',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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

  // 👇 FULLY SYNCHRONIZED LOGIC
  void _showAddMaintenanceDialog() {
    final validVehicles = _allVehicles.where((v) {
      return int.tryParse(v['vehicle_id']?.toString() ?? '') != null;
    }).toList();

    if (validVehicles.isEmpty) {
      _showSnackBar('No vehicles are available for maintenance logging.', Colors.orange);
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? selectedVehicleId = int.tryParse(validVehicles.first['vehicle_id'].toString());
    String description = '';
    
    // Defaulting to needs maintenance / unrepaired
    String chosenHealthStatus = 'Needs Maintenance';
    bool isRepaired = false; 
    
    String chosenCategory = 'General';
    DateTime? incidentDate = DateTime.now();
    TimeOfDay? incidentTime;
    
    DateTime? repairDate = DateTime.now();
    TimeOfDay? repairTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Log Maintenance Event',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F172A)),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedVehicleId,
                      decoration: _inputFieldStyle(label: 'Target Vehicle Plate', icon: Icons.commute),
                      dropdownColor: const Color(0xFFF8FAFC),
                      items: validVehicles.map<DropdownMenuItem<int>>((v) {
                        final id = int.parse(v['vehicle_id'].toString());
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text("${v['plate_number'] ?? 'TBD'} - ${v['bus_type'] ?? 'Unit'}"),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedVehicleId = val),
                      validator: (val) => val == null || val <= 0 ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: chosenCategory,
                            decoration: _inputFieldStyle(label: 'Issue Category', icon: Icons.category_outlined),
                            dropdownColor: const Color(0xFFF8FAFC),
                            items: ['General', 'Engine', 'Exterior', 'Interior', 'Electrical', 'Tires/Wheels']
                                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setModalState(() => chosenCategory = val ?? 'General'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          // 👇 LOCKED DROPDOWN (Controlled purely by the checkbox)
                          child: DropdownButtonFormField<String>(
                            value: chosenHealthStatus,
                            decoration: InputDecoration(
                              labelText: 'Vehicle Status (Auto-Locked)',
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF475569)),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: chosenHealthStatus, 
                                child: Text(
                                  chosenHealthStatus, 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isRepaired ? Colors.green.shade700 : Colors.orange.shade700)
                                )
                              )
                            ],
                            onChanged: null, 
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // 👇 SYNCED CHECKBOX
                    Container(
                      decoration: BoxDecoration(
                        color: isRepaired ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isRepaired ? Colors.green.shade300 : Colors.orange.shade300)
                      ),
                      child: CheckboxListTile(
                        title: const Text("Repair Completed", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          isRepaired ? "Vehicle is fixed. Status set to 'Good'." : "Vehicle is broken. Status set to 'Needs Maintenance'.",
                          style: TextStyle(fontSize: 12, color: isRepaired ? Colors.green.shade700 : Colors.orange.shade800),
                        ),
                        value: isRepaired,
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        onChanged: (val) {
                          setModalState(() {
                            isRepaired = val ?? false;
                            // FORCE THE STATUS TO CHANGE
                            chosenHealthStatus = isRepaired ? 'Good' : 'Needs Maintenance';
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft, 
                      child: Text("Incident & Repair Timeline", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: incidentDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setModalState(() => incidentDate = picked);
                            },
                            child: InputDecorator(
                              decoration: _inputFieldStyle(label: 'Incident Date', icon: Icons.event_note),
                              child: Text(incidentDate != null ? "${incidentDate!.month}/${incidentDate!.day}/${incidentDate!.year}" : "Select Date"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: incidentTime ?? TimeOfDay.now());
                              if (picked != null) setModalState(() => incidentTime = picked);
                            },
                            child: InputDecorator(
                              decoration: _inputFieldStyle(label: 'Incident Time', icon: Icons.access_time),
                              child: Text(incidentTime != null ? incidentTime!.format(context) : "Select Time"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (isRepaired) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: repairDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setModalState(() => repairDate = picked);
                              },
                              child: InputDecorator(
                                decoration: _inputFieldStyle(label: 'Date Repaired', icon: Icons.event_available),
                                child: Text(repairDate != null ? "${repairDate!.month}/${repairDate!.day}/${repairDate!.year}" : "Select Date"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: repairTime ?? TimeOfDay.now());
                                if (picked != null) setModalState(() => repairTime = picked);
                              },
                              child: InputDecorator(
                                decoration: _inputFieldStyle(label: 'Time Repaired', icon: Icons.build_circle_outlined),
                                child: Text(repairTime != null ? repairTime!.format(context) : "Select Time"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _inputFieldStyle(label: 'Short Description of Repair/Issue', icon: Icons.description_outlined),
                      maxLines: 2,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                      onSaved: (val) => description = val ?? '',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D83E4),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final int vehicleId = selectedVehicleId ?? 0;
                  if (vehicleId <= 0) return;

                  String? currentUserId = widget.userId;
                  if (currentUserId == null || currentUserId.isEmpty) {
                    try {
                      currentUserId = Supabase.instance.client.auth.currentUser?.id;
                    } catch (_) {}
                  }

                  if (currentUserId == null || currentUserId.isEmpty) return;

                  String? formatTime(TimeOfDay? time) {
                    if (time == null) return null;
                    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                  }

                  final payload = {
                    'repair_date': (isRepaired && repairDate != null) ? '${repairDate!.year}-${repairDate!.month.toString().padLeft(2, '0')}-${repairDate!.day.toString().padLeft(2, '0')}' : null,
                    'description': description,
                    'vehicle_id': vehicleId,
                    'health_status': chosenHealthStatus,
                    'user_id': currentUserId,
                    'category': chosenCategory,
                    'incident_date': incidentDate != null ? '${incidentDate!.year}-${incidentDate!.month.toString().padLeft(2, '0')}-${incidentDate!.day.toString().padLeft(2, '0')}' : null,
                    'incident_time': formatTime(incidentTime),
                    'repair_time': isRepaired ? formatTime(repairTime) : null,
                    'is_resolved': isRepaired,
                  };

                  final response = await http.post(
                    Uri.parse('$backendUrl/vehicles/maintenance'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(payload),
                  );

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    widget.onRefreshNeeded();
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showSnackBar('Maintenance record saved successfully.', Colors.green);
                    }
                  }
                }
              },
              child: const Text('Save Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 ADDED: Modal to display the fetched log history WITH SORTING
void _showHistoryModal(BuildContext context, String plateNumber, List<dynamic> logs) {
    String currentSort = 'Newest First';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          List<dynamic> sortedLogs = List.from(logs);
          
          sortedLogs.sort((a, b) {
            // Helper to extract a sortable value
            DateTime getDate(dynamic item) {
              final dateStr = item['incident_date']?.toString() ?? item['repair_date']?.toString() ?? '';
              return DateTime.tryParse(dateStr) ?? DateTime(2000);
            }

            DateTime dateA = getDate(a);
            DateTime dateB = getDate(b);

            if (currentSort == 'Newest First') return dateB.compareTo(dateA);
            if (currentSort == 'Oldest First') return dateA.compareTo(dateB);
            
            // For 'Ongoing First' (Ongoing = false/null)
            if (currentSort == 'Ongoing First') {
              bool aResolved = a['is_resolved'] == true;
              bool bResolved = b['is_resolved'] == true;
              if (aResolved != bResolved) return aResolved ? 1 : -1;
            }
            
            // For 'Fixed First'
            if (currentSort == 'Fixed First') {
              bool aResolved = a['is_resolved'] == true;
              bool bResolved = b['is_resolved'] == true;
              if (aResolved != bResolved) return aResolved ? -1 : 1;
            }

            return dateB.compareTo(dateA); // Default fallback
          });

          return AlertDialog(
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('History: $plateNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]
            ),
            content: SizedBox(
              width: 600,
              height: 500,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentSort,
                          isExpanded: true,
                          items: ['Newest First', 'Oldest First', 'Ongoing First', 'Fixed First']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) => setModalState(() => currentSort = val ?? 'Newest First'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: sortedLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = sortedLogs[index];
                        // Ensure is_resolved boolean is checked properly
                        final bool isResolved = log['is_resolved'] == true;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isResolved ? Colors.green.shade200 : Colors.orange.shade300, width: 2)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log['category'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: isResolved ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(20)),
                                    child: Text(isResolved ? "FIXED" : "ONGOING", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                ]
                              ),
                              const SizedBox(height: 8),
                              Text(log['description'] ?? ''),
                              const SizedBox(height: 8),
                              Text("Incident: ${log['incident_date'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ]
                          )
                        );
                      }
                    )
                  ),
                ],
              ),
            )
          );
        }
      )
    );
  }

  void _showUserModal(BuildContext context, {Map<String, dynamic>? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => RegisterVehicleDialog(
        vehicle: user,
        onDelete: user == null ? null : () => _confirmPurgeVehicle(user),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        widget.onRefreshNeeded();
        _fetchLiveFleetData();
      }
    });
  }

  InputDecoration _inputFieldStyle({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF475569)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              widget.customHeader,
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showAddMaintenanceDialog,
                    icon: const Icon(Icons.build_circle_outlined, size: 20),
                    label: const Text(
                      'Log Maintenance',
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
                  if (_isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showUserModal(context, user: null),
                      icon: const Icon(
                        Icons.add_box_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
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
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFiltersAndSort();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search fleet accounts profiles...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentSort,
                    icon: const Icon(Icons.sort),
                    items: _sortOptions
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        _currentSort = newValue;
                        _applyFiltersAndSort();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                ? const Center(
                    child: Text(
                      "No vehicle metrics found.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _paginatedVehicles.length,
                    itemBuilder: (context, index) {
                      final v = _paginatedVehicles[index];
                      final String health = v['health_status'] ?? 'Excellent';

                      final bool isUnderMaintenance =
                          health.toLowerCase().contains('need') ||
                          health.toLowerCase().contains('maintenance') ||
                          health.toLowerCase().contains('repair');
                      final bool isOnDuty = health.toLowerCase() == 'on duty';

                      Color statusColor = Colors.green;
                      String badgeText = "Active READY";

                      if (isUnderMaintenance) {
                        statusColor = Colors.red;
                        badgeText = "MAINTENANCE LOCK";
                      } else if (isOnDuty) {
                        statusColor = Colors.blue;
                        badgeText = "ON DUTY";
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showUserModal(
                              context,
                              user: Map<String, dynamic>.from(v),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        v['plate_number'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (_isAdmin) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _confirmPurgeVehicle(
                                                    Map<String, dynamic>.from(
                                                      v,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 12,
                                    children: [
                                      _iconText(
                                        Icons.directions_bus,
                                        v['bus_type'] ?? 'Standard Shuttle',
                                      ),
                                      _iconText(
                                        Icons.date_range_outlined,
                                        "Year: ${v['model_year'] ?? 'N/A'}",
                                      ),
                                      _iconText(
                                        Icons.pin_outlined,
                                        "Engine: ${v['engine_no'] ?? 'N/A'}",
                                      ),
                                      _iconText(
                                        Icons.article_outlined,
                                        "CR ID: ${v['cr_no'] ?? 'N/A'}",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.build_circle_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Notes: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          v['last_maintenance_description'] ??
                                              'No recent logs entries.',
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final int vId = int.tryParse(v['vehicle_id'].toString()) ?? 0;
                                        if (vId > 0) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (c) => const Center(child: CircularProgressIndicator()),
                                          );
                                          final logs = await _fetchVehicleLogHistory(vId);
                                          if (context.mounted) {
                                            Navigator.pop(context); 
                                            _showHistoryModal(context, v['plate_number'] ?? 'Unknown', logs);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.history, size: 18),
                                      label: const Text("View Maintenance History"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (!_isLoading && _filteredVehicles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredVehicles.length)} of ${_filteredVehicles.length} vehicle assets',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _currentPage > 0 ? _prevPage : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? _nextPage
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
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

class RegisterVehicleDialog extends StatefulWidget {
  final Map<String, dynamic>? vehicle;
  final VoidCallback? onDelete;

  const RegisterVehicleDialog({super.key, this.vehicle, this.onDelete});

  @override
  State<RegisterVehicleDialog> createState() => _RegisterVehicleDialogState();
}

class _RegisterVehicleDialogState extends State<RegisterVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isWritingUnlocked = false;

  late TextEditingController _plateController;
  late TextEditingController _typeController;
  late TextEditingController _yearController;
  late TextEditingController _engineController;
  late TextEditingController _policyController;
  late TextEditingController _insExpiryController;
  late TextEditingController _franchiseController;
  late TextEditingController _franExpiryController;
  late TextEditingController _crController;
  late TextEditingController _crDateController;
  late TextEditingController _orController;
  late TextEditingController _orExpiryController;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.vehicle != null;
    _isWritingUnlocked = !isEdit;

    _plateController = TextEditingController(
      text: isEdit ? (widget.vehicle!['plate_number'] ?? '') : '',
    );
    _typeController = TextEditingController(
      text: isEdit ? (widget.vehicle!['bus_type'] ?? '') : '',
    );
    _yearController = TextEditingController(
      text: isEdit ? (widget.vehicle!['model_year'] ?? '') : '',
    );
    _engineController = TextEditingController(
      text: isEdit ? (widget.vehicle!['engine_no'] ?? '') : '',
    );
    _policyController = TextEditingController(
      text: isEdit ? (widget.vehicle!['insurance_policy_no'] ?? '') : '',
    );
    _insExpiryController = TextEditingController(
      text: isEdit ? (widget.vehicle!['insurance_expiry'] ?? '') : '',
    );
    _franchiseController = TextEditingController(
      text: isEdit ? (widget.vehicle!['franchise_no'] ?? '') : '',
    );
    _franExpiryController = TextEditingController(
      text: isEdit ? (widget.vehicle!['franchise_expiry'] ?? '') : '',
    );
    _crController = TextEditingController(
      text: isEdit ? (widget.vehicle!['cr_no'] ?? '') : '',
    );
    _crDateController = TextEditingController(
      text: isEdit ? (widget.vehicle!['cr_date'] ?? '') : '',
    );
    _orController = TextEditingController(
      text: isEdit ? (widget.vehicle!['or_no'] ?? '') : '',
    );
    _orExpiryController = TextEditingController(
      text: isEdit ? (widget.vehicle!['or_expiry'] ?? '') : '',
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    if (!_isWritingUnlocked) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D83E4),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  InputDecoration _fieldStyle({
    required String label,
    required IconData icon,
    bool isDatePicker = false,
  }) {
    final bool active = _isWritingUnlocked;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF475569)),
      suffixIcon: isDatePicker
          ? const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B))
          : null,
      filled: true,
      fillColor: active ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Future<void> _submitVehicleForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final bool isEditMode = widget.vehicle != null;

    String cleanStr(TextEditingController controller, String fallback) {
      final txt = controller.text.trim();
      return txt.isEmpty ? fallback : txt;
    }

    try {
      final http.Response response;
      final bodyData = jsonEncode({
        'plate_number': cleanStr(
          _plateController,
          'TBD-${Random().nextInt(900) + 100}',
        ),
        'bus_type': cleanStr(_typeController, 'Standard Shuttle'),
        'model_year': cleanStr(_yearController, '2026'),
        'engine_no': cleanStr(_engineController, 'N/A'),
        'insurance_policy_no': cleanStr(_policyController, 'N/A'),
        'insurance_expiry': cleanStr(_insExpiryController, '2027-01-01'),
        'franchise_no': cleanStr(_franchiseController, 'N/A'),
        'franchise_expiry': cleanStr(_franExpiryController, 'N/A'),
        'cr_no': cleanStr(_crController, 'N/A'),
        'cr_date': cleanStr(_crDateController, 'N/A'),
        'or_no': cleanStr(_orController, 'N/A'),
        'or_expiry': cleanStr(_orExpiryController, 'N/A'),
      });

      if (isEditMode) {
        response = await http
            .put(
              Uri.parse(
                '$_backendUrl/vehicles/update/${widget.vehicle!['vehicle_id']}',
              ),
              headers: {'Content-Type': 'application/json'},
              body: bodyData,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .post(
              Uri.parse('$_backendUrl/vehicles'),
              headers: {'Content-Type': 'application/json'},
              body: bodyData,
            )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? "Asset profile changes committed!"
                  : "Fleet vehicle added to registry securely!",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(
          "Server responded with code status: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _typeController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _policyController.dispose();
    _insExpiryController.dispose();
    _franchiseController.dispose();
    _franExpiryController.dispose();
    _crController.dispose();
    _crDateController.dispose();
    _orController.dispose();
    _orExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.vehicle != null;

    return AlertDialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditMode
            ? 'Fleet Vehicle Specification Context'
            : 'Register System Vehicle',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Color(0xFF0F172A),
        ),
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plateController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'Plate Number',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _typeController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'Bus Configuration Type',
                          icon: Icons.directions_bus_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'Model Year',
                          icon: Icons.date_range_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _engineController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'Engine Serial Code',
                          icon: Icons.pin_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                TextFormField(
                  controller: _policyController,
                  readOnly: !_isWritingUnlocked,
                  decoration: _fieldStyle(
                    label: 'Insurance Policy No.',
                    icon: Icons.policy_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _insExpiryController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _insExpiryController),
                  decoration: _fieldStyle(
                    label: 'Insurance Expiry (YYYY-MM-DD)',
                    icon: Icons.event_busy_outlined,
                    isDatePicker: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _franchiseController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'Franchise No.',
                          icon: Icons.assignment_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _franExpiryController,
                        readOnly: true,
                        onTap: () =>
                            _selectDate(context, _franExpiryController),
                        decoration: _fieldStyle(
                          label: 'Franchise Expiry',
                          icon: Icons.event_available_outlined,
                          isDatePicker: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _crController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'CR Registration No.',
                          icon: Icons.article_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _crDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context, _crDateController),
                        decoration: _fieldStyle(
                          label: 'CR Registration Date',
                          icon: Icons.calendar_today_outlined,
                          isDatePicker: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orController,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: 'OR Official Receipt No.',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _orExpiryController,
                        readOnly: true,
                        onTap: () => _selectDate(context, _orExpiryController),
                        decoration: _fieldStyle(
                          label: 'OR Expiry Validity',
                          icon: Icons.history_toggle_off_outlined,
                          isDatePicker: true,
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
      actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isEditMode && !_isWritingUnlocked)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => setState(() => _isWritingUnlocked = true),
                child: const Text(
                  'Edit Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D83E4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submitVehicleForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditMode ? 'Save Changes' : 'Register Vehicle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}