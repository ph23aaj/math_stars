import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'game_selection.dart';
import 'package:math_stars/Services/auth-service.dart';

import 'teacher_dashboard_screen.dart';
import 'student_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      // Stream that emits nothing; UI will show "Not signed in"
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: uid == null
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: avatar + title + settings
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFDDDDDD),
                      ),
                      const Spacer(),
                      const Text(
                        'Maths Stars',
                        style: TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          // TODO: settings
                        },
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Logo
                  Image.asset(
                    'assets/images/project_logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),

                  // Banner
                  Container(
                    height: 40,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text(
                      'Lets Learn Some Maths!',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Play Game only for students
                  if (isStudent) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GameSelectionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 26),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Play Game'),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // View Dashboard routes based on role
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isStudent) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StudentDashboardScreen(),
                            ),
                          );
                        } else if (isTeacher) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TeacherDashboardScreen(),
                            ),
                          );
                        } else if (isParent) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                          );
                        }

                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        isTeacher
                            ? 'View Teacher Dashboard'
                            : isParent
                            ? 'View Parent Dashboard'
                            : 'View Dashboard',
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Log out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (!context.mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MathsStarsLoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Log out'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
