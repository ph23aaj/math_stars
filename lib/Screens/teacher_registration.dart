import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';
import '../widgets/ui_cards.dart';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  State<TeacherRegistrationScreen> createState() => _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _classNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerTeacher() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final className = _classNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        className.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().signUpTeacherWithUsername(
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        className: className,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${_friendlySignUpError(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignUpError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('already taken')) return 'That username is already taken.';
    if (msg.contains('email-already-in-use')) {
      return 'That username is already taken.';
    }
    if (msg.contains('class name already exists')) {
      return 'That class name already exists. Choose another.';
    }
    if (msg.contains('weak-password')) {
      return 'Password/PIN is too weak.';
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
                  Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back,
                        onTap: _isLoading ? () {} : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Teacher Registration',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const SizedBox(width: 44, height: 44),
                    ],
                  ),

                  const SizedBox(height: 8),

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
                        Text(
                          'Create your teacher account 🛰️',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a class and guide your students through their maths missions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _label('First Name'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _firstNameController,
                    hintText: 'Enter first name',
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label('Last Name'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _lastNameController,
                    hintText: 'Enter last name',
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label('Create Class Name'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _classNameController,
                    hintText: 'Choose a class name',
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label('Create Username'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _usernameController,
                    hintText: 'Choose a username',
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label('Create Password / PIN'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _passwordController,
                    hintText: 'Choose a password or PIN',
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _isLoading ? null : _registerTeacher(),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerTeacher,
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
                        'Launch Registration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.90),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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