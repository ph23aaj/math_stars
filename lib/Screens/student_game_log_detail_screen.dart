import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentGameLogDetailScreen extends StatelessWidget {
  const StudentGameLogDetailScreen({
    super.key,
    required this.uid,
    required this.logId,
  });

  final String uid;
  final String logId;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('gameLogs')
        .doc(logId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mission Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background gradient (space)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1026),
                  Color(0xFF1A2A6C),
                  Color(0xFF2B1055),
                ],
              ),
            ),
          ),

          // Stars overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _StarFieldPainter()),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: ref.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final d = (snap.data!.data() as Map<String, dynamic>?) ?? {};
                final gameName = (d['gameName'] ?? 'Game').toString();
                final level = (d['level'] ?? 0).toString();
                final status = (d['status'] ?? 'in_progress').toString();
                final correct = (d['correct'] ?? 0);
                final incorrect = (d['incorrect'] ?? 0);

                // Date/time shown
                DateTime? dt;
                final startedAt = d['startedAt'];
                final updatedAt = d['updatedAt'];
                if (startedAt is Timestamp) dt = startedAt.toDate();
                if (dt == null && updatedAt is Timestamp) dt = updatedAt.toDate();

                String two(int n) => n.toString().padLeft(2, '0');
                final dateText = dt == null
                    ? 'Unknown date'
                    : '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';

                // Questions list (one entry per question)
                final raw = (d['questions'] as List?)?.cast<Map>() ?? [];
                final questions = raw
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(growable: false);

                if (questions.isNotEmpty) {
                  questions.sort((a, b) {
                    final ia = (a['questionIndex'] ?? 999999) as int;
                    final ib = (b['questionIndex'] ?? 999999) as int;
                    return ia.compareTo(ib);
                  });
                }

                String prettyStatus(String s) {
                  switch (s) {
                    case 'completed':
                      return 'Completed';
                    case 'abandoned':
                      return 'Abandoned';
                    case 'in_progress':
                    default:
                      return 'In progress';
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gameName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Played: $dateText',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _MiniChip(text: 'Level $level'),
                              const SizedBox(width: 8),
                              _MiniChip(text: prettyStatus(status)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.check_circle,
                                label: 'Correct',
                                value: '$correct',
                                color: const Color(0xFF7E57C2), // purple
                              ),
                              const SizedBox(width: 10),
                              _StatChip(
                                icon: Icons.cancel,
                                label: 'Wrong',
                                value: '$incorrect',
                                color: const Color(0xFFFF8F00), // orange
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (questions.isEmpty)
                      _GlassCard(
                        child: Text(
                          'No questions recorded yet.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    ...questions.map((q) {
                      final aVal = q['a'];
                      final bVal = q['b'];
                      final ca = q['correctAnswer'];
                      final op = (q['operator'] ?? '+').toString();
                      final originalIndex = (q['questionIndex'] ?? 0) as int;

                      final ua = q['userAnswer'];
                      final isCorrect = q['isCorrect'] == true;
                      final timedOut = q['timedOut'] == true;
                      final timeMs = (q['timeTakenMs'] ?? 0) as int;
                      final timeSec = (timeMs / 1000).toStringAsFixed(1);

                      final resultText = timedOut
                          ? 'Timed out'
                          : isCorrect
                          ? 'Correct'
                          : 'Incorrect';

                      final answerText = ua == null ? '—' : ua.toString();

                      IconData icon;
                      if (timedOut) {
                        icon = Icons.timer_off;
                      } else if (isCorrect) {
                        icon = Icons.check_circle;
                      } else {
                        icon = Icons.cancel;
                      }

                      final pill = _ResultPill.from(
                        timedOut: timedOut,
                        isCorrect: isCorrect,
                        text: resultText,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Q$originalIndex: $aVal $op $bVal = $ca',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  pill,
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Your answer: $answerText  •  $resultText  •  ${timeSec}s',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.82),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ UI HELPERS ------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
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
      child: child,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.90),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.95)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({
    required this.text,
    required this.bg,
    required this.border,
  });

  final String text;
  final Color bg;
  final Color border;

  factory _ResultPill.from({
    required bool timedOut,
    required bool isCorrect,
    required String text,
  }) {
    if (timedOut) {
      return _ResultPill(
        text: text,
        bg: const Color(0xFFBDBDBD), // grey
        border: const Color(0xFFEEEEEE),
      );
    }
    if (isCorrect) {
      return _ResultPill(
        text: text,
        bg: const Color(0xFF7E57C2), // purple
        border: const Color(0xFFB39DDB),
      );
    }
    return _ResultPill(
      text: text,
      bg: const Color(0xFFFF8F00), // orange
      border: const Color(0xFFFFCC80),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ------------------ STARS ------------------

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(11);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 190; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;

      final r = rnd.nextDouble() * 1.4 + 0.4;
      final alpha = (rnd.nextDouble() * 0.55 + 0.12);

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    for (int i = 0; i < 16; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 2.0 + 1.2;

      paint.color = Colors.white.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}