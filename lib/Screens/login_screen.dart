import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';

class MathsStarsLoginScreen extends StatefulWidget {
  const MathsStarsLoginScreen({super.key});

  @override
  State<MathsStarsLoginScreen> createState() => _MathsStarsLoginScreenState();
}

class _MathsStarsLoginScreenState extends State<MathsStarsLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithUsername(
        username: username,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${_friendlyAuthError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect password.';
    }
    if (msg.contains('user-not-found')) {
      return 'Username not found.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return 'Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Maths Stars',
                  style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              Image.asset(
                'assets/images/project_logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),

              Container(
                height: 75,
                alignment: Alignment.center,
                child: const Text(
                  'Please Sign In',
                  style: TextStyle(color: Colors.black, fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 5),

              const Text('Username:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Password:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegistrationScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
