import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/driver_profile_model.dart';
import '../constant.dart';

class SharedDriversView extends StatefulWidget {
  final bool canManage;
  final Widget customHeader;
  final Function(BuildContext context, DriverProfileModel? driver)?
  onDriverTapped;

  const SharedDriversView({
    super.key,
    required this.canManage,
    required this.customHeader,
    this.onDriverTapped,
  });

  @override
  State<SharedDriversView> createState() => SharedDriversViewState();
}

class SharedDriversViewState extends State<SharedDriversView> {
  bool _isLoading = true;
  List<DriverProfileModel> _allDrivers = [];
  List<DriverProfileModel> _filteredDrivers = [];

  String _searchQuery = '';
  String _currentSort = 'A to Z';
  final List<String> _sortOptions = [
    'A to Z',
    'Z to A',
    'Rating (High-Low)',
    'Rating (Low-High)',
  ];

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchDriversFromDatabase();
  }

  void refreshData() {
    _fetchDriversFromDatabase();
  }

  Future<void> _fetchDriversFromDatabase() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Construct the path dynamically using the constant
    final String url = '$backendUrl/test-db';
    debugPrint("🔍 Fetching drivers from: $url");

    try {
      final response = await http
          .get(Uri.parse(url)) // Use the URL built with backendUrl
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['connection_status'] == 'SUCCESS') {
          final List<dynamic> rawList = data['sample_data_payload'] ?? [];
          if (mounted) {
            setState(() {
              _allDrivers = rawList
                  .map((json) => DriverProfileModel.fromJson(json))
                  .toList();
            });
          }
        }
      } else {
        debugPrint("⚠️ Server returned non-200 status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error reading live driver profile streams: $e");
    } finally {
      if (mounted) _applyFiltersAndSort();
    }
  }

  void _applyFiltersAndSort() {
    List<DriverProfileModel> temp = _allDrivers.where((driver) {
      return driver.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    temp.sort((a, b) {
      switch (_currentSort) {
        case 'Z to A':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case 'Rating (High-Low)':
          return b.rating.compareTo(a.rating);
        case 'Rating (Low-High)':
          return a.rating.compareTo(b.rating);
        case 'A to Z':
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    setState(() {
      _filteredDrivers = temp;
      _currentPage = 0;
      _isLoading = false;
    });
  }

  int get _totalPages => (_filteredDrivers.length / _itemsPerPage).ceil();

  List<DriverProfileModel> get _paginatedDrivers {
    if (_filteredDrivers.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredDrivers.length);
    return _filteredDrivers.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.customHeader,
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
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _currentSort = val;
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
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active drivers found.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _paginatedDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = _paginatedDrivers[index];
                      final Color statusColor = (driver.status == 'Active')
                          ? Colors.green
                          : Colors.orange;

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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(
                              driver.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber.shade600,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              driver.rating.toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          driver.status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "License: ${driver.licenseNumber} • Expiry: ${driver.licenseExpiry}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (widget.onDriverTapped != null) {
                                widget.onDriverTapped!(context, driver);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // FIX: Responsive, scalable pagination wrapped in FittedBox
          if (!_isLoading && _filteredDrivers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredDrivers.length)} of ${_filteredDrivers.length} drivers',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
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
                              ? () => setState(() => _currentPage++)
                              : null,
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
}
