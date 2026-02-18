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
      appBar: AppBar(title: const Text('Game Details')),
      body: StreamBuilder<DocumentSnapshot>(
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

          // Questions list (now one entry per question)
          final raw = (d['questions'] as List?)?.cast<Map>() ?? [];
          final questions = raw
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false);

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

          if (questions.isNotEmpty) {
            // Sort by original question index if present
            questions.sort((a, b) {
              final ia = (a['questionIndex'] ?? 999999) as int;
              final ib = (b['questionIndex'] ?? 999999) as int;
              return ia.compareTo(ib);
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                gameName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Played: $dateText'),
              const SizedBox(height: 6),
              Text('Level: $level • Status: ${prettyStatus(status)}'),
              const SizedBox(height: 6),
              Text('Correct: $correct • Incorrect: $incorrect'),

              const SizedBox(height: 18),
              const Text(
                'Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              if (questions.isEmpty)
                const Text('No questions recorded yet.'),

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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Pill(
                              text: resultText,
                              filled: isCorrect,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Answer $answerText • $resultText • ${timeSec}s',
                                style: const TextStyle(fontSize: 14),
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.filled});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
