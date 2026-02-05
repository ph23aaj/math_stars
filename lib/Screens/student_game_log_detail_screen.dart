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

          final questions = (d['questions'] as List?)?.cast<Map>() ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(gameName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Level: $level • Status: $status'),
              const SizedBox(height: 6),
              Text('Correct: $correct • Incorrect: $incorrect'),

              const SizedBox(height: 16),
              const Text('Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              ...questions.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final q = Map<String, dynamic>.from(entry.value);

                final a = q['a'];
                final b = q['b'];
                final ca = q['correctAnswer'];
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

                return Card(
                  child: ListTile(
                    title: Text('Q$i: $a + $b = $ca'),
                    subtitle: Text('Your answer: $answerText • $resultText • ${timeSec}s'),
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
