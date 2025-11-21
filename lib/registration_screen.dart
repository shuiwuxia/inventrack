// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String email;
  final String password;

  const RegistrationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _addressController = TextEditingController(); // Maps to 'location' in API

  bool _isLoading = false;

  // Constants for API access
  static const String _baseUrl = 'https://inventrack-backend-1.onrender.com';
  static const String _registerEndpoint = '/auth/register';


  @override
  void initState() {
    super.initState();
    // Pre-fill email and password from the login screen attempt
    _emailController.text = widget.email;
    _passwordController.text = widget.password;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ Register API Integration
  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final address = _addressController.text.trim();

    // 1. Validation
    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        address.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    if (password != confirm) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl$_registerEndpoint'); 
      
      // 2. Constructing the API Body according to the required schema
      final body = {
        "full_name": fullName,
        "email": email,
        "password": password,
        "role": "consumer", // Hardcoded role for consumer registration
        "phone": phone,
        "location": address, // Using address as location
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ Registration Successful
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullName);
        await prefs.setString('email', email);
        await prefs.setString('phone', phone);
        await prefs.setString('address', address); // Store address locally as well

        _showSnackBar('Registration successful! Logging you in...', isError: false);
        
        // Navigate to the main application screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (response.statusCode == 400 &&
          data.containsKey("detail") && data["detail"] == "Email already exists") {
        // ❌ Email already exists (Specific FastAPI error)
        _showSnackBar('Email already exists.');
      } else {
        // ❌ General API failure (e.g., phone format error, required fields missing)
        _showSnackBar('Registration failed. Server Message: ${data['detail'] ?? 'Unknown Error'}');
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error connecting to server. Please ensure your backend is running.');
      debugPrint('Network Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Allow back navigation to LoginScreen
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 7, 212, 195),
              Color.fromARGB(255, 105, 10, 230),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1,
                      size: 80, color: Color.fromARGB(255, 199, 231, 13)),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Consumer Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 230, 10, 238)),
                  ),
                  const SizedBox(height: 40),

                  _buildTextField(
                      controller: _fullNameController,
                      hint: 'Full Name',
                      icon: Icons.person),
                  _buildTextField(
                      controller: _emailController,
                      hint: 'Email ID',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress),
                  _buildTextField(
                      controller: _phoneController,
                      hint: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone),
                  _buildTextField(
                      controller: _passwordController,
                      hint: 'Create Password',
                      icon: Icons.lock,
                      obscure: true),
                  _buildTextField(
                      controller: _confirmController,
                      hint: 'Re-enter Password',
                      icon: Icons.lock_outline,
                      obscure: true),
                  _buildTextField(
                      controller: _addressController,
                      hint: 'Address (for Location)',
                      icon: Icons.home),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.blue)
                          : const Text(
                              'Register',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}