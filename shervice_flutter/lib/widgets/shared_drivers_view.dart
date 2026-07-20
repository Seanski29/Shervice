import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/driver_profile_model.dart';
import '../constant.dart';
import 'driver_rating_badge.dart';

class SharedDriversView extends StatefulWidget {
  final bool canManage;
  final Widget customHeader;
  final Function(BuildContext context, DriverProfileModel? driver)? onDriverTapped;

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

    final String url = '$backendUrl/test-db';
    debugPrint("🔍 Fetching drivers from: $url");

    try {
      final response = await http
          .get(Uri.parse(url))
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
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.customHeader,
          const SizedBox(height: 20),

          // Search & Sort
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
                      hintText: 'Search by name or letter...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
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
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _currentSort,
                        icon: const Icon(Icons.sort, size: 18, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        items: _sortOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _currentSort = val;
                              _applyFiltersAndSort();
                            });
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

          // Driver List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
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
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), // reduced from 12
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                onTap: () {
                                  if (widget.onDriverTapped != null) {
                                    widget.onDriverTapped!(context, driver);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, // reduced from 16
                                    vertical: 8,   // reduced from 12
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Left indicator – smaller height
                                      Container(
                                        width: 4,
                                        height: 36, // reduced from 50
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
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    driver.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                      fontSize: 15, // reduced from 16
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
                                                    driver.status,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 8, // reduced from 9
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2), // reduced from 4
                                            Wrap(
                                              spacing: 10, // reduced from 14
                                              runSpacing: 2,
                                              children: [
                                                DriverRatingBadge(
                                                  key: UniqueKey(),
                                                  driverUuid: driver.userId,
                                                  backendUrl: backendUrl,
                                                ),
                                                _infoChip(
                                                  Icons.badge_outlined,
                                                  "License: ${driver.licenseNumber}",
                                                ),
                                                _infoChip(
                                                  Icons.calendar_today_outlined,
                                                  "Expiry: ${driver.licenseExpiry}",
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

          // Pagination (unchanged)
          if (!_isLoading && _filteredDrivers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredDrivers.length)} of ${_filteredDrivers.length} drivers',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
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
                            ? () => setState(() => _currentPage++)
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
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)), // reduced from 13
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11, // reduced from 12
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}