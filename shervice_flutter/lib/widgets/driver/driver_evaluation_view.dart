import 'dart:convert';
import 'dart:math';
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

  // --- Pagination & Sorting State ---
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _currentSort = 'Date (Newest)';
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Highest Rating',
    'Lowest Rating'
  ];

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
          _applySort(); // Apply default sorting upon fetch
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

  // --- Sorting Logic ---
  void _applySort() {
    _evaluations.sort((a, b) {
      if (_currentSort.contains('Date')) {
        DateTime dateA = DateTime.tryParse(a['submit_date']?.toString() ?? '') ?? DateTime(2000);
        DateTime dateB = DateTime.tryParse(b['submit_date']?.toString() ?? '') ?? DateTime(2000);
        return _currentSort == 'Date (Newest)'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      } else {
        double scoreA = ((a['safety_score'] ?? 0) +
                (a['punctuality_score'] ?? 0) +
                (a['professionalism_score'] ?? 0)) /
            3;
        double scoreB = ((b['safety_score'] ?? 0) +
                (b['punctuality_score'] ?? 0) +
                (b['professionalism_score'] ?? 0)) /
            3;
        return _currentSort == 'Highest Rating'
            ? scoreB.compareTo(scoreA)
            : scoreA.compareTo(scoreB);
      }
    });
  }

  void _onSortChanged(String? newValue) {
    if (newValue != null && newValue != _currentSort) {
      setState(() {
        _currentSort = newValue;
        _currentPage = 0; // Reset to page 1 on resort
        _applySort();
      });
    }
  }

  // --- Pagination Logic ---
  int get _totalPages => (_evaluations.length / _itemsPerPage).ceil();

  List<dynamic> get _paginatedEvaluations {
    if (_evaluations.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _evaluations.length);
    return _evaluations.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
      );
    }

    if (_evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No evaluations yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Passengers have not rated this driver.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
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
            color: isDark ? Colors.blue.withOpacity(0.05) : theme.colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.blue.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.3)),
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
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
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
                      color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
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
                    _buildMetricBar('Safety', _getAverage('safety_score'), isDark),
                    const SizedBox(height: 8),
                    _buildMetricBar(
                      'Punctuality',
                      _getAverage('punctuality_score'),
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricBar(
                      'Professionalism',
                      _getAverage('professionalism_score'),
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- SORTING & HEADER ROW ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASSENGER FEEDBACK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentSort,
                  dropdownColor: theme.cardColor,
                  icon: Icon(Icons.sort, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: _sortOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: _onSortChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // --- BOTTOM SECTION: Individual Reviews (Paginated) ---
        Expanded(
          child: ListView.separated(
            itemCount: _paginatedEvaluations.length,
            separatorBuilder: (context, index) => Divider(height: 24, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            itemBuilder: (context, index) {
              final eval = _paginatedEvaluations[index];
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
                              color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: isDark ? Colors.green.shade400 : Colors.green,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avgScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.green.shade400 : Colors.green,
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
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // INDIVIDUAL SCORE BREAKDOWN
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildMiniScore('Safety', safety, isDark),
                      _buildMiniScore('Punctuality', punctuality, isDark),
                      _buildMiniScore('Professionalism', pro, isDark),
                    ],
                  ),

                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '"$comments"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF334155),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // --- PAGINATION CONTROLS ---
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _evaluations.length)} of ${_evaluations.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? _prevPage : null,
                      splashRadius: 20,
                      color: _currentPage > 0 ? theme.colorScheme.primary : theme.disabledColor,
                    ),
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                      splashRadius: 20,
                      color: _currentPage < _totalPages - 1 ? theme.colorScheme.primary : theme.disabledColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- HELPER FOR THE BREAKDOWN ROW ---
  Widget _buildMiniScore(String label, int score, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
          ),
        ),
        const Icon(Icons.star, size: 10, color: Colors.amber),
      ],
    );
  }

  Widget _buildMetricBar(String label, double average, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: average / 5,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
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
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
            ),
          ),
        ),
      ],
    );
  }
}