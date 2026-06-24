import 'package:flutter/material.dart';

class OicTrips extends StatefulWidget {
  const OicTrips({super.key});

  @override
  State<OicTrips> createState() => _OicTripsState();
}

class _OicTripsState extends State<OicTrips> {
  String _searchTerm = '';

  final List<Map<String, dynamic>> _trips = [
    {'id': 'TRP-801', 'driver': 'A. Santos', 'vehicle': 'Van 1 (ABC-123)', 'route': 'LIMA - SM Lipa', 'time': '10:00 AM', 'status': 'In Transit', 'passengers': 12, 'capacity': 15},
    {'id': 'TRP-802', 'driver': 'B. Garcia', 'vehicle': 'Bus 3 (XYZ-987)', 'route': 'LIMA - Malvar', 'time': '09:30 AM', 'status': 'Completed', 'passengers': 28, 'capacity': 30},
    {'id': 'TRP-803', 'driver': 'C. Mendoza', 'vehicle': 'Van 2 (DEF-456)', 'route': 'LIMA - Tanauan', 'time': '01:00 PM', 'status': 'Scheduled', 'passengers': 0, 'capacity': 15},
    {'id': 'TRP-804', 'driver': 'D. Reyes', 'vehicle': 'Bus 1 (LMN-111)', 'route': 'LIMA - Sto. Tomas', 'time': '03:30 PM', 'status': 'Scheduled', 'passengers': 0, 'capacity': 30},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _trips.where((trip) => trip['id'].toString().toLowerCase().contains(_searchTerm.toLowerCase())).toList();

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
                  const Text('Trip Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Comprehensive log of all fleet deployments and passenger counts.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchTerm = val),
                      decoration: InputDecoration(
                        hintText: 'Search trips...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, color: Colors.black87),
                    label: const Text('Filters', style: TextStyle(color: Colors.black87)),
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // List Container
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text('Deployment Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTrips.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final trip = filteredTrips[index];
                    Color statusColor = trip['status'] == 'Completed' ? Colors.green : trip['status'] == 'In Transit' ? Colors.blue : Colors.orange;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(trip['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.local_shipping, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(trip['vehicle'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
                            ]),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blue), const SizedBox(width: 4), Text(trip['route'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(trip['time'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
                            ]),
                          ),
                          Expanded(flex: 1, child: Text(trip['driver'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${trip['passengers']} / ${trip['capacity']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), border: Border.all(color: statusColor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(20)),
                                child: Text(trip['status'].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}