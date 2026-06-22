import 'package:flutter/material.dart';

class DriverSchedules extends StatelessWidget {
  const DriverSchedules({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text(
          'My Schedule',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Text('June 2026', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 24),

        // Timeline / Agenda View
        _buildScheduleCard('Today, Jun 21', '06:00 AM - Shift 1', 'LIMA Estate (EPSON)', true),
        _buildScheduleCard('Tomorrow, Jun 22', '06:00 AM - Shift 1', 'LIMA Estate (EPSON)', false),
        _buildScheduleCard('Wednesday, Jun 24', '02:00 PM - Shift 2', 'FPIP (NX Logistics)', false),
        _buildScheduleCard('Thursday, Jun 25', '02:00 PM - Shift 2', 'FPIP (NX Logistics)', false),
      ],
    );
  }

  Widget _buildScheduleCard(String date, String time, String destination, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isToday ? Colors.blue.shade300 : Colors.grey.shade200, width: isToday ? 2 : 1),
        boxShadow: [
          if (isToday) BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? Colors.blue.shade700 : Colors.grey.shade700)),
                if (isToday) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('Next Up', style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(destination, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}