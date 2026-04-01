import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AccuracyLineChartCard extends StatefulWidget {
  const AccuracyLineChartCard({super.key, required this.uid});
  final String uid;

  @override
  State<AccuracyLineChartCard> createState() => _AccuracyLineChartCardState();
}

class _AccuracyLineChartCardState extends State<AccuracyLineChartCard> {
  String? _selectedGameId; // null => All games

  final Map<String?, String> _options = const {
    null: 'All games',
    'addition': 'Addition',
    'subtraction': 'Subtraction',
    'multiplication': 'Multiplication',
    'division': 'Division',
  };

  Query<Map<String, dynamic>> _query() {
    var q = FirebaseFirestore.instance
        .collection('students')
        .doc(widget.uid)
        .collection('gameLogs')
        .where('status', isEqualTo: 'completed')
        .orderBy('startedAt', descending: true);

    if (_selectedGameId != null) {
      q = q.where('gameId', isEqualTo: _selectedGameId);
      // For a single game: last 15 of that game
      return q.limit(15);
    }

    // For "All games": last 30 overall so the line has more points
    return q.limit(30);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10), // glass
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Accuracy trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Game:',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedGameId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0B1026),
                    underline: const SizedBox.shrink(),
                    iconEnabledColor: Colors.white.withValues(alpha: 0.9),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
                    items: _options.entries
                        .map((e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGameId = v),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 220,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Chart error:\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData) {
                  return const Center(child: Text('No data'));
                }


                // Query is descending; reverse so the line goes left->right in time
                final docs = snap.data!.docs.toList().reversed.toList();

                final points = <_AccPoint>[];
                for (final doc in docs) {
                  final d = doc.data();
                  final startedAt = d['startedAt'];
                  final correct = (d['correct'] ?? 0) as int;
                  final incorrect = (d['incorrect'] ?? 0) as int;

                  if (startedAt is! Timestamp) continue;

                  final total = correct + incorrect;
                  if (total == 0) continue;

                  final acc = (correct / total) * 100.0;
                  points.add(_AccPoint(time: startedAt.toDate(), accuracy: acc));
                }

                if (points.length < 2) {
                  return const Center(child: Text('Play a few games to see a trend.'));
                }

                final spots = <FlSpot>[];
                for (int i = 0; i < points.length; i++) {
                  spots.add(FlSpot(i.toDouble(), points[i].accuracy));
                }

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 25,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.round()}%',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (points.length / 4).clamp(1, 999).toDouble(),
                          getTitlesWidget: (v, meta) {
                            final idx = v.round();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                            final dt = points[idx].time;
                            final dd = dt.day.toString().padLeft(2, '0');
                            final mm = dt.month.toString().padLeft(2, '0');
                            return Text(
                              '$dd/$mm',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w700,
                              ),
                            );
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
          Text(
            'Tip: Try to keep the line trending upwards over time.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _AccPoint {
  _AccPoint({required this.time, required this.accuracy});
  final DateTime time;
  final double accuracy;
}
