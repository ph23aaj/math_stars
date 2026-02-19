import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressChartsCard extends StatelessWidget {
  const ProgressChartsCard({super.key, required this.uid});
  final String uid;

  String _prettyGame(String gameId) {
    switch (gameId) {
      case 'timed_addition':
        return 'Addition';
      case 'timed_subtraction':
        return 'Subtraction';
      case 'timed_multiplication':
        return 'Multiplication';
      case 'timed_division':
        return 'Division';
      default:
        return gameId;
    }
  }

  String _keyLabel(String gameId, int level) => '${_prettyGame(gameId)} L$level';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('gameLogs')
        .where('status', isEqualTo: 'completed')
        .orderBy('startedAt', descending: true)
        .limit(15);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Chart error:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No completed games yet.'));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Text('Play some games to see progress charts.');
          }

          // We queried newest->oldest. For a trend line, reverse to oldest->newest.
          final logs = docs.map((d) => d.data()).toList().reversed.toList();

          // -------- Line chart data: accuracy % per game --------
          final spots = <FlSpot>[];
          final dateLabels = <String>[];

          for (int i = 0; i < logs.length; i++) {
            final m = logs[i];
            final correct = (m['correct'] ?? 0) as int;
            final total = (m['totalQuestions'] ?? (correct + ((m['incorrect'] ?? 0) as int))) as int;

            final pct = total <= 0 ? 0.0 : (correct / total) * 100.0;
            spots.add(FlSpot(i.toDouble(), pct));

            final t = m['startedAt'];
            if (t is Timestamp) {
              final dt = t.toDate();
              dateLabels.add('${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}');
            } else {
              dateLabels.add(' ');
            }
          }

          // -------- Pie data: totals by (gameId + level) --------
          final correctByKey = <String, int>{};
          final incorrectByKey = <String, int>{};

          for (final m in logs) {
            final gameId = (m['gameId'] ?? 'unknown').toString();
            final level = (m['level'] ?? 0) as int;
            final key = _keyLabel(gameId, level);

            final c = (m['correct'] ?? 0) as int;
            final w = (m['incorrect'] ?? 0) as int;

            correctByKey[key] = (correctByKey[key] ?? 0) + c;
            incorrectByKey[key] = (incorrectByKey[key] ?? 0) + w;
          }

          Widget pieFromMap(String title, Map<String, int> data) {
            final entries = data.entries.where((e) => e.value > 0).toList();
            entries.sort((a, b) => b.value.compareTo(a.value));

            if (entries.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text('No data yet.'),
                ],
              );
            }

            // Avoid unreadable pies: keep top 6 slices, group the rest as "Other"
            const maxSlices = 6;
            final top = entries.take(maxSlices).toList();
            final rest = entries.skip(maxSlices).toList();
            final otherTotal = rest.fold<int>(0, (sum, e) => sum + e.value);

            final finalEntries = <MapEntry<String, int>>[
              ...top,
              if (otherTotal > 0) const MapEntry('Other', 0),
            ];

            if (otherTotal > 0) {
              finalEntries[finalEntries.length - 1] = MapEntry('Other', otherTotal);
            }

            final sections = <PieChartSectionData>[];
            for (int i = 0; i < finalEntries.length; i++) {
              final e = finalEntries[i];
              sections.add(
                PieChartSectionData(
                  value: e.value.toDouble(),
                  title: e.value.toString(),
                  radius: 46,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            sectionsSpace: 2,
                            centerSpaceRadius: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: finalEntries.length,
                          itemBuilder: (_, idx) {
                            final e = finalEntries[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${e.key}: ${e.value}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // -------- Build UI --------
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Progress (last 15 completed games)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Line chart: accuracy %
              const Text('Accuracy trend (%)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: LineChart(
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
                          reservedSize: 44,
                          getTitlesWidget: (v, meta) => Text('${v.toStringAsFixed(0)}%'),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (spots.length / 4).clamp(1, 999).toDouble(),
                          getTitlesWidget: (v, meta) {
                            final idx = v.round();
                            if (idx < 0 || idx >= dateLabels.length) return const SizedBox.shrink();
                            return Text(dateLabels[idx], style: const TextStyle(fontSize: 10));
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
                ),
              ),

              const SizedBox(height: 18),
              pieFromMap('Correct answers by game + level', correctByKey),

              const SizedBox(height: 18),
              pieFromMap('Incorrect answers by game + level', incorrectByKey),

              const SizedBox(height: 8),
              const Text(
                'Tip: Look for a rising accuracy line, and “wrong” slices shrinking over time.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }
}
