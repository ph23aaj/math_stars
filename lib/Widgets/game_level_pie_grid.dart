import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GameLevelPieGrid extends StatelessWidget {
  const GameLevelPieGrid({super.key, required this.uid});

  final String uid;

  static const _games = <_GameMeta>[
    _GameMeta('timed_addition', 'Addition'),
    _GameMeta('timed_subtraction', 'Subtraction'),
    _GameMeta('timed_multiplication', 'Multiplication'),
    _GameMeta('timed_division', 'Division'),
  ];

  // Consistent colours across all pies
  static const Color _l1 = Color(0xFF2E7D32); // green
  static const Color _l2 = Color(0xFFF9A825); // amber
  static const Color _l3 = Color(0xFFC62828); // red

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Correct answers (last 15 games per topic)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        _PieRow(
          uid: uid,
          games: _games,
          mode: _PieMode.correct,
          l1: _l1,
          l2: _l2,
          l3: _l3,
        ),

        const SizedBox(height: 18),

        const Text(
          'Incorrect answers (last 15 games per topic)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        _PieRow(
          uid: uid,
          games: _games,
          mode: _PieMode.incorrect,
          l1: _l1,
          l2: _l2,
          l3: _l3,
        ),

        const SizedBox(height: 10),

        Row(
          children: const [
            _LegendDot(color: _l1, label: 'Level 1'),
            SizedBox(width: 12),
            _LegendDot(color: _l2, label: 'Level 2'),
            SizedBox(width: 12),
            _LegendDot(color: _l3, label: 'Level 3'),
          ],
        ),
      ],
    );
  }
}

class _PieRow extends StatelessWidget {
  const _PieRow({
    required this.uid,
    required this.games,
    required this.mode,
    required this.l1,
    required this.l2,
    required this.l3,
  });

  final String uid;
  final List<_GameMeta> games;
  final _PieMode mode;
  final Color l1;
  final Color l2;
  final Color l3;

  @override
  Widget build(BuildContext context) {
    // 4 in a row; horizontally scroll if narrow screens
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: games.map((g) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 220,
              child: _GamePieCard(
                uid: uid,
                gameId: g.id,
                title: g.title,
                mode: mode,
                l1: l1,
                l2: l2,
                l3: l3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GamePieCard extends StatelessWidget {
  const _GamePieCard({
    required this.uid,
    required this.gameId,
    required this.title,
    required this.mode,
    required this.l1,
    required this.l2,
    required this.l3,
  });

  final String uid;
  final String gameId;
  final String title;
  final _PieMode mode;
  final Color l1;
  final Color l2;
  final Color l3;

  Query<Map<String, dynamic>> _query() {
    // last 15 completed games for THIS game
    return FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('gameLogs')
        .where('status', isEqualTo: 'completed')
        .where('gameId', isEqualTo: gameId)
        .orderBy('startedAt', descending: true)
        .limit(15);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Chart error:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snap.hasData) {
            return const SizedBox(
              height: 160,
              child: Center(child: Text('No data')),
            );
          }


          int l1Total = 0, l2Total = 0, l3Total = 0;

          int _asInt(dynamic v, {int fallback = 0}) {
            if (v is int) return v;
            if (v is num) return v.toInt();
            if (v is String) return int.tryParse(v) ?? fallback;
            return fallback;
          }

          int _correctFromQuestions(Map<String, dynamic> d) {
            final raw = (d['questions'] as List?) ?? const [];
            int correct = 0;
            for (final e in raw) {
              final m = Map<String, dynamic>.from(e as Map);
              if (m['isCorrect'] == true) correct++;
            }
            return correct;
          }

          int _incorrectFromQuestions(Map<String, dynamic> d) {
            final raw = (d['questions'] as List?) ?? const [];
            // incorrect = total questions recorded - correct
            final correct = _correctFromQuestions(d);
            return raw.length - correct;
          }

          for (final doc in snap.data!.docs) {
            final d = doc.data();
            final level = _asInt(d['level'], fallback: 1);

            final correct = _correctFromQuestions(d);
            final incorrect = _incorrectFromQuestions(d);

            final val = (mode == _PieMode.correct) ? correct : incorrect;

            if (level == 1) l1Total += val;
            else if (level == 2) l2Total += val;
            else if (level == 3) l3Total += val;
          }


          final total = l1Total + l2Total + l3Total;

          final subtitle = mode == _PieMode.correct ? 'Correct' : 'Incorrect';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '$subtitle ',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 140,
                child: total == 0
                    ? const Center(child: Text('No data yet'))
                    : PieChart(
                  PieChartData(
                    centerSpaceRadius: 34,
                    sectionsSpace: 2,
                    sections: [
                      _sec(value: l1Total, color: l1, label: l1Total),
                      _sec(value: l2Total, color: l2, label: l2Total),
                      _sec(value: l3Total, color: l3, label: l3Total),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PieChartSectionData _sec({
    required int value,
    required Color color,
    required int label,
  }) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 46,
      title: value == 0 ? '' : label.toString(),
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

enum _PieMode { correct, incorrect }

class _GameMeta {
  const _GameMeta(this.id, this.title);
  final String id;
  final String title;
}
