import 'package:flutter/material.dart';


class StaffAttendance extends StatefulWidget {
  const StaffAttendance({super.key});

  @override
  State<StaffAttendance> createState() => _StaffAttendanceState();
}

class _StaffAttendanceState extends State<StaffAttendance> {
  String _filterQuery = '';

  // Redesigned to prioritize physiological outcomes (rest periods and fatigue)
  final List<Map<String, dynamic>> _attendanceLogs = [
    { "id": 1, "name": "Juan Dela Cruz", "initials": "JD", "time": "05:48 AM", "rest": "8.5 hrs", "status": "Cleared", "route": "EPSON - Shift A" },
    { "id": 2, "name": "Ricardo Ramos", "initials": "RR", "time": "06:02 AM", "rest": "4.0 hrs", "status": "Fatigue Risk", "route": "Bandai - Shift A" },
    { "id": 3, "name": "Miguel Santos", "initials": "MS", "time": "05:55 AM", "rest": "7.2 hrs", "status": "Cleared", "route": "NX Logistics" },
    { "id": 4, "name": "Antonio Luna", "initials": "AL", "time": "05:30 AM", "rest": "5.5 hrs", "status": "Monitor", "route": "EPSON - Shift B" },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Cleared': return Colors.green;
      case 'Monitor': return Colors.amber.shade700;
      case 'Fatigue Risk': return Colors.red.shade600;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _attendanceLogs.where((log) => log['name'].toString().toLowerCase().contains(_filterQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Physiological Monitoring', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.health_and_safety, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text('Tracking driver rest intervals for XXXXX', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildQuickStatCard('Cleared for Duty', '42', '/59', Colors.green.shade600),
                  const SizedBox(width: 16),
                  _buildQuickStatCard('High Fatigue', '3', ' Drivers', Colors.red.shade600),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(11)), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shift Check-in & Rest Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(
                        width: 280, height: 40,
                        child: TextField(
                          onChanged: (val) => setState(() => _filterQuery = val),
                          decoration: InputDecoration(hintText: 'Filter by driver name...', prefixIcon: const Icon(Icons.search, size: 18), filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200))),
                        ),
                      )
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final Color statusColor = _getStatusColor(log['status']);
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade100, child: Text(log['initials'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14))),
                              const SizedBox(width: 16),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 2), Text(log['route'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500))])
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Prior Rest', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                  Text(log['rest'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 24),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.08), border: Border.all(color: statusColor.withOpacity(0.3)), borderRadius: BorderRadius.circular(6)), child: Text(log['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor))),
                              const SizedBox(width: 16),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)), child: Text(log['time'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))))
                            ],
                          )
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String mainValue, String subValue, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          RichText(text: TextSpan(text: mainValue, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor), children: [if (subValue.isNotEmpty) TextSpan(text: subValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400))]))
        ],
      ),
    );
  }
}