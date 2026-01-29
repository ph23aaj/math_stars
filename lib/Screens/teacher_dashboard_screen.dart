import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Services/auth-service.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  Future<Map<String, dynamic>> _loadTeacher() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) throw Exception('Teacher profile not found.');
    if (data['role'] != 'teacher') throw Exception('This account is not a teacher.');

    final className = (data['className'] as String?)?.trim() ?? '';
    if (className.isEmpty) throw Exception('Teacher class name is missing.');

    return {'uid': uid, 'className': className};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadTeacher(),
        builder: (context, teacherSnap) {
          if (teacherSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (teacherSnap.hasError) {
            return Center(child: Text(teacherSnap.error.toString().replaceFirst('Exception: ', '')));
          }

          final className = teacherSnap.data!['className'] as String;

          final studentsQuery = FirebaseFirestore.instance
              .collection('students')
              .where('className', isEqualTo: className);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Class: $className',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Students who registered with this class name:',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: studentsQuery.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }

                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No students found yet.'));
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final id = docs[i].id;
                        final d = docs[i].data() as Map<String, dynamic>;

                        final first = (d['firstName'] ?? '').toString().trim();
                        final last = (d['lastName'] ?? '').toString().trim();

                        final displayName =
                        ('$first $last').trim().isEmpty ? 'Student' : '$first $last';

                        return ListTile(
                          title: Text(displayName),
                          subtitle: Text('Student ID: $id'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Later: open student progress screen
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
