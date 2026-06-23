import 'package:flutter/material.dart';

class AdminSchedules extends StatelessWidget {
  const AdminSchedules({super.key});

  void _showNewDispatchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Schedule New Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Client / Company Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Time & Shift', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Driver', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    items: ['Ricardo Ramos', 'Juan Dela Cruz', 'Miguel Santos'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Vehicle', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
                    items: ['GT-VAN-012', 'GT-VAN-008', 'GT-VAN-022'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
              'Active Schedules',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            ElevatedButton.icon(
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
        
        _buildRouteCard(client: 'LIMA Estate (EPSON)', time: '06:00 AM - Shift 1', driver: 'Ricardo Ramos', vehicle: 'GT-VAN-012', status: 'In Transit', statusColor: Colors.blue),
        _buildRouteCard(client: 'Malvar (Bandai Namco)', time: '06:30 AM - Shift 1', driver: 'Juan Dela Cruz', vehicle: 'GT-VAN-008', status: 'Departed', statusColor: Colors.green),
        _buildRouteCard(client: 'BIZ HUB (NX Logistics)', time: '02:00 PM - Shift 2', driver: 'Miguel Santos', vehicle: 'GT-VAN-022', status: 'Scheduled', statusColor: Colors.orange),

        const SizedBox(height: 16),
        _buildResponsivePagination('1 to 3 of 12 entries'),
      ],
    );
  }

  Widget _buildRouteCard({required String client, required String time, required String driver, required String vehicle, required String status, required Color statusColor}) {
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
            spacing: 8, runSpacing: 8,
            children: [
              Text(client, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),
          Wrap(
            spacing: 16, runSpacing: 12,
            children: [
              _iconText(Icons.access_time, time),
              _iconText(Icons.person_outline, driver),
              _iconText(Icons.directions_car_outlined, vehicle),
            ],
          )
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

   Widget _buildResponsivePagination(String text) {
    return Wrap(
      alignment: WrapAlignment.end, // Anchored purely to the right
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