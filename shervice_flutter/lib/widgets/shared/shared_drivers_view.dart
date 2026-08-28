import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';
import '../driver/driver_profile_model.dart';
import '../../constant.dart';
import '../driver/driver_rating_badge.dart';

class SharedDriversView extends StatefulWidget {
  final bool canManage;
  final String title;
  final String subtitle;
  final Widget? actionWidget;
  final Function(BuildContext context, DriverProfileModel? driver)? onDriverTapped;

  const SharedDriversView({
    super.key,
    required this.canManage,
    required this.title,
    required this.subtitle,
    this.actionWidget,
    this.onDriverTapped,
  });

  @override
  State<SharedDriversView> createState() => SharedDriversViewState();
}

class SharedDriversViewState extends State<SharedDriversView> {
  bool _isLoading = true;
  bool _isRefreshing = false;
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
  final int _itemsPerPage = 10; // Increased items per page for better screen utilization

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
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    final String url = '$backendUrl/test-db';
    debugPrint("🔍 Fetching drivers from: $url");

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['connection_status'] == 'SUCCESS') {
          final List<dynamic> rawList = data['sample_data_payload'] ?? [];
          if (mounted) {
            setState(() {
              _allDrivers = rawList.map((json) => DriverProfileModel.fromJson(json)).toList();
            });
          }
        }
      } else {
        debugPrint("⚠️ Server returned non-200 status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error reading live driver profile streams: $e");
    } finally {
      if (mounted) {
        _applyFiltersAndSort();
        setState(() => _isRefreshing = false);
      }
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

  int get _totalPages => max(1, (_filteredDrivers.length / _itemsPerPage).ceil());

  List<DriverProfileModel> get _paginatedDrivers {
    if (_isLoading) {
      return List.generate(5, (index) => DriverProfileModel(
        id: 'skeleton-$index', userId: 'skeleton-$index', name: 'Loading Driver',
        email: 'loading@example.com', licenseNumber: 'Loading', birthday: '1995-01-01',
        rating: 0, status: 'Active', dateHired: 'Loading', licenseExpiry: 'Loading',
      ));
    }
    if (_filteredDrivers.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _filteredDrivers.length);
    return _filteredDrivers.sublist(start, end);
  }

  // --- Stats Calculations ---
  int get _totalDrivers => _allDrivers.length;
  int get _activeDrivers => _allDrivers.where((d) => d.status.toLowerCase() == 'active').length;
  int get _inactiveDrivers => _totalDrivers - _activeDrivers;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Skeletonizer(
      enabled: _isLoading,
      child: RefreshIndicator(
      onRefresh: _fetchDriversFromDatabase,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER & ACTIONS ───
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleArea(isDark),
                      const SizedBox(height: 16),
                      _buildSearchAndFilterRow(isDark, isMobile),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTitleArea(isDark),
                      const Spacer(), // Pushes everything below to the far right!
                      _buildSearchAndFilterRow(isDark, isMobile),
                    ],
                  ),
            const SizedBox(height: 24),

            // ─── TOP SUMMARY STATS (Pills) ───
            if (!_isLoading && _allDrivers.isNotEmpty) 
              _buildTopSummaryStats(isDark, isMobile),
            const SizedBox(height: 24),

            // ─── DRIVER LIST ───
            if (!_isLoading && _filteredDrivers.isEmpty)
              _buildEmptyState(isDark)
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paginatedDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = _paginatedDrivers[index];
                        return _buildDriverCard(driver, isDark, index == _paginatedDrivers.length - 1);
                      },
                    ),
                    // ─── PAGINATION ───
                    _buildPaginationFooter(isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTitleArea(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow(bool isDark, bool isMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Box
        SizedBox(
          width: isMobile ? double.infinity : 220,
          height: 40,
          child: TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFiltersAndSort();
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search driver name...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
            ),
          ),
        ),
        // Sort Dropdown
        Container(
          height: 40,
          width: isMobile ? double.infinity : 160,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _currentSort,
              icon: const Icon(Icons.sort, size: 18, color: Color(0xFF64748B)),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
        // Refresh Button
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: Colors.blue.shade600, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: _isRefreshing ? null : refreshData,
            icon: _isRefreshing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                : const Icon(Icons.refresh, color: Colors.blue, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        // Add Button
        if (widget.actionWidget != null)
          SizedBox(height: 40, child: widget.actionWidget!),
      ],
    );
  }

  Widget _buildTopSummaryStats(bool isDark, bool isMobile) {
    final List<Map<String, dynamic>> stats = [
      {'label': 'Total Drivers', 'value': _totalDrivers.toString(), 'icon': Icons.people_outline, 'color': isDark ? Colors.grey.shade400 : Colors.grey.shade600},
      {'label': 'Active Duty', 'value': _activeDrivers.toString(), 'icon': Icons.check_circle_outline, 'color': const Color(0xFF10B981)},
      {'label': 'Inactive/Leave', 'value': _inactiveDrivers.toString(), 'icon': Icons.pause_circle_outline, 'color': const Color(0xFFF59E0B)},
    ];

    Widget buildCard(Map<String, dynamic> stat) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stat['icon'], color: stat['color'], size: 28),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  stat['value'],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                Text(
                  stat['label'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => buildCard(stat)).toList(),
      );
    } else {
      return Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: stat == stats.last ? 0 : 16.0),
              child: buildCard(stat),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No drivers found matching your criteria.',
              style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverProfileModel driver, bool isDark, bool isLast) {
    final Color statusColor = (driver.status.toLowerCase() == 'active') ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () {
        if (widget.onDriverTapped != null) {
          widget.onDriverTapped!(context, driver);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left indicator bar
            Container(
              width: 4,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _cardIconText(Icons.badge_outlined, "ID: ${driver.id}", isDark),
                      _cardIconText(Icons.card_membership, "Lic: ${driver.licenseNumber}", isDark),
                      _cardIconText(Icons.event_available, "Hired: ${driver.dateHired}", isDark),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DriverRatingBadge(
                          key: UniqueKey(),
                          driverUuid: driver.userId,
                          backendUrl: backendUrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Content
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driver.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.grey.shade600 : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardIconText(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.grey.shade500 : const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _filteredDrivers.length)} of ${_filteredDrivers.length}',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text('Prev', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentPage + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text('Next', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
