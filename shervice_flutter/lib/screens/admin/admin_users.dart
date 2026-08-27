import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constant.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchSystemUsers();
  }

  Future<void> _fetchSystemUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/auth/system-users'))
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

  void _nextPage() =>
      _currentPage < _totalPages - 1 ? setState(() => _currentPage++) : null;
  void _prevPage() => _currentPage > 0 ? setState(() => _currentPage--) : null;

  void _confirmPurgeUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently revoke accesses and delete system account records for ${user['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final res = await http
                    .delete(
                      Uri.parse('$backendUrl/auth/delete-user/${user['id']}'),
                    )
                    .timeout(const Duration(seconds: 10));

                if (res.statusCode == 200) {
                  _showSnackBar(
                    'User identity context completely deleted.',
                    const Color(0xFFF59E0B),
                  );
                } else {
                  _showSnackBar(
                    'Purge validation request rejected by server.',
                    const Color(0xFFEF4444),
                  );
                }
              } catch (e) {
                _showSnackBar(
                  'Network layer timing exception error.',
                  const Color(0xFFEF4444),
                );
              } finally {
                _fetchSystemUsers();
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
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchSystemUsers,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- HEADER -----
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage system users, roles, and access permissions.',
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
                    onPressed: () => _showUserModal(context),
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Register User',
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

              // ----- SEARCH & SORT -----
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
                          hintText: 'Search system accounts...',
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

              // ----- USER LIST -----
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                    : _filteredUsers.isEmpty
                        ? Center(
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
                                  'No system users found.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _paginatedUsers.length,
                            itemBuilder: (context, index) {
                              final user = _paginatedUsers[index];
                              final String status = user['status'] ?? 'Active';
                              final Color statusColor = (status == 'Active')
                                  ? const Color(0xFF10B981) // green
                                  : const Color(0xFFF59E0B); // yellow

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
                                    onTap: () => _showUserModal(
                                      context,
                                      user: Map<String, dynamic>.from(user),
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
                                              color: statusColor,
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
                                                        user['name'] ?? 'System User',
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
                                                        color: statusColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        status,
                                                        style: TextStyle(
                                                          color: statusColor,
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
                                                      Icons.business,
                                                      user['company'] ?? 'Internal',
                                                    ),
                                                    _iconText(
                                                      Icons.email_outlined,
                                                      user['email'] ?? 'No Email',
                                                    ),
                                                    _iconText(
                                                      Icons.admin_panel_settings_outlined,
                                                      user['role'] ?? 'Staff',
                                                    ),
                                                    _iconText(
                                                      Icons.verified_user_outlined,
                                                      user['permission'] ?? 'Standard',
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
              if (!_isLoading && _filteredUsers.isNotEmpty)
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
                          'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredUsers.length)} of ${_filteredUsers.length} users',
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
// REGISTER USER DIALOG (light mode only)
// ============================================================================
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

  @override
  void initState() {
    super.initState();
    final bool isEdit = widget.user != null;
    _isWritingUnlocked = !isEdit;

    _nameController = TextEditingController(
      text: isEdit ? widget.user!['name'] : '',
    );
    _emailController = TextEditingController(
      text: isEdit ? widget.user!['email'] : '',
    );
    _passwordController = TextEditingController();

    if (isEdit) {
      _selectedRole = widget.user!['role'];
      _selectedCompany = widget.user!['company'] == 'Internal'
          ? 'None (Internal)'
          : widget.user!['company'];
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

  Future<void> _submitUserForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final bool isEditMode = widget.user != null;

    try {
      final http.Response response;
      if (isEditMode) {
        response = await http
            .put(
              Uri.parse('$backendUrl/auth/update-user/${widget.user!['id']}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'full_name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'role': _selectedRole,
                'company_name': _selectedCompany ?? 'None (Internal)',
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (_passwordController.text.isNotEmpty) {
          final passResponse = await http
              .post(
                Uri.parse('$backendUrl/auth/update-password'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'user_id': widget.user!['id'],
                  'new_password': _passwordController.text,
                }),
              )
              .timeout(const Duration(seconds: 10));

          final passData = jsonDecode(passResponse.body);
          if (passResponse.statusCode != 200 || passData['success'] != true) {
            throw Exception(
              passData['message'] ?? "Failed to override password.",
            );
          }
        }
      } else {
        response = await http
            .post(
              Uri.parse('$backendUrl/auth/register-staff-oic'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': _emailController.text.trim(),
                'password': _passwordController.text,
                'role': _selectedRole,
                'company_name': _selectedCompany ?? 'None (Internal)',
                'full_name': _nameController.text.trim(),
              }),
            )
            .timeout(const Duration(seconds: 15));
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
                  ? "Account profile synchronized!"
                  : "User registered successfully!",
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(
          responseData['message'] ?? "Request operation rejected.",
        );
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.user != null;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 520,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditMode ? 'System User Profile' : 'Register System User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form (scrollable)
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        readOnly: !_isWritingUnlocked,
                        validator: (val) =>
                            val == null || val.isEmpty ? "Required" : null,
                        decoration: _fieldStyle(
                          label: 'Full Name',
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        readOnly: !_isWritingUnlocked,
                        validator: (val) => val == null || !val.contains('@')
                            ? "Enter a valid email"
                            : null,
                        decoration: _fieldStyle(
                          label: 'Email Address',
                          icon: Icons.email,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        readOnly: !_isWritingUnlocked,
                        decoration: _fieldStyle(
                          label: isEditMode
                              ? 'Reset Password (Leave empty to keep current)'
                              : 'Secure Password',
                          icon: Icons.lock_reset,
                        ),
                        validator: (val) {
                          if (!isEditMode && (val == null || val.length < 6)) {
                            return "Minimum 6 characters required";
                          }
                          if (isEditMode &&
                              val != null &&
                              val.isNotEmpty &&
                              val.length < 6) {
                            return "Minimum 6 characters required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        validator: (val) => val == null ? "Select a role" : null,
                        decoration: _fieldStyle(
                          label: 'Assign Role',
                          icon: Icons.admin_panel_settings,
                        ),
                        onChanged: !_isWritingUnlocked
                            ? null
                            : (value) => setState(() => _selectedRole = value),
                        dropdownColor: Colors.white,
                        items: ['Dispatch Staff', 'Officer-in-Charge']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedCompany,
                        decoration: _fieldStyle(
                          label: 'Assign Company Account',
                          icon: Icons.business,
                        ),
                        onChanged: !_isWritingUnlocked
                            ? null
                            : (value) => setState(() => _selectedCompany = value),
                        dropdownColor: Colors.white,
                        items: [
                          'GT LANTIN INTERNAL',
                          'EPSON',
                          'Bandai',
                          'NX Logistics',
                        ]
                            .map(
                              (e) =>
                                  DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions (responsive wrap)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isEditMode)
                  TextButton(
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
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    if (isEditMode && !_isWritingUnlocked)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64748B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () =>
                            setState(() => _isWritingUnlocked = true),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitUserForm,
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
                                isEditMode ? 'Save Changes' : 'Register User',
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
        ),
      ),
    );
  }
}