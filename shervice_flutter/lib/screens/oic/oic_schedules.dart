import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OicSchedules extends StatefulWidget {
  final String oicId; // ✅ Require the UUID from the layout

  const OicSchedules({super.key, required this.oicId});

  @override
  State<OicSchedules> createState() => _OicSchedulesState();
}

class _OicSchedulesState extends State<OicSchedules> {
  bool _isLoading = true;
  List<dynamic> _myTrips = [];
  String _searchTerm = ''; // 👈 Added state variable for search

  // Calendar State
  late DateTime _focusedMonth;
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/schedules/oic/${widget.oicId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _myTrips = data['data'];
            _isLoading = false;
          });
          return;
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewScheduleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          CreateTripRequestDialog(oicId: widget.oicId),
    ).then((_) {
      if (mounted) {
        setState(() => _isLoading = true);
        _fetchMyTrips();
      }
    });
  }

  // ─── CUSTOM CALENDAR LOGIC ───

  // Group trips by exact date
  Map<DateTime, List<dynamic>> get _tripsByDate {
    Map<DateTime, List<dynamic>> map = {};
    final search = _searchTerm.toLowerCase(); // 👈 Grab lowercase search term

    for (var trip in _myTrips) {
      final dateString = trip['schedule_date'] ?? trip['departure_date'];
      
      if (dateString != null) {
        final route = (trip['route_name'] ?? '').toString().toLowerCase();
        final driver = (trip['driver_name'] ?? '').toString().toLowerCase();
        final dateStr = dateString.toString().toLowerCase();

        // 👈 Filter logic applied before parsing and adding to the calendar!
        if (search.isEmpty || route.contains(search) || driver.contains(search) || dateStr.contains(search)) {
          try {
            DateTime parsedDate = DateTime.parse(dateString.toString());
            // Normalize to midnight to use as a reliable map key
            DateTime normalizedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            
            if (map[normalizedDate] == null) {
              map[normalizedDate] = [];
            }
            map[normalizedDate]!.add(trip);
          } catch (e) {
            debugPrint("Date Parsing Error: $e");
          }
        }
      }
    }
    return map;
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _showDayTripsDialog(DateTime date, List<dynamic> trips) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "${_monthNames[date.month - 1]} ${date.day}, ${date.year}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: SizedBox(
            width: 400, // Bound width for desktop/mobile consistency
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final isPending = trip['trip_status'].toString().contains('Pending');
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trip['route_name'] ?? 'Unknown Route',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trip['trip_status'],
                              style: TextStyle(
                                color: isPending ? Colors.orange.shade700 : Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(trip['departure_time'].toString().substring(0, 5), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(width: 16),
                          Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text("${trip['passenger_count']} Pax", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fleet Schedule Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visualize and track your trip requests by date.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewScheduleModal(context),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'New Request',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Tightened spacing

            // 👈 NEW: Search Bar directly above the calendar
            TextField(
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: InputDecoration(
                hintText: 'Search by route',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              // ─── CALENDAR UI ───
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    // Calendar Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _prevMonth,
                          tooltip: "Previous Month",
                        ),
                        Text(
                          "${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth,
                          tooltip: "Next Month",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Weekday Headers (Sun, Mon, Tue...)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekdays.map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    
                    // Calendar Grid Builder
                    Builder(
                      builder: (context) {
                        final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
                        // 1 = Mon, 7 = Sun. We want Sun = 0.
                        final firstDayWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
                        final totalCells = daysInMonth + firstDayWeekday;
                        
                        final tripsMap = _tripsByDate;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            // FIX: Increased aspect ratio to 1.6 on desktop to reduce calendar height
                            childAspectRatio: isMobile ? 0.8 : 1.6, 
                          ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            // Empty cells before the 1st of the month
                            if (index < firstDayWeekday) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }

                            final dayNumber = index - firstDayWeekday + 1;
                            final currentCellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                            final today = DateTime.now();
                            final isToday = today.year == currentCellDate.year && today.month == currentCellDate.month && today.day == currentCellDate.day;
                            
                            final dailyTrips = tripsMap[currentCellDate] ?? [];

                            return InkWell(
                              onTap: dailyTrips.isNotEmpty ? () => _showDayTripsDialog(currentCellDate, dailyTrips) : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isToday ? Colors.blue.shade50 : Colors.white,
                                  border: Border.all(color: isToday ? Colors.blue.shade300 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      dayNumber.toString(),
                                      style: TextStyle(
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                        color: isToday ? Colors.blue.shade700 : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Plotting the trips inside the box!
                                    if (dailyTrips.isNotEmpty)
                                      Expanded(
                                        child: ListView(
                                          physics: const NeverScrollableScrollPhysics(),
                                          children: dailyTrips.take(isMobile ? 1 : 2).map<Widget>((trip) { // Show up to 2 items on desktop to save height
                                            final isPending = trip['trip_status'].toString().contains('Pending');
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 2),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isMobile 
                                                  ? trip['departure_time'].toString().substring(0, 5) // Mobile only shows time to save space
                                                  : "${trip['departure_time'].toString().substring(0, 5)} - ${trip['route_name']}", // Desktop shows time and route
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList()
                                          // Add a "+X more" indicator if there are too many trips to fit
                                          ..addAll([
                                            if (dailyTrips.length > (isMobile ? 1 : 2))
                                              Text(
                                                "+${dailyTrips.length - (isMobile ? 1 : 2)} more",
                                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              )
                                          ]),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── NEW TRIP REQUEST FORM DIALOG ───
class CreateTripRequestDialog extends StatefulWidget {
  final String oicId;

  const CreateTripRequestDialog({super.key, required this.oicId});

  @override
  State<CreateTripRequestDialog> createState() => _CreateTripRequestDialogState();
}

class _CreateTripRequestDialogState extends State<CreateTripRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _loadingStaff = true;

  List<dynamic> _staffMembers = [];
  String? _selectedStaffId;

  final _destinationController = TextEditingController();
  final _passengerController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String get _backendUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000/api';
    return Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/schedules/staff-options'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && mounted) {
        setState(() {
          _staffMembers = data['data'];
          _loadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStaff = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/schedules/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "oic_id": widget.oicId,
          "staff_id": _selectedStaffId,
          "destination": _destinationController.text.trim(),
          "passenger_count": _passengerController.text.trim(),
          "departure_date": formattedDate,
          "departure_time": formattedTime,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip requested successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message'] ?? "Failed to submit request.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Request New Schedule",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingStaff)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Assign to Dispatch Staff",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.support_agent),
                  ),
                  value: _selectedStaffId,
                  items: _staffMembers
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s['user_id'],
                          child: Text(s['full_name'] ?? 'Staff'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStaffId = val),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _destinationController,
                validator: (val) => val!.isEmpty ? "Required" : null,
                decoration: const InputDecoration(
                  labelText: "Route / Destination",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passengerController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (int.tryParse(val) == null) {
                    return "Must be a valid number";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: "Number of Passengers",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? "Select Date"
                              : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? "Select Time"
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text(
                  "Submit Request",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}