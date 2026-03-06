import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Services/auth-service.dart';
import 'teacher_student_progress_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  Future<Map<String, dynamic>> _loadTeacher() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) throw Exception('Teacher profile not found.');
    if (data['role'] != 'teacher') throw Exception('This account is not a teacher.');

    final classId = (data['classId'] as String?)?.trim() ?? '';
    if (classId.isEmpty) throw Exception('Teacher classId is missing.');

    final className = (data['className'] as String?)?.trim() ?? '';
    if (className.isEmpty) throw Exception('Teacher class name is missing.');

    return {'uid': uid, 'className': className, 'classId': classId};
  }

  @override
  Widget build(BuildContext context) {
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
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadTeacher(),
              builder: (context, teacherSnap) {
                if (teacherSnap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (teacherSnap.hasError) {
                  return Center(
                    child: Text(
                      teacherSnap.error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final className = teacherSnap.data!['className'] as String;

                final classId = teacherSnap.data!['classId'] as String;

                final studentsQuery = FirebaseFirestore.instance
                    .collection('students')
                    .where('classId', isEqualTo: classId);

                return Padding(
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
                              'Teacher Dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _GlassIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {
                              // TODO later
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // CLASS HEADER CARD (centred + not too wide)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Class',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text('🛰️', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        className,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Students who registered using this class name.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // STUDENT LIST (in a solid panel for readability)
                      Expanded(
                        child: _PanelCard(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: studentsQuery.snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snap.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snap.error}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final docs = snap.data!.docs;
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No students found yet.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                itemBuilder: (context, i) {
                                  final doc = docs[i];
                                  final d = doc.data() as Map<String, dynamic>;

                                  final first = (d['firstName'] ?? '').toString().trim();
                                  final last = (d['lastName'] ?? '').toString().trim();

                                  final displayName =
                                  ('$first $last').trim().isEmpty ? 'Student' : '$first $last';

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
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Tap to view progress (coming next)',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.70),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TeacherStudentProgressScreen(studentUid: doc.id),
                                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ SOLID PANEL (READABILITY) ------------------

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1026).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1.2),
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