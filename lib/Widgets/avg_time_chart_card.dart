import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AvgTimeLineChartCard extends StatefulWidget {
  const AvgTimeLineChartCard({super.key, required this.uid});

  final String uid;

  @override
  State<AvgTimeLineChartCard> createState() => _AvgTimeLineChartCardState();
}

class _AvgTimeLineChartCardState extends State<AvgTimeLineChartCard> {
  // null => All games
  String? _selectedGameId;

  final Map<String?, String> _options = const {
    null: 'All games',
    'timed_addition': 'Addition',
    'timed_subtraction': 'Subtraction',
    'timed_multiplication': 'Multiplication',
    'timed_division': 'Division',
  };

  Query<Map<String, dynamic>> _baseQuery() {
    var q = FirebaseFirestore.instance
        .collection('students')
        .doc(widget.uid)
        .collection('gameLogs')
        .where('status', isEqualTo: 'completed')
        .orderBy('startedAt', descending: false)
        .limitToLast(25); // more points = smoother trend

    if (_selectedGameId != null) {
      q = q.where('gameId', isEqualTo: _selectedGameId);
    }

    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Average time per question',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // Dropdown
          Row(
            children: [
              const Text('Game:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String?>(
                  value: _selectedGameId,
                  isExpanded: true,
                  items: _options.entries
                      .map(
                        (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGameId = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 220,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _baseQuery().snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                // Extract points where avgTimeMs exists
                final points = <_TimePoint>[];
                for (final d in docs) {
                  final data = d.data();
                  final t = data['startedAt'];
                  final avg = data['avgTimeMs'];

                  if (t is! Timestamp) continue;
                  if (avg is! int) continue;

                  points.add(_TimePoint(time: t.toDate(), avgTimeMs: avg));
                }

                if (points.length < 2) {
                  return const Center(
                    child: Text('Play a few games to see a trend.'),
                  );
                }

                // Convert to chart spots (x=index, y=seconds)
                final spots = <FlSpot>[];
                for (int i = 0; i < points.length; i++) {
                  final ySeconds = points[i].avgTimeMs / 1000.0;
                  spots.add(FlSpot(i.toDouble(), ySeconds));
                }

                // Axis ranges
                final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
                final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

                return LineChart(
                  LineChartData(
                    minY: (minY - 0.5).clamp(0, double.infinity),
                    maxY: (maxY + 0.5),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toStringAsFixed(1)}s');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (points.length / 4).clamp(1, 999).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final idx = value.round();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();

                            // label like "28/01"
                            final dt = points[idx].time;
                            final dd = dt.day.toString().padLeft(2, '0');
                            final mm = dt.month.toString().padLeft(2, '0');
                            return Text('$dd/$mm', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Tip: Lower is faster. Aim for accuracy first, then speed.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TimePoint {
  _TimePoint({required this.time, required this.avgTimeMs});
  final DateTime time;
  final int avgTimeMs;
}
