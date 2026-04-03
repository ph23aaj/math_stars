import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:math_stars/Services/auth-service.dart';
import 'package:math_stars/Widgets/ui_cards.dart';
import 'student_dashboard_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parentUid = AuthService().currentUser?.uid;

    if (parentUid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in.')),
      );
    }

    final childrenQuery = FirebaseFirestore.instance
        .collection('parents')
        .doc(parentUid)
        .collection('children')
        .orderBy('linkedAt', descending: true);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient and Stars overlay
          const SpaceBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  // TOP BAR
                  Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Parent Dashboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () {
                          // TODO later
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Linked Children',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'View your child’s progress and activity',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: PanelCard(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: childrenQuery.snapshots(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snap.error}',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No children linked yet.',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final d = doc.data() as Map<String, dynamic>;

                              final childUid = (d['childUid'] ?? doc.id).toString();

                              return StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('students').doc(childUid).snapshots(),
                                builder: (context, studentSnap) {
                                  final studentData = (studentSnap.data?.data() as Map<String, dynamic>?) ?? {};

                                  final firstName = (studentData['firstName'] ?? '').toString().trim();
                                  final lastName = (studentData['lastName'] ?? '').toString().trim();
                                  final className = (studentData['className'] ?? '').toString().trim();

                                  final childName = ('$firstName $lastName').trim().isEmpty
                                      ? 'Child Dashboard'
                                      : ('$firstName $lastName').trim();

                                  return StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance.collection('progress').doc(childUid).snapshots(),
                                    builder: (context, progressSnap) {
                                      final progressData = (progressSnap.data?.data() as Map<String, dynamic>?) ?? {};
                                      final lastPlayedAt = progressData['lastPlayedAt'];

                                      String formatDate(DateTime? dt) {
                                        if (dt == null) return 'Not played yet';
                                        String two(int n) => n.toString().padLeft(2, '0');
                                        return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
                                      }

                                      DateTime? playedDate;
                                      if (lastPlayedAt is Timestamp) {
                                        playedDate = lastPlayedAt.toDate();
                                      }

                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        leading: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.10),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.18),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.92),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          childName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Class: ${className.isEmpty ? '-' : className}\nLast played: ${formatDate(playedDate)}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.72),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        isThreeLine: true,
                                        trailing: Icon(
                                          Icons.chevron_right,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => StudentDashboardScreen(uidOverride: childUid),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
