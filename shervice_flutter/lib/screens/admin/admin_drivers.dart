import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDriver extends StatefulWidget {
  const AdminDriver({super.key});

  @override
  State<AdminDriver> createState() => _AdminDriverState();
}

class _AdminDriverState extends State<AdminDriver> {
  // --- Network Routing ---
  String get _backendRegisterUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/auth/register-driver';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/auth/register-driver'
        : 'http://127.0.0.1:5000/api/auth/register-driver';
  }

  String get _backendFetchUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/test-db';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/test-db'
        : 'http://127.0.0.1:5000/api/test-db';
  }

  String _backendUpdateUrl(String id) {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/auth/update-driver/$id';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/auth/update-driver/$id'
        : 'http://127.0.0.1:5000/api/auth/update-driver/$id';
  }

  String _backendDeleteUrl(String id) {
    if (kIsWeb) return 'http://127.0.0.1:5000/api/auth/delete-driver/$id';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api/auth/delete-driver/$id'
        : 'http://127.0.0.1:5000/api/auth/delete-driver/$id';
  }

  // --- State Variables ---
  bool _isLoading = true;
  List<dynamic> _allDrivers = [];
  List<dynamic> _filteredDrivers = [];

  // Filtering & Sorting
  String _searchQuery = '';
  String _currentSort = 'A to Z';
  final List<String> _sortOptions = ['A to Z', 'Z to A', 'Rating (High-Low)', 'Rating (Low-High)'];

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchDriversFromDatabase();
  }

  // --- Data Fetching & Processing ---
  Future<void> _fetchDriversFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse(_backendFetchUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['connection_status'] == 'SUCCESS') {
          _allDrivers = data['sample_data_payload'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("❌ Error reading live driver profile streams: $e");
      _allDrivers = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  void _applyFiltersAndSort() {
    // 1. Search Filter
    List<dynamic> temp = _allDrivers.where((driver) {
      final name = (driver['full_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Sorting
    temp.sort((a, b) {
      final nameA = (a['full_name'] ?? '').toString().toLowerCase();
      final nameB = (b['full_name'] ?? '').toString().toLowerCase();
      
      final ratingA = double.tryParse(a['rating']?.toString() ?? '5.0') ?? 5.0;
      final ratingB = double.tryParse(b['rating']?.toString() ?? '5.0') ?? 5.0;

      switch (_currentSort) {
        case 'Z to A':
          return nameB.compareTo(nameA);
        case 'Rating (High-Low)':
          return ratingB.compareTo(ratingA);
        case 'Rating (Low-High)':
          return ratingA.compareTo(ratingB);
        case 'A to Z':
        default:
          return nameA.compareTo(nameB);
      }
    });

    setState(() {
      _filteredDrivers = temp;
      _currentPage = 0;
      _isLoading = false;
    });
  }

  // --- Pagination Logic ---
  int get _totalPages => (_filteredDrivers.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedDrivers {
    if (_filteredDrivers.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredDrivers.length);
    return _filteredDrivers.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  // --- CORE DRIVER MODAL (VIEW MODE BY DEFAULT -> EDIT MODE FLIP) ---
  void _showNewDriverModal(BuildContext context, {Map<String, dynamic>? driver}) {
    final bool isDriverMode = driver != null;
    final formKey = GlobalKey<FormState>();

    bool isWritingUnlocked = !isDriverMode; 

    final String initialName = isDriverMode ? (driver['full_name'] ?? '').toString() : '';
    final String initialLicense = isDriverMode ? (driver['license_no'] ?? '').toString() : '';
    final String initialEmail = isDriverMode 
        ? (driver['username'] ?? driver['email'] ?? driver['Username'] ?? driver['Email'] ?? '').toString() 
        : '';
    final String initialBirthday = isDriverMode ? (driver['birthday'] ?? '1995-05-15').toString() : '1995-05-15';

    final nameController = TextEditingController(text: initialName);
    final licenseController = TextEditingController(text: initialLicense);
    final emailController = TextEditingController(text: initialEmail);
    final birthdayController = TextEditingController(text: initialBirthday);
    final passwordController = TextEditingController();
    
    final String driverId = isDriverMode ? (driver['driver_id']?.toString() ?? 'TBD') : '';
    final String licenseExpiry = isDriverMode ? (driver['license_expiry'] ?? '2031-12-31') : '2031-12-31';
    final String dateHired = isDriverMode ? (driver['date_hired'] ?? 'Not Recorded') : '';
    String currentStatus = isDriverMode ? (driver['employment_status'] ?? 'Active') : 'Active';

    InputDecoration _fieldStyle({required String label, required IconData icon, bool forcesDisabled = false}) {
      final bool editable = isWritingUnlocked && !forcesDisabled;
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF475569)),
        filled: true,
        fillColor: editable ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isDriverMode ? 'Driver Profile (DRV-$driverId)' : 'Register New Driver', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF0F172A)),
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          readOnly: !isWritingUnlocked,
                          decoration: _fieldStyle(label: 'Full Name', icon: Icons.person),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: licenseController,
                          readOnly: !isWritingUnlocked,
                          decoration: _fieldStyle(label: 'License Number', icon: Icons.card_membership),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !isWritingUnlocked, 
                          decoration: _fieldStyle(label: 'Account Email', icon: Icons.email),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Dynamic Birthday Selector for BOTH states
                        TextFormField(
                          controller: birthdayController,
                          readOnly: true,
                          decoration: _fieldStyle(label: 'Date of Birth (YYYY-MM-DD)', icon: Icons.cake),
                          onTap: !isWritingUnlocked ? null : () async {
                            DateTime currentParsedDate = DateTime.tryParse(birthdayController.text) ?? DateTime(1995, 5, 15);
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: currentParsedDate,
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                birthdayController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        if (!isDriverMode) ...[
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: _fieldStyle(label: 'Account Password', icon: Icons.lock),
                            validator: (value) => value == null || value.length < 6 ? 'Password must be >= 6 chars' : null,
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: currentStatus,
                            decoration: _fieldStyle(label: 'Employment Status', icon: Icons.info_outline),
                            dropdownColor: const Color(0xFFF8FAFC),
                            onChanged: !isWritingUnlocked ? null : (val) {
                              if (val != null) {
                                setDialogState(() => currentStatus = val);
                              }
                            },
                            items: ['Active', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: dateHired,
                            readOnly: true,
                            decoration: _fieldStyle(label: 'Date Hired', icon: Icons.event_available, forcesDisabled: true),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: licenseExpiry,
                            readOnly: true,
                            decoration: _fieldStyle(label: 'License Expiration', icon: Icons.assignment_late, forcesDisabled: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isDriverMode
                        ? TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmPurgeDriver(driver);
                            },
                            child: const Text(
                              'Delete', 
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          )
                        : const SizedBox.shrink(),
                    
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        if (isDriverMode && !isWritingUnlocked)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setDialogState(() => isWritingUnlocked = true);
                            },
                            child: const Text('Edit Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D83E4),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                setState(() => _isLoading = true);
                                
                                try {
                                  if (isDriverMode) {
                                    final res = await http.put(
                                      Uri.parse(_backendUpdateUrl(driver['user_id'].toString())),
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode({
                                        'full_name': nameController.text.trim(),
                                        'license_no': licenseController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'birthday': birthdayController.text.trim(), 
                                        'employment_status': currentStatus,
                                      }),
                                    ).timeout(const Duration(seconds: 10));

                                    if (!mounted) return;
                                    if (res.statusCode == 200) {
                                      _showSnackBar('Profile successfully modified!', Colors.green);
                                    } else {
                                      _showSnackBar('Update rejected by server.', Colors.red);
                                    }
                                  } else {
                                    final DateTime now = DateTime.now();
                                    final String formattedDateHired = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                    final res = await http.post(
                                      Uri.parse(_backendRegisterUrl),
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode({
                                        'email': emailController.text.trim(),
                                        'password': passwordController.text,
                                        'full_name': nameController.text.trim(),
                                        'license_no': licenseController.text.trim(),
                                        'birthday': birthdayController.text.trim(), 
                                        'license_expiry': '2031-12-31',
                                        'date_hired': formattedDateHired,
                                      }),
                                    ).timeout(const Duration(seconds: 10));

                                    if (!mounted) return;
                                    final responseData = jsonDecode(res.body);

                                    if (res.statusCode == 201 || responseData['success'] == true) {
                                      _showSnackBar('Driver registered securely in database!', Colors.green);
                                    } else {
                                      _showSnackBar('Server Error: ${responseData['message']}', Colors.red);
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) _showSnackBar('Network connection failure.', Colors.red);
                                } finally {
                                  _fetchDriversFromDatabase();
                                }
                              }
                            },
                            child: Text(
                              isDriverMode ? 'Save Changes' : 'Register Driver', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DELETE CONFIRMATION INTERFACE ---
  void _confirmPurgeDriver(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently erase ${driver['full_name']} from the fleet network?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final res = await http.delete(
                  Uri.parse(_backendDeleteUrl(driver['user_id'].toString()))
                ).timeout(const Duration(seconds: 10));
                
                if (res.statusCode == 200) {
                  _showSnackBar('Driver records completely expunged.', Colors.orange);
                } else {
                  _showSnackBar('Purge request denied by backend.', Colors.red);
                }
              } catch (e) {
                _showSnackBar('Network error occurred.', Colors.red);
              } finally {
                _fetchDriversFromDatabase();
              }
            },
            child: const Text('Delete permanently', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // --- CORE UI VIEW BUILDER ---
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
              const Text(
                'Driver Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewDriverModal(context),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('Add Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
                    hintText: 'Search by name or letter...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                    items: _sortOptions.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
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
                : _filteredDrivers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No active drivers found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _paginatedDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = _paginatedDrivers[index];
                          final String status = driver['employment_status'] ?? 'Active';
                          final Color statusColor = (status == 'Active') ? Colors.green : Colors.orange;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Material(
                              color: Colors.transparent, 
                              child: ListTile(
                                splashColor: Colors.grey.withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                title: Text(
                                  driver['full_name'] ?? 'Unnamed Driver', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 16)
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                                            const SizedBox(width: 4),
                                            Text(driver['rating']?.toString() ?? '5.0', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                onTap: () => _showNewDriverModal(context, driver: Map<String, dynamic>.from(driver)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          if (!_isLoading && _filteredDrivers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredDrivers.length)} of ${_filteredDrivers.length} drivers',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _currentPage > 0 ? _prevPage : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 8),
                      Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
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
}