import 'package:flutter/material.dart';

class StaffVehicle extends StatelessWidget {
  const StaffVehicle({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicles = [
      {"plate": "GT-VAN-012", "model": "Toyota Hiace Commuter", "cap": "15 Seats", "cond": "Excellent", "status": "Active (On Route)"},
      {"plate": "GT-VAN-008", "model": "Nissan Urvan NV350", "cap": "15 Seats", "cond": "Good", "status": "Active (On Route)"},
      {"plate": "GT-VAN-022", "model": "Toyota Hiace GL", "cap": "12 Seats", "cond": "Needs Maintenance", "status": "Garage"},
    ];

    Color getStatusColor(String s) {
      if (s.contains('Active')) return Colors.green;
      if (s.contains('Garage')) return Colors.red;
      return Colors.blue;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fleet Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Monitor vehicle status, capacity, and maintenance.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Register Vehicle', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
              )
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2),
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final v = vehicles[i];
              final sColor = getStatusColor(v['status']!);
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.local_shipping, color: Colors.grey)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(v['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sColor))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(v['plate']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(v['model']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Capacity', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(v['cap']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Condition', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(v['cond']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: v['cond'] == 'Needs Maintenance' ? Colors.red : Colors.green))]),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}