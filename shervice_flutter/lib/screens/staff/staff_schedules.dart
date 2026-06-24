import 'package:flutter/material.dart';

class StaffSchedules extends StatelessWidget {
  const StaffSchedules({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = [
      {"route": "LIMA Estate (EPSON)", "shift": "Shift 1", "time": "06:00 AM", "driver": "Juan Dela Cruz", "van": "ABC-1234"},
      {"route": "Malvar (Bandai Namco)", "shift": "Shift 1", "time": "06:30 AM", "driver": "Ricardo Ramos", "van": "XYZ-5678"},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dispatch & Scheduling', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white, size: 18), label: const Text('New Dispatch', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedules.length, separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = schedules[i];
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['route']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text(s['time']!, style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: Text(s['shift']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                                ])
                              ],
                            ),
                            Row(children: [
                              const Icon(Icons.person, color: Colors.grey, size: 20), const SizedBox(width: 4), Text(s['driver']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              const Icon(Icons.local_shipping, color: Colors.grey, size: 20), const SizedBox(width: 4), Text(s['van']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ])
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignment Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Units', style: TextStyle(color: Colors.grey)), const Text('18', style: TextStyle(fontWeight: FontWeight.bold))]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Available Drivers', style: TextStyle(color: Colors.grey)), const Text('7', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Standby Vehicles', style: TextStyle(color: Colors.grey)), const Text('4', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome, color: Colors.blue), label: const Text('Optimize Matrix', style: TextStyle(color: Colors.black87)))),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}