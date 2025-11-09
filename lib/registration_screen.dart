import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED for saving registration data
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
  final _phoneController = TextEditingController(); // CORRECTED: Added Phone Controller
  final _passwordController = TextEditingController(); 
  final _confirmController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _passwordController.text = widget.password;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); // CORRECTED: Dispose phone controller
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
      ),
    );
  }

  Future<void> _register() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim(); // CORRECTED: Read phone
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty || // CORRECTED: Validate phone
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

    await Future.delayed(const Duration(seconds: 1)); // mock delay

    // --- NEW: Save Registration Data to SharedPreferences ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', name);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
    await prefs.setString('address', address);
    await prefs.setString('password', password); // Mock password storage
    // --------------------------------------------------------

    _showSnackBar('Registration successful!', isError: false);

    // Navigate to HomeScreen directly after signup
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );

    setState(() => _isLoading = false);
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
          keyboardType: keyboardType, // Added keyboard type
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
                    'Create Account',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 230, 10, 238)),
                  ),
                  const SizedBox(height: 40),

                  // Full Name
                  _buildTextField(
                    controller: _fullNameController,
                    hint: 'Full Name',
                    icon: Icons.person,
                  ),

                  // Email ID
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email ID',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  // CORRECTED FIELD: Phone Number
                  _buildTextField(
                    controller: _phoneController, 
                    hint: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ), 

                  // Create Password
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Create Password',
                    icon: Icons.lock,
                    obscure: true,
                  ),

                  // Re-enter Password
                  _buildTextField(
                    controller: _confirmController,
                    hint: 'Re-enter Password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),

                  // Address
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Address',
                    icon: Icons.home,
                  ),

                  const SizedBox(height: 10),

                  // REGISTER BUTTON
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

                  // BACK TO LOGIN
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