import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                      _GlassIconButton(
                        icon: Icons.home_outlined,
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
                      _GlassIconButton(
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
                              child: _GlassCard(
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

                          // Your existing chart cards
                          // If these widgets have white backgrounds, they’ll still look fine here.
                          // (Later, we can “space theme” them too if you want.)
                          AccuracyLineChartCard(uid: uid),

                          const SizedBox(height: 14),

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
                          _GlassCard(
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

// ------------------ PROFILE CARD ------------------

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // More solid than glass so charts are readable
        color: const Color(0xFF0B1026).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
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

        return _GlassCard(
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
                    Row(
                      children: [
                        _MiniChip(text: '⭐ Learner'),
                        const SizedBox(width: 8),
                        _MiniChip(text: '🚀 Missions'),
                      ],
                    ),
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

// ------------------ GLASS UI HELPERS ------------------

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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white),
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