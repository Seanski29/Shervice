import 'package:flutter/material.dart';

class OicSchedules extends StatelessWidget {
  const OicSchedules({super.key});

  final List<String> daysOfWeek = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    // Mock Data Mapping
    final Map<int, List<Map<String, dynamic>>> scheduledLoads = {
      12: [{'time': 'Morning', 'count': 4}, {'time': 'Night', 'count': 2}],
      15: [{'time': 'Morning', 'count': 5}],
      18: [{'time': 'Special', 'count': 1}],
      24: [{'time': 'Morning', 'count': 6}, {'time': 'Night', 'count': 4}],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deployment Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Manage monthly fleet deployment schedules and trip assignments.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300))),
                          child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('New Schedule', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Calendar Wrapper
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                // Month Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text('May 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                // Days Header
                Row(
                  children: daysOfWeek.map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                      child: Text(day.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                    ),
                  )).toList(),
                ),
                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.8),
                  itemCount: 35,
                  itemBuilder: (context, index) {
                    final dayNum = index - 4; // Shift to simulate starting day
                    final isValidDate = dayNum > 0 && dayNum <= 31;
                    final events = isValidDate ? scheduledLoads[dayNum] : null;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100, width: 0.5),
                        color: isValidDate ? Colors.white : Colors.grey.shade50,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: !isValidDate ? const SizedBox() : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: dayNum == 12 ? Colors.blue.shade600 : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, color: dayNum == 12 ? Colors.white : Colors.grey.shade700)),
                          ),
                          const SizedBox(height: 4),
                          if (events != null) ...events.map((event) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade100)),
                            child: Text('${event['count']} Trips • ${event['time']}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700), overflow: TextOverflow.ellipsis),
                          )),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}