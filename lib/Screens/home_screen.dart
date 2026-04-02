import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'game_selection.dart';
import 'package:math_stars/Services/auth-service.dart';
import 'teacher_dashboard_screen.dart';
import 'student_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'package:math_stars/Widgets/ui_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      body: uid == null
          ? const Center(child: Text('Not signed in.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() ?? {};
          final role = (data['role'] ?? 'student').toString();

          final isStudent = role == 'student';
          final isTeacher = role == 'teacher';
          final isParent = role == 'parent';

          return Stack(
              children: [
              // Background gradient and Stars overlay
              const SpaceBackground(),

              // ----- PLANETS (soft blobs) -----
              Positioned(
                top: -50,
                left: -40,
                child: _PlanetBlob(
                  size: 160,
                  color: const Color(0xFF3A86FF).withValues(alpha: 0.25),
                ),
              ),
              Positioned(
                bottom: -70,
                right: -60,
                child: _PlanetBlob(
                  size: 220,
                  color: const Color(0xFFF72585).withValues(alpha: 0.18),
                ),
              ),

              // ----- CONTENT -----
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          GlassIconButton(
                            icon: Icons.rocket_launch,
                            onTap: () {
                              // ToDo: Avatar Screen
                            },
                          ),

                          const Spacer(),

                          GlassIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {
                              // ToDo: Settings
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Mission card (more playful)
                      Center(
                        child: Column(
                          children: [
                              Image.asset(
                                'assets/images/project_logo6.png',
                                width: 420,
                                height: 220,
                                fit: BoxFit.contain,
                              ),

                            const SizedBox(height: 0),
                            const Text(
                              'Hey Astronaut!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isStudent
                                  ? 'Complete missions and earn ⭐ stars!'
                                  : isTeacher
                                  ? 'Track your class missions 🚀'
                                  : 'Check your child’s star journey 🌙',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Big “Launch” button (students only)
                      if (isStudent) ...[
                        _BigSpaceButton(
                          text: 'Launch Mission',
                          emoji: '🚀',
                          fill: const Color(0xFFFFD166), // yellow button
                          textColor: Colors.black,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const GameSelectionScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Dashboard button
                      _BigSpaceButton(
                        text: isTeacher
                            ? 'Teacher Dashboard'
                            : isParent
                            ? 'Parent Dashboard'
                            : 'Mission Progress',
                        emoji: '📈',
                        fill: Colors.white.withValues(alpha: 0.10),
                        textColor: Colors.white,
                        outline: true,
                        onTap: () {
                          if (isStudent) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                            );
                          } else if (isTeacher) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
                            );
                          } else if (isParent) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Log out
                      _BigSpaceButton(
                        text: 'Log out',
                        emoji: '',
                        fill: Colors.white.withValues(alpha: 0.08),
                        textColor: Colors.white,
                        outline: true,
                        onTap: () async {
                          await AuthService().signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MathsStarsLoginScreen()),
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------- UI HELPERS ----------

class _BigSpaceButton extends StatelessWidget {
  const _BigSpaceButton({
    required this.text,
    required this.emoji,
    required this.fill,
    required this.textColor,
    required this.onTap,
    this.outline = false,
  });

  final String text;
  final String emoji;
  final Color fill;
  final Color textColor;
  final VoidCallback onTap;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: textColor,
          elevation: outline ? 0 : 14,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: outline
                ? BorderSide(color: Colors.white.withValues(alpha:0.22), width: 1.2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanetBlob extends StatelessWidget {
  const _PlanetBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
