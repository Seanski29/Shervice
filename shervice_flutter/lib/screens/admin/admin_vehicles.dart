import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

class AdminFleet extends StatefulWidget {
  const AdminFleet({super.key});

  @override
  State<AdminFleet> createState() => _AdminFleetState();
}

class _AdminFleetState extends State<AdminFleet> {
  // --- State Variables ---
  bool _isLoading = true;
  List<dynamic> _allVehicles = [];
  List<dynamic> _filteredVehicles = [];

  // Filtering & Sorting Workspace
  String _searchQuery = '';
  String _currentSort = 'Plate (A to Z)';
  final List<String> _sortOptions = [
    'Plate (A to Z)',
    'Plate (Z to A)',
    'Capacity (High-Low)',
    'Capacity (Low-High)',
  ];

  // Pagination Configuration Rules
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  // --- Data Fetching Operations ---
  Future<void> _fetchVehicles() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/vehicles'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _allVehicles = data['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch vehicles: $e");
      _allVehicles = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  // --- Filtering, Sorting, and Search Sync Engine ---
  void _applyFiltersAndSort() {
    List<dynamic> temp = _allVehicles.where((vehicle) {
      final plate = (vehicle['plate_number'] ?? '').toString().toLowerCase();
      final model = (vehicle['bus_type'] ?? '').toString().toLowerCase();
      return plate.contains(_searchQuery.toLowerCase()) ||
          model.contains(_searchQuery.toLowerCase());
    }).toList();

    temp.sort((a, b) {
      final plateA = (a['plate_number'] ?? '').toString().toLowerCase();
      final plateB = (b['plate_number'] ?? '').toString().toLowerCase();

      final int capA =
          int.tryParse((a['bus_type'] ?? '').toString().split(' ').first) ?? 0;
      final int capB =
          int.tryParse((b['bus_type'] ?? '').toString().split(' ').first) ?? 0;

      switch (_currentSort) {
        case 'Plate (Z to A)':
          return plateB.compareTo(plateA);
        case 'Capacity (High-Low)':
          return capB.compareTo(capA);
        case 'Capacity (Low-High)':
          return capA.compareTo(capB);
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

  // --- Pagination Slice Calculations ---
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

  // --- Clear Vehicle Registration Row Handler ---
  void _confirmPurgeVehicle(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to completely erase vehicle ${vehicle['plate_number']} from the fleet network registry?',
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
                    .delete(
                      Uri.parse(
                        '$backendUrl/vehicles/delete/${vehicle['vehicle_id'] ?? vehicle['id']}',
                      ),
                    )
                    .timeout(const Duration(seconds: 10));

                if (res.statusCode == 200) {
                  _showSnackBar(
                    'Vehicle profile successfully expunged.',
                    Colors.orange,
                  );
                } else {
                  _showSnackBar(
                    'Delete operation rejected by backend.',
                    Colors.red,
                  );
                }
              } catch (e) {
                _showSnackBar('Network communication failure.', Colors.red);
              } finally {
                _fetchVehicles();
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

  void _showVehicleModal(
    BuildContext context, {
    Map<String, dynamic>? vehicle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RegisterVehicleDialog(
          vehicle: vehicle,
          onDelete: vehicle == null
              ? null
              : () => _confirmPurgeVehicle(vehicle),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchVehicles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchVehicles,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- HEADER (matches AdminSchedules/AdminDriver) -----
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fleet Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage vehicle profiles, documents, and compliance status.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showVehicleModal(context),
                    icon: const Icon(Icons.directions_bus, color: Colors.white, size: 18),
                    label: const Text(
                      'Register Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ----- SEARCH & SORT (responsive Wrap) -----
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 350,
                      minWidth: isMobile ? double.infinity : 200,
                    ),
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFiltersAndSort();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by plate or model...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 200,
                      minWidth: isMobile ? double.infinity : 140,
                    ),
                    child: SizedBox(
                      height: 42,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _currentSort,
                            icon: const Icon(Icons.sort, size: 18, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ----- VEHICLE LIST -----
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                    : _filteredVehicles.isEmpty
                        ? const Center(
                            child: Text(
                              "No tracking vehicles matched parameters.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _paginatedVehicles.length,
                            itemBuilder: (context, index) {
                              final v = _paginatedVehicles[index];
                              final String plate = v['plate_number'] ?? 'UNKNOWN';
                              final String rawBusType =
                                  v['bus_type'] ?? 'Unknown Model';
                              final String condition =
                                  v['health_status'] ?? 'Good Condition';

                              final String modelDisplay = rawBusType.contains(' - ')
                                  ? rawBusType.split(' - ').last
                                  : rawBusType;
                              final String seatCapacity = rawBusType.contains(' - ')
                                  ? rawBusType.split(' - ').first
                                  : 'Configured Seats';

                              Color conditionColor = const Color(0xFF10B981); // green
                              if (condition == 'Maintenance Required') {
                                conditionColor = const Color(0xFFF59E0B); // yellow
                              } else if (condition == 'Under Repair') {
                                conditionColor = const Color(0xFFEF4444); // red
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showVehicleModal(
                                      context,
                                      vehicle: Map<String, dynamic>.from(v),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Left indicator bar
                                          Container(
                                            width: 4,
                                            height: 36,
                                            margin: const EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              color: conditionColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        plate,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: conditionColor.withOpacity(
                                                          0.1,
                                                        ),
                                                        borderRadius: BorderRadius.circular(
                                                          10,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        condition,
                                                        style: TextStyle(
                                                          color: conditionColor,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Wrap(
                                                  spacing: 10,
                                                  runSpacing: 2,
                                                  children: [
                                                    _iconText(
                                                      Icons.directions_car_outlined,
                                                      modelDisplay,
                                                    ),
                                                    _iconText(
                                                      Icons.group_outlined,
                                                      seatCapacity,
                                                    ),
                                                    _iconText(
                                                      Icons.build_circle_outlined,
                                                      'Status: $condition',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Color(0xFF94A3B8),
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

              // ----- PAGINATION -----
              if (!_isLoading && _filteredVehicles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredVehicles.length)} of ${_filteredVehicles.length} vehicles',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                          softWrap: true,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: _currentPage > 0 ? _prevPage : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Previous'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_currentPage + 1} / $_totalPages',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _currentPage < _totalPages - 1
                                ? _nextPage
                                : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// REGISTER VEHICLE DIALOG – kept exactly as original, only styling tweaks
// ============================================================================
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
  late TextEditingController _modelController;
  late TextEditingController _modelYearController;
  late TextEditingController _engineController;
  late TextEditingController _insuranceNoController;
  late TextEditingController _franchiseNoController;
  late TextEditingController _crNoController;
  late TextEditingController _orNoController;

  final _insuranceExpiryController = TextEditingController();
  final _franchiseExpiryController = TextEditingController();
  final _crDateController = TextEditingController();
  final _orExpiryController = TextEditingController();

  String _selectedCapacity = '15 Seats';

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.vehicle != null;
    _isWritingUnlocked = !isEdit;

    String parsedModel = '';
    if (isEdit) {
      String rawBusType = widget.vehicle!['bus_type'] ?? '';
      if (rawBusType.contains(' - ')) {
        _selectedCapacity = rawBusType.split(' - ').first;
        parsedModel = rawBusType.split(' - ').last;
      } else {
        parsedModel = rawBusType;
      }
    }

    _plateController = TextEditingController(
      text: isEdit ? widget.vehicle!['plate_number'] : '',
    );
    _modelController = TextEditingController(text: parsedModel);
    _modelYearController = TextEditingController(
      text: isEdit ? widget.vehicle!['model_year']?.toString() : '',
    );
    _engineController = TextEditingController(
      text: isEdit ? widget.vehicle!['engine_no'] : '',
    );
    _insuranceNoController = TextEditingController(
      text: isEdit ? widget.vehicle!['insurance_policy_no'] : '',
    );
    _franchiseNoController = TextEditingController(
      text: isEdit ? widget.vehicle!['franchise_no'] : '',
    );
    _crNoController = TextEditingController(
      text: isEdit ? widget.vehicle!['cr_no'] : '',
    );
    _orNoController = TextEditingController(
      text: isEdit ? widget.vehicle!['or_no'] : '',
    );

    _insuranceExpiryController.text = isEdit
        ? (widget.vehicle!['insurance_expiry'] ?? '')
        : '';
    _franchiseExpiryController.text = isEdit
        ? (widget.vehicle!['franchise_expiry'] ?? '')
        : '';
    _crDateController.text = isEdit ? (widget.vehicle!['cr_date'] ?? '') : '';
    _orExpiryController.text = isEdit
        ? (widget.vehicle!['or_expiry'] ?? '')
        : '';
  }

  String _formatPickedDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2045),
    );
    if (picked != null) {
      setState(() {
        controller.text = _formatPickedDate(picked);
      });
    }
  }

  InputDecoration _fieldStyle({
    required String label,
    required IconData icon,
    bool forceDisable = false,
  }) {
    final bool active = _isWritingUnlocked && !forceDisable;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 20),
      filled: true,
      fillColor: active ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Future<void> _submitVehicleForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_insuranceExpiryController.text.isEmpty ||
        _franchiseExpiryController.text.isEmpty ||
        _crDateController.text.isEmpty ||
        _orExpiryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please declare all validation certificate expirations.",
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final bool isEditMode = widget.vehicle != null;

    final Map<String, dynamic> payload = {
      "role": "admin",
      "plate_number": _plateController.text.trim(),
      "bus_type": "$_selectedCapacity - ${_modelController.text.trim()}",
      "model_year": _modelYearController.text.trim(),
      "engine_no": _engineController.text.trim(),
      "insurance_policy_no": _insuranceNoController.text.trim(),
      "insurance_expiry": _insuranceExpiryController.text,
      "franchise_no": _franchiseNoController.text.trim(),
      "franchise_expiry": _franchiseExpiryController.text,
      "cr_no": _crNoController.text.trim(),
      "cr_date": _crDateController.text,
      "or_no": _orNoController.text.trim(),
      "or_expiry": _orExpiryController.text,
    };

    try {
      final http.Response response;
      if (isEditMode) {
        response = await http.put(
          Uri.parse(
            '$backendUrl/vehicles/update/${widget.vehicle!['vehicle_id'] ?? widget.vehicle!['id']}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } else {
        response = await http.post(
          Uri.parse('$backendUrl/vehicles'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          responseData['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? "Vehicle layout update saved!"
                  : "Vehicle successfully registered!",
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(responseData['message'] ?? "Operational rejection.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
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
    _modelController.dispose();
    _modelYearController.dispose();
    _engineController.dispose();
    _insuranceNoController.dispose();
    _franchiseNoController.dispose();
    _crNoController.dispose();
    _orNoController.dispose();
    _insuranceExpiryController.dispose();
    _franchiseExpiryController.dispose();
    _crDateController.dispose();
    _orExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.vehicle != null;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditMode ? 'Vehicle Specification Sheet' : 'Register New Vehicle',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF0F172A),
        ),
      ),
      content: SizedBox(
        width: isMobile ? double.infinity : 680,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Basic Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 20),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _plateController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'Plate Number',
                              icon: Icons.pin,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'Vehicle Model',
                              icon: Icons.directions_car,
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
                            controller: _modelYearController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'Model Year',
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCapacity,
                            decoration: _fieldStyle(
                              label: 'Capacity',
                              icon: Icons.group,
                            ),
                            onChanged: !_isWritingUnlocked
                                ? null
                                : (val) =>
                                      setState(() => _selectedCapacity = val!),
                            items: ['12 Seats', '15 Seats', '18 Seats']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _engineController,
                      readOnly: !_isWritingUnlocked,
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      decoration: _fieldStyle(
                        label: 'Engine Number',
                        icon: Icons.engineering,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Documents & Expirations",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 20),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _insuranceNoController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'Insurance Policy No.',
                              icon: Icons.gavel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _insuranceExpiryController,
                            readOnly: true,
                            onTap: !_isWritingUnlocked
                                ? null
                                : () => _selectDate(
                                    context,
                                    _insuranceExpiryController,
                                  ),
                            decoration: _fieldStyle(
                              label: 'Insurance Expiry',
                              icon: Icons.date_range,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _franchiseNoController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'Franchise No.',
                              icon: Icons.description,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _franchiseExpiryController,
                            readOnly: true,
                            onTap: !_isWritingUnlocked
                                ? null
                                : () => _selectDate(
                                    context,
                                    _franchiseExpiryController,
                                  ),
                            decoration: _fieldStyle(
                              label: 'Franchise Expiry',
                              icon: Icons.date_range,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _crNoController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'CR No.',
                              icon: Icons.assignment,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _crDateController,
                            readOnly: true,
                            onTap: !_isWritingUnlocked
                                ? null
                                : () => _selectDate(context, _crDateController),
                            decoration: _fieldStyle(
                              label: 'CR Date',
                              icon: Icons.date_range,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _orNoController,
                            readOnly: !_isWritingUnlocked,
                            validator: (val) =>
                                val!.isEmpty ? "Required" : null,
                            decoration: _fieldStyle(
                              label: 'OR No.',
                              icon: Icons.receipt,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _orExpiryController,
                            readOnly: true,
                            onTap: !_isWritingUnlocked
                                ? null
                                : () =>
                                      _selectDate(context, _orExpiryController),
                            decoration: _fieldStyle(
                              label: 'OR Expiry',
                              icon: Icons.date_range,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      actions: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            isEditMode
                ? TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onDelete != null) widget.onDelete!();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8),
                if (isEditMode && !_isWritingUnlocked)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => setState(() => _isWritingUnlocked = true),
                    child: const Text(
                      'Edit Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _submitVehicleForm,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
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
                              fontSize: 13,
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}