import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverRatingBadge extends StatefulWidget {
  final String driverUuid;
  final String backendUrl;

  const DriverRatingBadge({
    super.key,
    required this.driverUuid,
    required this.backendUrl,
  });

  @override
  State<DriverRatingBadge> createState() => _DriverRatingBadgeState();
}

class _DriverRatingBadgeState extends State<DriverRatingBadge> {
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchDriverRating();
  }

  Future<void> _fetchDriverRating() async {
    try {
      final String targetUrl =
          '${widget.backendUrl}/evaluate/driver/${widget.driverUuid}';
      debugPrint(
        "🔍 Badge fetching from: $targetUrl",
      ); // Let's verify the exact URL

      final res = await http.get(Uri.parse(targetUrl));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final List evals = data['data'] ?? [];

        if (evals.isNotEmpty) {
          double totalScore = 0;
          for (var eval in evals) {
            // ─── SAFE PARSING: Prevents crashes if DB returns an int, string, or double ───
            final safety = (eval['safety_score'] as num?)?.toDouble() ?? 0.0;
            final punctuality =
                (eval['punctuality_score'] as num?)?.toDouble() ?? 0.0;
            final pro =
                (eval['professionalism_score'] as num?)?.toDouble() ?? 0.0;

            totalScore += (safety + punctuality + pro) / 3.0;
          }
          setState(() {
            _averageRating = totalScore / evals.length;
            _totalReviews = evals.length;
            _isLoading = false;
          });
        } else {
          debugPrint("⚠️ Badge: No evaluations found for ${widget.driverUuid}");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        debugPrint("❌ Badge Server Error: ${res.statusCode} - ${res.body}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("🚨 Badge Crash: $e"); // Stop hiding the error!
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _totalReviews == 0 ? Icons.star_border : Icons.star,
          color: Colors.amber.shade600,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _totalReviews == 0 ? 'New' : _averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            fontSize: 14,
          ),
        ),
        if (_totalReviews > 0)
          Text(
            ' ($_totalReviews)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
      ],
    );
  }
}
