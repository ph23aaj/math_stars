import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';
import '../widgets/ui_cards.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _parentUsernameController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _childUsernameController = TextEditingController();
  final _childPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _parentUsernameController.dispose();
    _parentPasswordController.dispose();
    _childUsernameController.dispose();
    _childPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerParent() async {
    final parentUsername = _parentUsernameController.text.trim();
    final parentPassword = _parentPasswordController.text;
    final childUsername = _childUsernameController.text.trim();
    final childPassword = _childPasswordController.text;

    if (parentUsername.isEmpty ||
        parentPassword.isEmpty ||
        childUsername.isEmpty ||
        childPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().signUpParentWithUsername(
        parentUsername: parentUsername,
        parentPassword: parentPassword,
        childUsername: childUsername,
        childPassword: childPassword,
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
    if (msg.contains('child username not found')) {
      return 'Child username not found.';
    }
    if (msg.contains('child username/password is incorrect')) {
      return 'Child username or password is incorrect.';
    }
    if (msg.contains('not a student account')) {
      return 'That child username is not a student account.';
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
                          'Parent Registration',
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
                          'Create your parent account 🌙',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Link to your child and track their maths journey',
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

                  _label('Create Parent Username'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _parentUsernameController,
                    hintText: 'Choose a parent username',
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label('Create Parent Password / PIN'),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _parentPasswordController,
                    hintText: 'Choose a parent password or PIN',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  _label("Child's Username"),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _childUsernameController,
                    hintText: "Enter your child's username",
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _label("Child's Password / PIN"),
                  const SizedBox(height: 8),
                  _SpaceTextField(
                    controller: _childPasswordController,
                    hintText: "Enter your child's password or PIN",
                    obscureText: true,
                    onSubmitted: (_) => _isLoading ? null : _registerParent(),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerParent,
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