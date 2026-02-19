import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Services/auth-service.dart';
import 'student_dashboard_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parentUid = AuthService().currentUser?.uid;
    if (parentUid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final childrenQuery = FirebaseFirestore.instance
        .collection('parents')
        .doc(parentUid)
        .collection('children')
        .orderBy('linkedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: childrenQuery.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No children linked yet.'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final childUid = (d['childUid'] ?? docs[i].id).toString();
              final childUsername = (d['childUsername'] ?? 'Child').toString();

              return ListTile(
                title: Text(childUsername),
                subtitle: Text('Child ID: $childUid'),
                trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }
}
