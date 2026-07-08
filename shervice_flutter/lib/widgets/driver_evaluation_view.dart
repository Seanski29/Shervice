import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverEvaluationView extends StatefulWidget {
  final String driverUuid;
  final String backendUrl;

  const DriverEvaluationView({
    super.key,
    required this.driverUuid,
    required this.backendUrl,
  });

  @override
  State<DriverEvaluationView> createState() => _DriverEvaluationViewState();
}

class _DriverEvaluationViewState extends State<DriverEvaluationView> {
  bool _isLoading = true;
  List<dynamic> _evaluations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvaluations();
  }

  Future<void> _fetchEvaluations() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.backendUrl}/evaluate/driver/${widget.driverUuid}'),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _evaluations = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load evaluations.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error occurred.';
          _isLoading = false;
        });
      }
    }
  }

  // --- Aggregate Math Helpers ---
  double _getAverage(String key) {
    if (_evaluations.isEmpty) return 0.0;
    int total = 0;
    for (var eval in _evaluations) {
      total += (eval[key] as num?)?.toInt() ?? 0;
    }
    return total / _evaluations.length;
  }

  double get _overallAverage {
    if (_evaluations.isEmpty) return 0.0;
    return (_getAverage('safety_score') +
            _getAverage('punctuality_score') +
            _getAverage('professionalism_score')) /
        3;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No evaluations yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Passengers have not rated this driver.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TOP SECTION: Aggregate Averages ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big Overall Score
              Column(
                children: [
                  Text(
                    _overallAverage.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      height: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _overallAverage.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_evaluations.length} Reviews',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Breakdown Progress Bars
              Expanded(
                child: Column(
                  children: [
                    _buildMetricBar('Safety', _getAverage('safety_score')),
                    const SizedBox(height: 8),
                    _buildMetricBar(
                      'Punctuality',
                      _getAverage('punctuality_score'),
                    ),
                    const SizedBox(height: 8),
                    _buildMetricBar(
                      'Professionalism',
                      _getAverage('professionalism_score'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'PASSENGER FEEDBACK',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // --- BOTTOM SECTION: Individual Reviews ---
        Expanded(
          child: ListView.separated(
            itemCount: _evaluations.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final eval = _evaluations[index];
              final date = eval['submit_date'] ?? 'Unknown Date';
              final safety = eval['safety_score'] ?? 0;
              final punctuality = eval['punctuality_score'] ?? 0;
              final pro = eval['professionalism_score'] ?? 0;
              final comments = eval['comments']?.toString().trim() ?? '';

              final double avgScore = (safety + punctuality + pro) / 3;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avgScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Trip #${eval['trip_id']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- NEW: INDIVIDUAL SCORE BREAKDOWN ---
                  Row(
                    children: [
                      _buildMiniScore('Safety', safety),
                      const SizedBox(width: 12),
                      _buildMiniScore('Punctuality', punctuality),
                      const SizedBox(width: 12),
                      _buildMiniScore('Professionalism', pro),
                    ],
                  ),

                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '"$comments"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- NEW: HELPER FOR THE BREAKDOWN ROW ---
  Widget _buildMiniScore(String label, int score) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const Icon(Icons.star, size: 10, color: Colors.amber),
      ],
    );
  }

  Widget _buildMetricBar(String label, double average) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: average / 5,
              backgroundColor: Colors.white,
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 24,
          child: Text(
            average.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ),
      ],
    );
  }
}
