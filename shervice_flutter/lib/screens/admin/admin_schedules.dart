import 'package:flutter/material.dart';

class AdminSchedules extends StatelessWidget {
  const AdminSchedules({super.key});

  // 1. The Function to trigger the Modal
  void _showNewDispatchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Schedule New Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500, // Keeps the modal wide on desktop
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input: Client Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Client / Company Name',
                      hintText: 'e.g., LIMA Estate (EPSON)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input: Time & Shift
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Time & Shift',
                      hintText: 'e.g., 06:00 AM - Shift 1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input: Assign Driver (Dropdown)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign Driver',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: ['Ricardo Ramos', 'Juan Dela Cruz', 'Miguel Santos', 'Unassigned']
                        .map((driver) => DropdownMenuItem(value: driver, child: Text(driver)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 16),

                  // Input: Assign Vehicle (Dropdown)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign Vehicle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    items: ['GT-VAN-012 (Toyota Hiace)', 'GT-VAN-008 (Nissan Urvan)', 'GT-VAN-022 (Toyota Hiace)']
                        .map((vehicle) => DropdownMenuItem(value: vehicle, child: Text(vehicle)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Closes the modal
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // Future logic: Save data and update the list
                Navigator.pop(context); // Closes the modal after submitting
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Dispatch', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            const Text(
              'Active Routes & Schedules',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
              // 2. Wired the button to open the modal
              onPressed: () => _showNewDispatchModal(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Active Routes List
        _buildRouteCard(
          client: 'LIMA Estate (EPSON)',
          time: '06:00 AM - Shift 1',
          driver: 'Ricardo Ramos',
          vehicle: 'GT-VAN-012 (Toyota Hiace)',
          status: 'In Transit',
          statusColor: Colors.blue,
        ),
        _buildRouteCard(
          client: 'Malvar (Bandai Namco)',
          time: '06:30 AM - Shift 1',
          driver: 'Juan Dela Cruz',
          vehicle: 'GT-VAN-008 (Nissan Urvan)',
          status: 'Departed',
          statusColor: Colors.green,
        ),
        _buildRouteCard(
          client: 'FPIP (NX Logistics)',
          time: '02:00 PM - Shift 2',
          driver: 'Miguel Santos',
          vehicle: 'GT-VAN-022 (Toyota Hiace)',
          status: 'Scheduled',
          statusColor: Colors.orange,
        ),

        const SizedBox(height: 16),
        
        // 3. Pagination UI Component
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Showing 1 to 3 of 12 entries', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Previous', style: TextStyle(color: Colors.black87)),
                ),
                const SizedBox(width: 8),
                // Active Page Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Next', style: TextStyle(color: Colors.black87)),
                ),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildRouteCard({
    required String client,
    required String time,
    required String driver,
    required String vehicle,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(client, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(driver, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(vehicle, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}