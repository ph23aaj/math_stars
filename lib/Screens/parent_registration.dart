import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../Services/auth-service.dart';

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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text('Registration - Parents', style: TextStyle(color: Colors.black)),
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

              _label('Create Parent Username:'),
              _input(controller: _parentUsernameController),

              const SizedBox(height: 16),

              _label('Create Parent Password / PIN:'),
              _input(controller: _parentPasswordController, isPassword: true, isNumeric: true),

              const SizedBox(height: 24),

              _label("Child's Username:"),
              _input(controller: _childUsernameController),

              const SizedBox(height: 16),

              _label("Child's Password / PIN:"),
              _input(controller: _childPasswordController, isPassword: true, isNumeric: true),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registerParent,
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
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _input({
    required TextEditingController controller,
    bool isPassword = false,
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade300,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
