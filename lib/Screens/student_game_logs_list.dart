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
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No missions completed yet 🚀',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onOpenLog(doc.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$gameName (Level $level)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$statusText • Score $correct/$total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}