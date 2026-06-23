import 'package:flutter/material.dart';

class AdminFeedbacks extends StatelessWidget {
  const AdminFeedbacks({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Added a Scaffold to provide the Material theme canvas. 
    // This stops Flutter from using the giant yellow fallback text.
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Matches your dashboard background
      body: SafeArea(
        child: ListView(
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

            // SECTION 1: Client Company Ratings (How companies rate the assigned drivers)
            const Text('CLIENT COMPANY RATINGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildCompanyRatingCard('EPSON', '4.8', 124, Colors.blue.shade700),
                _buildCompanyRatingCard('Bandai', '4.6', 89, Colors.orange.shade700),
                _buildCompanyRatingCard('NX Logistics', '4.9', 56, Colors.green.shade700),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // SECTION 2: Individual Driver Ratings
            const Text('DRIVER PERFORMANCE FEEDBACKS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            
            _buildDriverFeedbackCard(
              driverName: 'Ricardo Ramos',
              assignedCompany: 'EPSON',
              rating: '4.9',
              recentComment: '"Very punctual and drives safely. The employees appreciate the smooth ride every morning."',
              date: 'Jun 20, 2026',
            ),
            _buildDriverFeedbackCard(
              driverName: 'Miguel Santos',
              assignedCompany: 'Bandai',
              rating: '4.2',
              recentComment: '"Driver was a bit late due to traffic, but communication was good. AC in the van could be colder."',
              date: 'Jun 19, 2026',
            ),
            _buildDriverFeedbackCard(
              driverName: 'Juan Dela Cruz',
              assignedCompany: 'NX Logistics',
              rating: '4.8',
              recentComment: '"Excellent service. Always on standby exactly when the shift ends."',
              date: 'Jun 18, 2026',
            ),

            const SizedBox(height: 16),
            _buildResponsivePagination('1 to 3 of 42 drivers'),
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

  Widget _buildResponsivePagination(String text) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16, runSpacing: 16,
      children: [
        Text('Showing $text', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Prev', style: TextStyle(color: Colors.black87))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Next', style: TextStyle(color: Colors.black87))),
          ],
        )
      ],
    );
  }
}