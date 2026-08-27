import 'package:flutter/material.dart';
import '../../constant.dart';

class StaffAnalytics extends StatelessWidget {
  const StaffAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Redesigned KPIs focusing on employee fatigue and sleep status
    final List<Map<String, dynamic>> analyticsMetrics = [
      { "title": "Fatigue Predict Accuracy", "value": "94.2%", "desc": "Random Forest Classifier", "color": Colors.blue.shade600 },
      { "title": "Avg. Fleet Sleep Debt", "value": "1.2 Hrs", "desc": "Linear Regression Trend", "color": Colors.amber.shade700 },
      { "title": "High-Risk Shift Clusters", "value": "4 Active", "desc": "Unsupervised K-Means", "color": Colors.red.shade600 }
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fatigue & Intelligence Analytics', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Row(
            children: analyticsMetrics.map((metric) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.02), blurRadius: 6)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric['title'].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(metric['value'], style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: metric['color'])),
                      const SizedBox(height: 4),
                      Text(metric['desc'], style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500, fontWeight: FontWeight.w500))
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildVisualizationCard(
                  theme: theme,
                  icon: Icons.health_and_safety, iconColor: Colors.blue.shade600, iconBg: Colors.blue.shade50,
                  title: 'Driver Fatigue Risk Distribution', subtitle: 'Random Forest Classification',
                  indicator: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 48, height: 8, decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 6),
                      Container(width: 32, height: 8, decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 6),
                      Container(width: 16, height: 8, decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildVisualizationCard(
                  theme: theme,
                  icon: Icons.bedtime, iconColor: Colors.amber.shade700, iconBg: Colors.amber.shade50,
                  title: 'Sleep Deprivation Trend Analysis', subtitle: 'Linear Regression Modeling',
                  indicator: SizedBox(width: 128, height: 6, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: 0.75, backgroundColor: Colors.grey.shade100, color: Colors.amber.shade500))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildVisualizationCard(
            theme: theme,
            icon: Icons.warning_amber, iconColor: Colors.red.shade600, iconBg: Colors.red.shade50,
            title: 'Incident vs. Fatigue Clusters', subtitle: 'Unsupervised K-Means Clustering',
            indicator: Opacity(
              opacity: 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 24),
                  Transform.translate(offset: const Offset(0, 16), child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle))),
                  const SizedBox(width: 24),
                  Transform.translate(offset: const Offset(0, -8), child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationCard({required ThemeData theme, required IconData icon, required Color iconColor, required Color iconBg, required String title, required String subtitle, required Widget indicator}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32), constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.01), blurRadius: 4)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 40, color: iconColor)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(subtitle.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
          const SizedBox(height: 32),
          indicator,
        ],
      ),
    );
  }
}