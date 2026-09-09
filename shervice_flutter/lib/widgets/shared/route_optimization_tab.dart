import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';

class RouteOptimizationTab extends StatefulWidget {
  final String backendUrl;
  final VoidCallback onSyncAction;

  const RouteOptimizationTab({
    super.key,
    required this.backendUrl,
    required this.onSyncAction,
  });

  @override
  State<RouteOptimizationTab> createState() => _RouteOptimizationTabState();
}

class _RouteOptimizationTabState extends State<RouteOptimizationTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _mlPayload;

  @override
  void initState() {
    super.initState();
    _fetchClusterData();
  }

  Future<void> _fetchClusterData() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.backendUrl}/routes/cluster'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _mlPayload = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Cluster fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (!_isLoading &&
        (_mlPayload == null || _mlPayload!['status'] == 'Insufficient Data')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              "Insufficient Historical Timestamps",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "K-Means Clustering requires at least 3 completed trips with actual start and end times.",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final clusters = _mlPayload?['clusters'] ?? [];
    final recommendations = _mlPayload?['recommendations'] ?? [];

    return Skeletonizer(
      enabled: _isLoading,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "K-Means Route Delay Clusters",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Unsupervised ML grouping of historical schedule variance.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    tooltip: 'Recalculate Clusters',
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchClusterData();
                    },
                    icon: const Icon(
                      Icons.sync,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cluster Distribution Layout
            isMobile
                ? Column(
                    children: clusters
                        .map<Widget>((c) => _buildClusterCard(c, isDark, true))
                        .toList(),
                  )
                : Row(
                    children: clusters
                        .map<Widget>(
                          (c) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: c == clusters.last ? 0 : 16,
                              ),
                              child: _buildClusterCard(c, isDark, false),
                            ),
                          ),
                        )
                        .toList(),
                  ),
            const SizedBox(height: 32),

            Text(
              "Route Optimization Insights",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            if (recommendations.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text(
                      "All routes are operating within nominal efficiency margins.",
                    ),
                  ],
                ),
              )
            else
              ...recommendations
                  .map<Widget>(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF451A03)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['route'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r['insight'],
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Action: ${r['action']}",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(
    Map<String, dynamic> cluster,
    bool isDark,
    bool isMobile,
  ) {
    Color themeColor;
    IconData icon;
    if (cluster['label'].toString().contains('Optimal')) {
      themeColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline;
    } else if (cluster['label'].toString().contains('Departure')) {
      themeColor = const Color(0xFFF97316);
      icon = Icons.garage_outlined;
    } else {
      themeColor = const Color(0xFFEF4444);
      icon = Icons.traffic_outlined;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cluster['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            cluster['description'],
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          const SizedBox(height: 16),
          _statRow("Trip Count", "${cluster['count']} trips", isDark),
          _statRow(
            "Avg Departure Delay",
            "${cluster['avg_departure_delay_mins']} mins",
            isDark,
          ),
          _statRow(
            "Avg Arrival Delay",
            "${cluster['avg_arrival_delay_mins']} mins",
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
