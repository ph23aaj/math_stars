import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:math_stars/Widgets/ui_cards.dart';
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
          // Background gradient and Stars overlay
          const SpaceBackground(),

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
                          GlassIconButton(
                            icon: Icons.arrow_back,
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
                          GlassIconButton(
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
                          child: GlassCard(
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
                        child: PanelCard(
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
                                separatorBuilder: (_, _) => Divider(
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
                                      'Tap to view progress',
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
