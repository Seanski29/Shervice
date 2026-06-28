import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_feedbacks.dart';

// ─── MAIN DASHBOARD COMPONENT ───
class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  // --- State Variables ---
  bool _isLoading = true;
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];

  // Filtering, Searching & Sorting Configuration
  String _searchQuery = '';
  String _currentSort = 'Name (A to Z)';
  final List<String> _sortOptions = ['Name (A to Z)', 'Name (Z to A)', 'Role'];

  // Pagination Parameters
  int _currentPage = 0;
  final int _itemsPerPage = 5;

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
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/auth/system-users'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _allUsers = data['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch users: $e");
      _allUsers = [];
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
      }
    }
  }

  void _applyFiltersAndSort() {
    List<dynamic> temp = _allUsers.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final company = (user['company'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             email.contains(_searchQuery.toLowerCase()) || 
             company.contains(_searchQuery.toLowerCase());
    }).toList();

    temp.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      final roleA = (a['role'] ?? '').toString().toLowerCase();
      final roleB = (b['role'] ?? '').toString().toLowerCase();

      switch (_currentSort) {
        case 'Name (Z to A)':
          return nameB.compareTo(nameA);
        case 'Role':
          return roleA.compareTo(roleB);
        case 'Name (A to Z)':
        default:
          return nameA.compareTo(nameB);
      }
    });

    setState(() {
      _filteredUsers = temp;
      _currentPage = 0;
      _isLoading = false;
    });
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedUsers {
    if (_filteredUsers.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredUsers.length);
    return _filteredUsers.sublist(start, end);
  }

  void _nextPage() => _currentPage < _totalPages - 1 ? setState(() => _currentPage++) : null;
  void _prevPage() => _currentPage > 0 ? setState(() => _currentPage--) : null;

  void _confirmPurgeUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently revoke accesses and delete system account records for ${user['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final res = await http.delete(
                  Uri.parse('$_backendUrl/auth/delete-user/${user['id']}'),
                ).timeout(const Duration(seconds: 10));
                
                if (res.statusCode == 200) {
                  _showSnackBar('User identity context completely deleted.', Colors.orange);
                } else {
                  _showSnackBar('Purge validation request rejected by server.', Colors.red);
                }
              } catch (e) {
                _showSnackBar('Network layer timing exception error.', Colors.red);
              } finally {
                _fetchSystemUsers();
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

  void _showUserModal(BuildContext context, {Map<String, dynamic>? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RegisterUserDialog(
          user: user,
          onDelete: user == null ? null : () => _confirmPurgeUser(user),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchSystemUsers();
      }
    });
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
              const Text(
                'User Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
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
                    onPressed: () => _showUserModal(context),
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

          // Search and Sort Row
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
                    hintText: 'Search system accounts...',
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
                    items: _sortOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
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
                : _filteredUsers.isEmpty
                    ? const Center(child: Text("No operational system users found matching filters.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        itemCount: _paginatedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _paginatedUsers[index];
                          final String status = user['status'] ?? 'Active';
                          final Color statusColor = user['color'] == 'blue' ? Colors.blue : Colors.green;

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
                                onTap: () => _showUserModal(context, user: Map<String, dynamic>.from(user)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // FIX: Expanded added to text so long names wrap instead of breaking the layout
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user['name'] ?? 'System User', 
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                          _iconText(Icons.business, user['company'] ?? 'Internal'),
                                          _iconText(Icons.email_outlined, user['email'] ?? 'No Email Bound'),
                                          _iconText(Icons.admin_panel_settings_outlined, user['role'] ?? 'Staff'),
                                          _iconText(Icons.verified_user_outlined, user['permission'] ?? 'Standard'),
                                        ],
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

          // FIX: FittedBox gracefully scales the pagination down on mobile
          if (!_isLoading && _filteredUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredUsers.length)} of ${_filteredUsers.length} system users',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
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

class RegisterUserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback? onDelete;

  const RegisterUserDialog({super.key, this.user, this.onDelete});

  @override
  State<RegisterUserDialog> createState() => _RegisterUserDialogState();
}

class _RegisterUserDialogState extends State<RegisterUserDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isWritingUnlocked = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  String? _selectedRole;
  String? _selectedCompany;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid ? 'http://10.0.2.2:5000/api' : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.user != null;
    _isWritingUnlocked = !isEdit;

    _nameController = TextEditingController(text: isEdit ? widget.user!['name'] : '');
    _emailController = TextEditingController(text: isEdit ? widget.user!['email'] : '');
    _passwordController = TextEditingController();

    if (isEdit) {
      _selectedRole = widget.user!['role'];
      _selectedCompany = widget.user!['company'] == 'Internal' ? 'None (Internal)' : widget.user!['company'];
    }
  }

  InputDecoration _fieldStyle({required String label, required IconData icon, bool forceDisable = false}) {
    final bool active = _isWritingUnlocked && !forceDisable;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF475569)),
      filled: true,
      fillColor: active ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
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

  Future<void> _submitUserForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final bool isEditMode = widget.user != null;

    try {
      final http.Response response;
      if (isEditMode) {
        response = await http.put(
          Uri.parse('$_backendUrl/auth/update-user/${widget.user!['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole,
            'company_name': _selectedCompany ?? 'None (Internal)',
          }),
        ).timeout(const Duration(seconds: 15));
      } else {
        response = await http.post(
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
      }

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) && responseData['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? "Account profile layout details synchronized!" : "User registered securely in the Auth Vault!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(responseData['message'] ?? "Request operation rejected.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
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
    final bool isEditMode = widget.user != null;

    return AlertDialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEditMode ? 'System User Profile Context' : 'Register System User',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF0F172A)),
      ),
      content: SizedBox(
        width: 500,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      readOnly: !_isWritingUnlocked,
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                      decoration: _fieldStyle(label: 'Full Name', icon: Icons.person),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: !_isWritingUnlocked,
                      validator: (val) => val == null || !val.contains('@') ? "Enter a valid email" : null,
                      decoration: _fieldStyle(label: 'Email Address', icon: Icons.email),
                    ),
                    const SizedBox(height: 16),
                    
                    if (!isEditMode) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _fieldStyle(label: 'Secure Password', icon: Icons.lock),
                        validator: (val) => val == null || val.length < 6 ? "Minimum 6 characters" : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      validator: (val) => val == null ? "Select a role" : null,
                      decoration: _fieldStyle(label: 'Assign Role', icon: Icons.admin_panel_settings),
                      onChanged: !_isWritingUnlocked ? null : (value) => setState(() => _selectedRole = value),
                      dropdownColor: const Color(0xFFF8FAFC),
                      items: ['Administrator', 'Dispatch Staff', 'Officer-in-Charge']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCompany,
                      decoration: _fieldStyle(label: 'Assign Company Account', icon: Icons.business),
                      onChanged: !_isWritingUnlocked ? null : (value) => setState(() => _selectedCompany = value),
                      dropdownColor: const Color(0xFFF8FAFC),
                      items: ['None (Internal)', 'GT Lantin Internal', 'EPSON', 'Bandai', 'NX Logistics']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
      actions: [
        // FIX: Replaced `Row` with `FittedBox` so the bottom buttons gracefully shrink to fit mobile screens
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isEditMode
                  ? TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onDelete != null) widget.onDelete!();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 24), // Give it some breathing room
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  if (isEditMode && !_isWritingUnlocked)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => setState(() => _isWritingUnlocked = true),
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
                      onPressed: _isLoading ? null : _submitUserForm,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditMode ? 'Save Changes' : 'Register User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}