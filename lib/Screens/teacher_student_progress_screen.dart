import 'package:flutter/material.dart';
import 'student_dashboard_screen.dart';

class TeacherStudentProgressScreen extends StatelessWidget {
  const TeacherStudentProgressScreen({
    super.key,
    required this.studentUid,
  });

  final String studentUid;

  @override
  Widget build(BuildContext context) {
    // Reuse your existing dashboard UI, but force it to load the selected student
    return StudentDashboardScreen(uidOverride: studentUid);
  }
}