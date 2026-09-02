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
  String? _errorMessage;
  int? _expandedIndex;

  // Cumulative Lifetime Averages
  double _overallRating = 0.0;
  double _punctualityAvg = 0.0;
  double _safetyAvg = 0.0;
  double _professionalismAvg = 0.0;
  int _totalRawEvaluations = 0;

  // ML Behavioral Classification State
  String _mlClassification = 'Analyzing...';
  Color _mlBadgeColor = const Color(0xFF64748B);
  IconData _mlIcon = Icons.analytics_outlined;

  // Grouped Trip Data
  List<Map<String, dynamic>> _groupedTrips = [];

  // --- Pagination & Sorting State ---
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _currentSort = 'Date (Newest)';
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Highest Rating',
    'Lowest Rating',
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

      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List<dynamic> rawEvals =
              data['data'] ?? data['evaluations'] ?? [];
          _processAndGroupEvaluations(rawEvals);
        } else if (res.statusCode == 404) {
          setState(() {
            _groupedTrips = [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Failed to load evaluations. Server returned ${res.statusCode}.';
            _isLoading = false;
          });
        }
      }

      // Concurrently fetch the KNN Behavioral Classification
      try {
        final String cacheBuster = DateTime.now().millisecondsSinceEpoch
            .toString();
        final mlRes = await http.get(
          Uri.parse(
            '${widget.backendUrl}/drivers/classify/${widget.driverUuid}?cb=$cacheBuster',
          ),
        );

        if (mlRes.statusCode == 200 && mounted) {
          final mlData = jsonDecode(mlRes.body);
          final String classification =
              mlData['classification'] ?? 'Insufficient Data';

          Color badgeColor = const Color(0xFF64748B);
          IconData badgeIcon = Icons.info_outline;

          if (classification == 'Consistent Performer') {
            badgeColor = const Color(0xFF10B981);
            badgeIcon = Icons.verified;
          } else if (classification == 'Aggressive Driving Risk' ||
              classification == 'Needs Review') {
            badgeColor = const Color(0xFFEF4444);
            badgeIcon = Icons.warning_amber_rounded;
          } else if (classification == 'Tardiness Risk' ||
              classification == 'Unprofessional Conduct') {
            badgeColor = const Color(0xFFF97316);
            badgeIcon = Icons.access_time_filled;
          }

          setState(() {
            _mlClassification = classification;
            _mlBadgeColor = badgeColor;
            _mlIcon = badgeIcon;
          });
        } else if (mounted) {
          // Prevent getting stuck on "Analyzing" if server throws 500
          setState(() {
            _mlClassification = 'Server Error';
            _mlBadgeColor = Colors.red;
            _mlIcon = Icons.error_outline;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _mlClassification = 'Network Error';
            _mlBadgeColor = Colors.grey;
            _mlIcon = Icons.cloud_off;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error occurred while fetching evaluations.';
          _isLoading = false;
        });
      }
    }
  }

  // --- Data Grouping Engine ---
  void _processAndGroupEvaluations(List<dynamic> rawEvals) {
    double cumTotalScore = 0.0, cumPunct = 0.0, cumSafe = 0.0, cumProf = 0.0;
    _totalRawEvaluations = rawEvals.length;

    for (var e in rawEvals) {
      final p = (e['punctuality_score'] as num?)?.toDouble() ?? 5.0;
      final s = (e['safety_score'] as num?)?.toDouble() ?? 5.0;
      final pr = (e['professionalism_score'] as num?)?.toDouble() ?? 5.0;

      cumPunct += p;
      cumSafe += s;
      cumProf += pr;
      cumTotalScore += (p + s + pr) / 3.0;
    }

    Map<String, List<dynamic>> tripGroups = {};
    for (var e in rawEvals) {
      String tripId = e['trip_id']?.toString() ?? 'Unassigned';
      if (!tripGroups.containsKey(tripId)) {
        tripGroups[tripId] = [];
      }
      tripGroups[tripId]!.add(e);
    }

    List<Map<String, dynamic>> compiledTrips = [];
    for (var entry in tripGroups.entries) {
      final tId = entry.key;
      final tripEvals = entry.value;

      double tPunct = 0.0, tSafe = 0.0, tProf = 0.0;
      for (var te in tripEvals) {
        tPunct += (te['punctuality_score'] as num?)?.toDouble() ?? 5.0;
        tSafe += (te['safety_score'] as num?)?.toDouble() ?? 5.0;
        tProf += (te['professionalism_score'] as num?)?.toDouble() ?? 5.0;
      }

      int tCount = tripEvals.length;
      double avgPunct = tPunct / tCount;
      double avgSafe = tSafe / tCount;
      double avgProf = tProf / tCount;
      double tripOverallAvg = (avgPunct + avgSafe + avgProf) / 3.0;
      String tripDate = tripEvals.first['submit_date'] ?? 'Unknown Date';

      compiledTrips.add({
        'trip_id': tId,
        'date': tripDate,
        'eval_count': tCount,
        'avg_punctuality': avgPunct,
        'avg_safety': avgSafe,
        'avg_professionalism': avgProf,
        'overall_avg': tripOverallAvg,
        'passenger_reviews': tripEvals,
      });
    }

    setState(() {
      _overallRating = _totalRawEvaluations == 0
          ? 0.0
          : (cumTotalScore / _totalRawEvaluations);
      _punctualityAvg = _totalRawEvaluations == 0
          ? 0.0
          : (cumPunct / _totalRawEvaluations);
      _safetyAvg = _totalRawEvaluations == 0
          ? 0.0
          : (cumSafe / _totalRawEvaluations);
      _professionalismAvg = _totalRawEvaluations == 0
          ? 0.0
          : (cumProf / _totalRawEvaluations);

      _groupedTrips = compiledTrips;
      _applySort();
      _isLoading = false;
    });
  }

  // --- Sorting Logic ---
  void _applySort() {
    _groupedTrips.sort((a, b) {
      if (_currentSort.contains('Date')) {
        DateTime dateA =
            DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(2000);
        DateTime dateB =
            DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(2000);
        return _currentSort == 'Date (Newest)'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      } else {
        double scoreA = a['overall_avg'] ?? 0.0;
        double scoreB = b['overall_avg'] ?? 0.0;
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
        _currentPage = 0;
        _expandedIndex = null;
        _applySort();
      });
    }
  }

  // --- Pagination Logic ---
  int get _totalPages => max(1, (_groupedTrips.length / _itemsPerPage).ceil());

  List<Map<String, dynamic>> get _paginatedTrips {
    if (_groupedTrips.isEmpty) return [];
    int start = _currentPage * _itemsPerPage;
    int end = min(start + _itemsPerPage, _groupedTrips.length);
    return _groupedTrips.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
        _expandedIndex = null;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _expandedIndex = null;
      });
    }
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
        child: Text(
          _errorMessage!,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    if (_groupedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
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
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TOP SECTION: Cumulative Lifetime Averages & ML Badge ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.withOpacity(0.05)
                : theme.colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.blue.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big Overall Score & Classification Tag
              Column(
                children: [
                  Text(
                    _overallRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.blue.shade300
                          : Colors.blue.shade900,
                      height: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _overallRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalRawEvaluations Total Passenger Reviews',
                    style: TextStyle(
                      color: isDark
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ML Behavioral Classification Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _mlBadgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _mlBadgeColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_mlIcon, color: _mlBadgeColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _mlClassification.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: _mlBadgeColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Breakdown Progress Bars
              Expanded(
                child: Column(
                  children: [
                    _buildMetricBar('Safety Avg', _safetyAvg, isDark),
                    const SizedBox(height: 8),
                    _buildMetricBar('Punctuality Avg', _punctualityAvg, isDark),
                    const SizedBox(height: 8),
                    _buildMetricBar(
                      'Professionalism Avg',
                      _professionalismAvg,
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
              'TRIP PERFORMANCE LOGS (${_groupedTrips.length} Trips Evaluated)',
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
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentSort,
                  dropdownColor: theme.cardColor,
                  icon: Icon(
                    Icons.sort,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: _sortOptions
                      .map(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: _onSortChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // --- BOTTOM SECTION: Expandable Trip Analytics ---
        Expanded(
          child: ListView.builder(
            itemCount: _paginatedTrips.length,
            itemBuilder: (context, index) {
              final trip = _paginatedTrips[index];
              final bool isExpanded = _expandedIndex == index;

              final String tripId = trip['trip_id'] == 'Unassigned'
                  ? 'Unassigned Trip'
                  : '#TRP-${trip['trip_id']}';
              final String date = trip['date'];
              final int evalCount = trip['eval_count'];
              final double avgScore = trip['overall_avg'];
              final List<dynamic> passengerReviews = trip['passenger_reviews'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? const Color(0xFF3B82F6)
                        : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300),
                    width: isExpanded ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Collapsed Header View
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    size: 18,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tripId,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$date • $evalCount passenger evaluation${evalCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        avgScore.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.green.shade400
                                              : Colors.green,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.star,
                                        color: isDark
                                            ? Colors.green.shade400
                                            : Colors.green,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Expanded Analytics View
                        if (isExpanded) ...[
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniTripScore(
                                'Trip Safety',
                                trip['avg_safety'],
                                isDark,
                              ),
                              _buildMiniTripScore(
                                'Trip Punctuality',
                                trip['avg_punctuality'],
                                isDark,
                              ),
                              _buildMiniTripScore(
                                'Trip Professionalism',
                                trip['avg_professionalism'],
                                isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'PASSENGER REVIEWS ($evalCount)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...passengerReviews.map((review) {
                            final String comments =
                                review['comments']?.toString().trim() ??
                                'No passenger commentary provided.';
                            final double indAvg =
                                (((review['safety_score'] as num?)
                                            ?.toDouble() ??
                                        5.0) +
                                    ((review['punctuality_score'] as num?)
                                            ?.toDouble() ??
                                        5.0) +
                                    ((review['professionalism_score'] as num?)
                                            ?.toDouble() ??
                                        5.0)) /
                                3;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${indAvg.toStringAsFixed(1)} ★',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      comments,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // --- PAGINATION CONTROLS ---
        if (_totalPages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${(_currentPage * _itemsPerPage) + 1} - ${min((_currentPage + 1) * _itemsPerPage, _groupedTrips.length)} of ${_groupedTrips.length} trips',
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
                      color: _currentPage > 0
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
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
                      onPressed: _currentPage < _totalPages - 1
                          ? _nextPage
                          : null,
                      splashRadius: 20,
                      color: _currentPage < _totalPages - 1
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- HELPER FOR THE TRIP SPECIFIC BREAKDOWN ROW ---
  Widget _buildMiniTripScore(String label, double score, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < score.round() ? Icons.star : Icons.star_border,
                  size: 14,
                  color: i < score.round()
                      ? Colors.amber.shade600
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBar(String label, double average, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 130,
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
