// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'registration_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Needed for storing user data

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // IMPORTANT: Use the correct base URL for your local FastAPI server
  static const String _baseUrl = 'http://inventrack-backend-1.onrender.com';
  static const String _loginEndpoint = '/auth/login'; 


  // Function to show messages
  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Function to handle login (REVISED to check for User Object)
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl$_loginEndpoint'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // FIX: Sending the body as JSON with 'identifier' field
        body: jsonEncode({
          'identifier': email, 
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // --- CRITICAL FIX: Checking for keys present in the User Object ---
        // We look for 'full_name' or 'email' to confirm successful login.
        if (data.containsKey('full_name') && data.containsKey('email')) {
          _showSnackBar('Login successful!', color: Colors.green);
          
          // Since the backend returned the user object, we can save it to SharedPreferences
          // This ensures the profile screen can load the logged-in user's data.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullName', data['full_name']);
          await prefs.setString('email', data['email']);
          await prefs.setString('phone', data['phone']);
          await prefs.setString('address', data['location'] ?? 'Location not set'); 
          // Note: The backend returned 'location', so we save that as 'address' 
          // for the ProfileScreen to use.

          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Handles cases where the status is 200 but the response is not the expected User Object
          _showSnackBar('Login failed: Unexpected server response body.', color: Colors.orange);
          debugPrint('Unexpected 200 Body: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Standard code for Unauthorized/Invalid Credentials
        _showSnackBar('Login failed. Invalid credentials (Status ${response.statusCode}).');
      } else if (response.statusCode == 422) {
        _showSnackBar('Login failed. Data format error (422). Check identifier/password fields.');
      } else {
        // General error handling
        _showSnackBar('Server error: ${response.statusCode}');
        debugPrint('Server response: ${response.body}');
      }
    } catch (e) {
      // Handles network errors, timeouts, or JSON decoding failures.
      _showSnackBar('Network error. Failed to connect to server: $e');
      debugPrint('Network exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRegistration() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // Pass the required named parameters: email and password
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationScreen(
          email: email, 
          password: password,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Icon(Icons.inventory_2, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Inventrack',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email/Identifier input
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email or Phone (Identifier)',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),

                  // Password input
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _navigateToRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      _showSnackBar('Forgot Password functionality TBD.', color: Colors.blueGrey);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  
                  // Display API status for development/debugging purposes
                  if (!_isLoading) 
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'API Endpoint: $_loginEndpoint',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}