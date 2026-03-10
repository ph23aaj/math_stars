import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';
import '../widgets/ui_cards.dart';

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
      body: Stack(
        children: [
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 0),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/project_logo6.png',
                          width: 450,
                          height: 280,
                          fit: BoxFit.contain,
                        ),

                            const SizedBox(height: 0),

                            Text(
                              'Welcome back, Astronaut! 🚀',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Sign in to continue your maths mission',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Username',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.90),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            _SpaceTextField(
                              controller: _usernameController,
                              hintText: 'Enter username',
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 18),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.90),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            _SpaceTextField(
                              controller: _passwordController,
                              hintText: 'Enter password',
                              obscureText: true,
                              onSubmitted: (_) => _isLoading ? null : _login(),
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD166),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 12,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Text(
                                  'Launch Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1.4,
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTextField extends StatelessWidget {
  const _SpaceTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFFFD166),
            width: 1.5,
          ),
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