import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class AdminFeedbacks extends StatefulWidget {
  const AdminFeedbacks({super.key});

  @override
  State<AdminFeedbacks> createState() => _AdminFeedbacksState();
}

class _AdminFeedbacksState extends State<AdminFeedbacks> {
  List<dynamic> _feedbacks = [];
  List<dynamic> _companySummaries = [];
  bool _isLoading = true;
  String? _selectedCompany;

  String get _backendUrl => kIsWeb ? 'http://127.0.0.1:5000/api' : 'http://10.0.2.2:5000/api';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final feedRes = await http.get(Uri.parse('$_backendUrl/evaluations/mutual'));
      final sumRes = await http.get(Uri.parse('$_backendUrl/evaluations/summary'));
      
      if (feedRes.statusCode == 200 && sumRes.statusCode == 200) {
        setState(() {
          _feedbacks = jsonDecode(feedRes.body)['evaluations'] ?? [];
          _companySummaries = jsonDecode(sumRes.body) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtered list based on card selection
    final filtered = _selectedCompany == null 
        ? _feedbacks 
        : _feedbacks.where((f) => (f['oic_profile'] ?? {})['company_name'] == _selectedCompany).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Back')),
          const SizedBox(height: 16),
          const Text('Global Performance Ledger', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),

          Row(
            children: _companySummaries.map((s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCompany = (_selectedCompany == s['name'] ? null : s['name'])),
                  child: _buildCompanyRatingCard(s['name'], s['avg'].toString(), s['count'], _selectedCompany == s['name']),
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          ...filtered.map((f) => _buildDriverFeedbackCard(
            driverName: 'Trip ID: ${f['trip_id']}', 
            assignedCompany: (f['oic_profile'] ?? {})['company_name'] ?? 'Unknown',
            rating: f['overall_rating'].toString(),
            recentComment: f['comments'],
            date: f['submit_date'],
          )),
        ],
      ),
    );
  }

  Widget _buildCompanyRatingCard(String name, String avg, int count, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? Colors.blue.shade900 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(avg, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
          Text('$count reviews', style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDriverFeedbackCard({required String driverName, required String assignedCompany, required String rating, required String recentComment, required String date}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)), Text('Client: $assignedCompany')]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20)), child: Text('Rating: $rating')),
            ],
          ),
          const Divider(),
          Text('Remarks ($date):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(recentComment),
        ],
      ),
    );
  }
}