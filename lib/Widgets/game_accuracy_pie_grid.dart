import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GameAccuracyPieGrid extends StatefulWidget {
  const GameAccuracyPieGrid({super.key, required this.uid});
  final String uid;

  @override
  State<GameAccuracyPieGrid> createState() => _GameAccuracyPieGridState();
}

enum _Range { week, month, sixMonths }

class _GameAccuracyPieGridState extends State<GameAccuracyPieGrid> {
  static const _games = <_GameMeta>[
    _GameMeta('addition', 'Addition'),
    _GameMeta('subtraction', 'Subtraction'),
    _GameMeta('multiplication', 'Multiplication'),
    _GameMeta('division', 'Division'),
  ];

  _Range _range = _Range.week;

  DateTime _cutoffDate() {
    final now = DateTime.now();
    switch (_range) {
      case _Range.week:
        return now.subtract(const Duration(days: 7));
      case _Range.month:
        return now.subtract(const Duration(days: 30)); // simple + reliable
      case _Range.sixMonths:
        return now.subtract(const Duration(days: 182)); // ~6 months
    }
  }

  String _rangeLabel() {
    switch (_range) {
      case _Range.week:
        return '1 week';
      case _Range.month:
        return '1 month';
      case _Range.sixMonths:
        return '6 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = _cutoffDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accuracy by game (${_rangeLabel()})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // Range buttons
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('1 week'),
              selected: _range == _Range.week,
              onSelected: (_) => setState(() => _range = _Range.week),
            ),
            ChoiceChip(
              label: const Text('1 month'),
              selected: _range == _Range.month,
              onSelected: (_) => setState(() => _range = _Range.month),
            ),
            ChoiceChip(
              label: const Text('6 months'),
              selected: _range == _Range.sixMonths,
              onSelected: (_) => setState(() => _range = _Range.sixMonths),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 4 in a row; scroll if needed
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _games.map((g) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 230,
                  child: _AccuracyPieCard(
                           uid: widget.uid,
                           gameId: g.id,
                           title: g.title,
                           cutoff: cutoff,
                           limit: _range == _Range.week
                               ? 200
                               : _range == _Range.month
                                   ? 500
                                   : 1000,
                         ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),
        Text(
          'Tap a chart to expand into level breakdown.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

class _AccuracyPieCard extends StatefulWidget {
  const _AccuracyPieCard({
    required this.uid,
    required this.gameId,
    required this.title,
    required this.cutoff,
    required this.limit,
  });

  final String uid;
  final String gameId;
  final String title;
  final DateTime cutoff;
  final int limit;

  @override
  State<_AccuracyPieCard> createState() => _AccuracyPieCardState();
}

class _AccuracyPieCardState extends State<_AccuracyPieCard> {
  bool _expanded = false;

  // Correct (purple) shades by level (L1 darkest -> L3 brightest)
  static const Color _c1 = Color(0xFF5E35B1); // deep purple
  static const Color _c2 = Color(0xFF7E57C2); // medium purple
  static const Color _c3 = Color(0xFFB39DDB); // light/bright purple

  // Incorrect (orange) shades by level (L1 darkest -> L3 brightest)
  static const Color _w1 = Color(0xFFEF6C00); // deep orange
  static const Color _w2 = Color(0xFFFF8F00); // medium orange
  static const Color _w3 = Color(0xFFFFCC80); // light/bright orange

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(widget.uid)
        .collection('gameLogs')
        .where('status', isEqualTo: 'completed')
        .where('gameId', isEqualTo: widget.gameId)
        .where(
          'startedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(widget.cutoff),
        )
        .orderBy('startedAt', descending: true)
        .limit(widget.limit);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return SizedBox(
              height: 190,
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
              height: 190,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return _emptyCard();
          }

          // Totals per level
          int c1 = 0, c2 = 0, c3 = 0;
          int w1 = 0, w2 = 0, w3 = 0;

          for (final doc in docs) {
            final d = doc.data();

            final levelRaw = d['level'];
            final correctRaw = d['correct'];
            final incorrectRaw = d['incorrect'];

            final level = (levelRaw is int) ? levelRaw : int.tryParse('$levelRaw') ?? 0;
            final correct = (correctRaw is int) ? correctRaw : int.tryParse('$correctRaw') ?? 0;
            final incorrect = (incorrectRaw is int) ? incorrectRaw : int.tryParse('$incorrectRaw') ?? 0;

            if (level == 1) {
              c1 += correct; w1 += incorrect;
            } else if (level == 2) {
              c2 += correct; w2 += incorrect;
            } else if (level == 3) {
              c3 += correct; w3 += incorrect;
            }
          }

          final totalCorrect = c1 + c2 + c3;
          final totalWrong = w1 + w2 + w3;
          final total = totalCorrect + totalWrong;

          if (total == 0) {
            return _emptyCard();
          }

          // Collapsed view: 2 slices (Correct vs Incorrect)
          final collapsedSections = <PieChartSectionData>[
            _secPct(value: totalCorrect, total: total, color: _c2, title: 'Correct'),
            _secPct(value: totalWrong, total: total, color: _w2, title: 'Wrong'),
          ];

          // Expanded view: 6 slices (Correct L1-3, Wrong L1-3)
          final expandedSections = <PieChartSectionData>[
            _secPct(value: c1, total: total, color: _c1, title: 'C L1'),
            _secPct(value: c2, total: total, color: _c2, title: 'C L2'),
            _secPct(value: c3, total: total, color: _c3, title: 'C L3'),
            _secPct(value: w1, total: total, color: _w1, title: 'W L1'),
            _secPct(value: w2, total: total, color: _w2, title: 'W L2'),
            _secPct(value: w3, total: total, color: _w3, title: 'W L3'),
          ];

          final sections = _expanded ? expandedSections : collapsedSections;

          final correctPct = (totalCorrect / total) * 100.0;
          final wrongPct = (totalWrong / total) * 100.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _expanded
                    ? 'Expanded by level'
                    : 'Correct ${correctPct.toStringAsFixed(0)}% • Wrong ${wrongPct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.78)),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 180,
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 34,
                      sectionsSpace: 2,
                      sections: sections,
                      // no PieTouchData needed
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Legend changes based on expanded/collapsed
              if (!_expanded)
                const Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _LegendDot(color: _c2, label: 'Correct'),
                    _LegendDot(color: _w2, label: 'Wrong'),
                  ],
                )
              else
                const Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _LegendDot(color: _c1, label: 'Correct L1'),
                    _LegendDot(color: _c2, label: 'Correct L2'),
                    _LegendDot(color: _c3, label: 'Correct L3'),
                    _LegendDot(color: _w1, label: 'Wrong L1'),
                    _LegendDot(color: _w2, label: 'Wrong L2'),
                    _LegendDot(color: _w3, label: 'Wrong L3'),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No data yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.80)),
            ),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _secPct({
    required int value,
    required int total,
    required Color color,
    required String title,
  }) {
    if (value == 0) {
      return PieChartSectionData(
        value: 0,
        color: color.withValues(alpha: 0.15),
        radius: 46,
        title: '',
      );
    }

    final pct = (value / total) * 100.0;

    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 46,
      title: '${pct.toStringAsFixed(0)}%',
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.80))),
      ],
    );
  }
}

class _GameMeta {
  const _GameMeta(this.id, this.title);
  final String id;
  final String title;
}