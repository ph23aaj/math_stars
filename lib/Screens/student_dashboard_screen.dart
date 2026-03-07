import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_stars/Widgets/ui_cards.dart';
import 'student_game_logs_list.dart';
import 'student_game_log_detail_screen.dart';
import '../Widgets/game_accuracy_pie_grid.dart';
import '../Widgets/accuracy_line_chart_card.dart';



class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key, this.uidOverride});

  final String? uidOverride;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final uid = uidOverride ?? _myUid;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient and Stars overlay
          const SpaceBackground(),

          SafeArea(
            child: uid == null
                ? const Center(
              child: Text('Not signed in.', style: TextStyle(color: Colors.white)),
            )
                : Padding(
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
                          'Dashboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () {
                          // TODO: settings later
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: _ProfileCard(uid: uid),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: GlassCard(
                                child: SizedBox(
                                  height: 254,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('🏅', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.9))),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Badges / Level / Streak',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // later: badges content goes here
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Coming soon…',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Section title
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Chart card
                          AccuracyLineChartCard(uid: uid),
                          const SizedBox(height: 14),

                          // Pie charts
                          GameAccuracyPieGrid(uid: uid),
                          const SizedBox(height: 18),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Past games',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Wrap logs list in a glass container so it matches theme
                          GlassCard(
                            child: StudentGameLogsList(
                              uid: uid,
                              onOpenLog: (logId) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentGameLogDetailScreen(uid: uid, logId: logId),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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


class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final studentDoc = FirebaseFirestore.instance.collection('students').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: studentDoc.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final firstName = (data['firstName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        final className = (data['className'] ?? '').toString();

        final displayName = ('$firstName $lastName').trim().isEmpty ? 'Student' : ('$firstName $lastName').trim();

        return GlassCard(
          child: Row(
            children: [
              // Avatar “planet”
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.26),
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🪐',
                  style: TextStyle(fontSize: 28, color: Colors.white.withValues(alpha: 0.95)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      className.isEmpty ? 'Class: —' : 'Class: $className',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          color: Colors.white.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
