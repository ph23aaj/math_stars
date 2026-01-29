import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Not signed in.'))
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // Top bar: Home icon (left) - Title (centre) - Settings (right)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_outlined, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 30),
                    onPressed: () {
                      // TODO: settings page later
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Main content scroll (in case smaller phones)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProfileCard(uid: uid),

                      const SizedBox(height: 18),

                      // Grey placeholder bar (like your sketch)
                      Container(
                        height: 48,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Badge / Level / Streak',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Topics',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _TotalResultsCard(uid: uid),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

        final displayName = ('$firstName $lastName').trim().isEmpty
            ? 'Student'
            : ('$firstName $lastName').trim();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar circle (placeholder)
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name placeholder bar
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Class placeholder bar
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        className.isEmpty ? 'Class: —' : 'Class: $className',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _TotalResultsCard extends StatelessWidget {
  const _TotalResultsCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final progressDoc = FirebaseFirestore.instance.collection('progress').doc(uid);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Total Results',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          StreamBuilder<DocumentSnapshot>(
            stream: progressDoc.snapshots(),
            builder: (context, snap) {
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final gamesPlayed = (data['totalGamesPlayed'] ?? 0) as int;
              final correct = (data['totalCorrect'] ?? 0) as int;
              final incorrect = (data['totalIncorrect'] ?? 0) as int;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatPill(label: 'Games', value: gamesPlayed.toString()),
                      _StatPill(label: 'Correct', value: correct.toString()),
                      _StatPill(label: 'Wrong', value: incorrect.toString()),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Big “chart” placeholder (matches your sketch)
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Chart / Results Visual (later)',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
