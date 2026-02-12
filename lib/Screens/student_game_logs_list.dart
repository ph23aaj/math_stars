import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentGameLogsList extends StatelessWidget {
  const StudentGameLogsList({
    super.key,
    required this.uid,
    required this.onOpenLog,
  });

  final String uid;
  final void Function(String logId) onOpenLog;

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('gameLogs')
        .orderBy('startedAt', descending: true)
        .limit(15);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Text('No games logged yet.');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;

            final gameName = (d['gameName'] ?? 'Game').toString();
            final level = (d['level'] ?? 0).toString();
            final correct = (d['correct'] ?? 0).toString();
            final total = (d['totalQuestions'] ?? 0).toString();
            final status = (d['status'] ?? 'in_progress').toString();

            final statusText = status == 'completed'
                ? 'Completed'
                : status == 'abandoned'
                ? 'Abandoned'
                : 'In progress';

            // Prefer startedAt, fallback to updatedAt
            DateTime? dt;
            final startedAt = d['startedAt'];
            final updatedAt = d['updatedAt'];

            if (startedAt is Timestamp) dt = startedAt.toDate();
            if (dt == null && updatedAt is Timestamp) dt = updatedAt.toDate();

            String formatDateTime(DateTime? t) {
              if (t == null) return 'Unknown date';
              String two(int n) => n.toString().padLeft(2, '0');
              return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
            }

            final dateText = formatDateTime(dt);

            return ListTile(
              leading: CircleAvatar(
                child: Text('${i + 1}'), // ✅ 1–15 numbering
              ),
              title: Text('$gameName (Level $level)'),
              subtitle: Text('$dateText\n$statusText • Score $correct/$total'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenLog(doc.id),
            );
          },

        );
      },
    );
  }
}
