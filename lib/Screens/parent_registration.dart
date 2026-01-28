import 'package:flutter/material.dart';

class ParentRegistrationScreen extends StatelessWidget {
  const ParentRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registration - Parents',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Logo placeholder
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Logo'),
                ),
              ),

              const SizedBox(height: 32),

              // First Name
              _label('First Name:'),
              _input(),

              const SizedBox(height: 16),

              // Last Name
              _label('Last Name'),
              _input(),

              const SizedBox(height: 16),

              // Child's Username
              _label("Child's Username:"),
              _input(),

              const SizedBox(height: 16),

              // Child's Password
              _label("Child's Password:"),
              _input(isPassword: true),

              const SizedBox(height: 16),

              // Create Username
              _label('Create Username:'),
              _input(),

              const SizedBox(height: 16),

              // Create Password
              _label('Create Password:'),
              _input(isPassword: true),

              const SizedBox(height: 32),

              // Register button
              ElevatedButton(
                onPressed: () {
                  // TODO: handle parent registration
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Helper widgets ----------

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _input({bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade300,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
