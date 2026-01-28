import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
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

  Future<void> _registerStudent() async {
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
      await AuthService().signUpStudentWithUsername(
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
        SnackBar(content: Text('Registration failed: ${_friendlySignUpError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignUpError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already taken')) return 'That username is already taken.';
    if (msg.contains('email-already-in-use')) return 'That username is already taken.';
    if (msg.contains('weak-password')) return 'Password/PIN is too weak.';
    if (msg.contains('network')) return 'Network error. Check your connection.';
    return 'Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Registration - Students',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Center(
                child: Image.asset(
                  'assets/images/project_logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              _label('First Name:'),
              _input(controller: _firstNameController),

              const SizedBox(height: 16),

              _label('Last Name'),
              _input(controller: _lastNameController),

              const SizedBox(height: 16),

              _label('Class Name:'),
              _input(controller: _classNameController),

              const SizedBox(height: 16),

              _label('Create Username:'),
              _input(controller: _usernameController),

              const SizedBox(height: 16),

              _label('Create Password / PIN:'),
              _input(controller: _passwordController, isPassword: true),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registerStudent,
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
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade300,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
