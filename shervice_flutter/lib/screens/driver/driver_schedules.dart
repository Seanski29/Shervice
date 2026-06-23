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
        _buildScheduleCard(
          date: 'Today, Jun 21',
          shift: 'Shift 1',
          pickupLoc: 'Lipa City Terminal',
          pickupTime: '05:45 AM',
          dropoffLoc: 'LIMA Estate (EPSON)',
          dropoffTime: '06:30 AM',
          status: 'Ongoing',
        ),
        _buildScheduleCard(
          date: 'Yesterday, Jun 20',
          shift: 'Shift 1',
          pickupLoc: 'Lipa City Terminal',
          pickupTime: '06:15 AM',
          dropoffLoc: 'LIMA Estate (EPSON)',
          dropoffTime: '07:10 AM',
          status: 'Late',
        ),
        _buildScheduleCard(
          date: 'Tuesday, Jun 19',
          shift: 'Shift 2',
          pickupLoc: 'FPIP Transport Hub',
          pickupTime: '01:30 PM',
          dropoffLoc: 'NX Logistics',
          dropoffTime: '02:15 PM',
          status: 'Done',
        ),
        _buildScheduleCard(
          date: 'Tomorrow, Jun 22',
          shift: 'Shift 1',
          pickupLoc: 'Lipa City Terminal',
          pickupTime: '05:45 AM',
          dropoffLoc: 'LIMA Estate (EPSON)',
          dropoffTime: '06:30 AM',
          status: 'Upcoming',
        ),
      ],
    );
  }

  Widget _buildScheduleCard({
    required String date,
    required String shift,
    required String pickupLoc,
    required String pickupTime,
    required String dropoffLoc,
    required String dropoffTime,
    required String status,
  }) {
    // Dynamic Status Color Engine
    Color statusColor;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'ongoing':
        statusColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        break;
      case 'late':
        statusColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;
      case 'done':
        statusColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        break;
      case 'upcoming':
      default:
        statusColor = Colors.grey.shade600;
        bgColor = Colors.grey.shade100;
        break;
    }

    bool isHighlighted = status.toLowerCase() == 'ongoing' || status.toLowerCase() == 'late';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? statusColor.withOpacity(0.5) : Colors.grey.shade200, width: isHighlighted ? 2 : 1),
        boxShadow: [
          if (isHighlighted) BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Date & Dynamic Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isHighlighted ? statusColor : Colors.grey.shade800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            
            // Shift Information
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(shift, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline View for Pick-up and Drop-off
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle_outlined, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(child: Text(pickupLoc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text(pickupTime, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
              width: 2,
              height: 20,
              color: Colors.grey.shade300,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.red.shade500),
                const SizedBox(width: 12),
                Expanded(child: Text(dropoffLoc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text(dropoffTime, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}