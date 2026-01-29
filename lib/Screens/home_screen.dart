import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'game_selection.dart';
import 'package:math_stars/Services/auth-service.dart';
import 'teacher_dashboard_screen.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    'Maths Starss',
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
                      color: Colors.black
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Play Game button
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

              // View Dashboard
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: go to dashboard
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('View Dashboard'),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Teacher Dashboard'),
                ),
              ),


              // Log out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await AuthService().signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MathsStarsLoginScreen()),
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
        ),
      ),
    );
  }
}
