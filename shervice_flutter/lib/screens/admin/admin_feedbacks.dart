import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminFeedbacks extends StatefulWidget {
  const AdminFeedbacks({super.key});

  @override
  State<AdminFeedbacks> createState() => _AdminFeedbacksState();
}

class _AdminFeedbacksState extends State<AdminFeedbacks> {
  // --- State Variables ---
  bool _isLoading = true;
  List<dynamic> _companyRatings = [];
  List<dynamic> _driverFeedbacks = [];

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
    _fetchFeedbacks();
  }

  // --- Data Fetching & Processing ---
  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/evaluations/all'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _companyRatings = data['company_ratings'] ?? [];
          _driverFeedbacks = data['driver_feedbacks'] ?? [];
        } else {
          _loadDummyData();
        }
      } else {
        _loadDummyData();
      }
    } catch (e) {
      debugPrint("❌ Error fetching feedbacks: $e");
      // Fallback to dummy data if endpoint is unavailable to keep UI operational
      _loadDummyData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadDummyData() {
    _companyRatings = [
      {'company': 'EPSON', 'rating': '4.8', 'reviews': 124},
      {'company': 'Bandai', 'rating': '4.6', 'reviews': 89},
      {'company': 'NX Logistics', 'rating': '4.9', 'reviews': 56},
    ];
    _driverFeedbacks = [
      {'driver_name': 'Ricardo Ramos', 'company': 'EPSON', 'rating': '4.9', 'comment': '"Very punctual and drives safely. The employees appreciate the smooth ride every morning."', 'date': 'Jun 20, 2026'},
      {'driver_name': 'Miguel Santos', 'company': 'Bandai', 'rating': '4.2', 'comment': '"Driver was a bit late due to traffic, but communication was good. AC in the van could be colder."', 'date': 'Jun 19, 2026'},
      {'driver_name': 'Juan Dela Cruz', 'company': 'NX Logistics', 'rating': '4.8', 'comment': '"Excellent service. Always on standby exactly when the shift ends."', 'date': 'Jun 18, 2026'},
      {'driver_name': 'Arthur Reyes', 'company': 'EPSON', 'rating': '5.0', 'comment': '"Perfect driving record. Highly recommended!"', 'date': 'Jun 17, 2026'},
      {'driver_name': 'Lando Garcia', 'company': 'NX Logistics', 'rating': '3.9', 'comment': '"Good driver but missed a turn today. Could improve routing."', 'date': 'Jun 16, 2026'},
    ];
  }

  // --- Pagination Logic ---
  int get _totalPages => (_driverFeedbacks.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedFeedbacks {
    if (_driverFeedbacks.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _driverFeedbacks.length);
    return _driverFeedbacks.sublist(start, end);
  }

  void _nextPage() => _currentPage < _totalPages - 1 ? setState(() => _currentPage++) : null;
  void _prevPage() => _currentPage > 0 ? setState(() => _currentPage--) : null;

  Color _getCompanyColor(int index) {
    final colors = [
      Colors.blue.shade700,
      Colors.orange.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Matches dashboard background
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Back Button to return to User Management
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Back to Users', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Company & Driver Feedbacks',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text('Monitor client satisfaction and driver performance metrics.', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 32),

                  // SECTION 1: Client Company Ratings
                  const Text('CLIENT COMPANY RATINGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  
                  if (_companyRatings.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text("No company ratings available."))
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _companyRatings.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildCompanyRatingCard(
                          item['company'] ?? 'Unknown',
                          item['rating']?.toString() ?? '0.0',
                          item['reviews'] ?? 0,
                          _getCompanyColor(index),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // SECTION 2: Individual Driver Ratings
                  const Text('DRIVER PERFORMANCE FEEDBACKS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  
                  if (_driverFeedbacks.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text("No driver feedback logs available."))
                  else ...[
                    ..._paginatedFeedbacks.map((feedback) => _buildDriverFeedbackCard(
                      driverName: feedback['driver_name'] ?? 'Unknown Driver',
                      assignedCompany: feedback['company'] ?? 'Unknown Company',
                      rating: feedback['rating']?.toString() ?? '0.0',
                      recentComment: feedback['comment'] ?? 'No comment provided.',
                      date: feedback['date'] ?? 'N/A',
                    )),
                    
                    const SizedBox(height: 16),
                    _buildResponsivePagination(),
                  ],
                ],
              ),
      ),
    );
  }

  // Card showing the average rating given by a specific company
  Widget _buildCompanyRatingCard(String companyName, String avgRating, int totalReviews, Color brandColor) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: brandColor),
              const SizedBox(width: 8),
              Text(companyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(avgRating, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Icon(Icons.star, color: Colors.amber, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Based on $totalReviews trip reviews', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  // Card showing individual driver feedback
  Widget _buildDriverFeedbackCard({
    required String driverName,
    required String assignedCompany,
    required String rating,
    required String recentComment,
    required String date,
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
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Assigned to: $assignedCompany', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text('$rating Avg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Text('Recent OIC Comment ($date):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(recentComment, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildResponsivePagination() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight, 
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16, 
        runSpacing: 16,
        children: [
          Text(
            'Showing ${(_currentPage * _itemsPerPage) + 1} to ${min((_currentPage + 1) * _itemsPerPage, _driverFeedbacks.length)} of ${_driverFeedbacks.length} reviews', 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _currentPage > 0 ? _prevPage : null, 
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                child: const Text('Prev', style: TextStyle(color: Colors.black87))
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)), 
                child: Text('${_currentPage + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
              OutlinedButton(
                onPressed: _currentPage < _totalPages - 1 ? _nextPage : null, 
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                child: const Text('Next', style: TextStyle(color: Colors.black87))
              ),
            ],
          )
        ],
      ),
    );
  }
}