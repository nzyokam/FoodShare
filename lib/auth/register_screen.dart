// auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/onboarding_helper.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const RegisterScreen({super.key, required this.showLoginScreen});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Add listener to update password strength indicator
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Email validation method
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Check if it's a valid email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Check if it's specifically a Gmail address
    if (!value.toLowerCase().endsWith('@gmail.com')) {
      return 'Please use a Gmail address (@gmail.com)';
    }

    return null;
  }

  // Password validation method
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Check minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Name validation method
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  // Confirm password validation method
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Password strength indicator widget
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    List<String> requirements = [];

    if (password.length >= 8) {
      strength++;
    } else {
      requirements.add('8+ characters');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
    } else {
      requirements.add('uppercase letter');
    }

    if (RegExp(r'[a-z]').hasMatch(password)) {
      strength++;
    } else {
      requirements.add('lowercase letter');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    } else {
      requirements.add('number');
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    } else {
      requirements.add('special character');
    }

    Color strengthColor;
    String strengthText;

    if (strength < 2) {
      strengthColor = Colors.red;
      strengthText = 'Weak';
    } else if (strength < 4) {
      strengthColor = Colors.orange;
      strengthText = 'Medium';
    } else if (strength < 5) {
      strengthColor = Colors.yellow[700]!;
      strengthText = 'Good';
    } else {
      strengthColor = Colors.green;
      strengthText = 'Strong';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(175),
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  color: strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength / 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
          if (requirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Missing: ${requirements.join(', ')}',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _signUpWithEmail() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      await OnboardingHelper.markOnboardingAsSeen();
      // Navigation handled by AuthGate
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/2.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'FoodShare',
                      style: GoogleFonts.bebasNeue(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      'Join us in fighting hunger! 🤝',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Name TextFormField with validation
                    TextFormField(
                      controller: _nameController,
                      validator: _validateName,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outlined),
                        filled: true,
                        fillColor: const Color.fromARGB(78, 195, 195, 195),
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 188, 187, 187),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email TextFormField with validation
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        hintText: 'Email (Gmail only)',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: const Color.fromARGB(78, 195, 195, 195),
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 188, 187, 187),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password TextFormField with validation
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(78, 195, 195, 195),
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 188, 187, 187),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorStyle: const TextStyle(color: Colors.red),
                        errorMaxLines: 2,
                      ),
                    ),

                    // Password strength indicator
                    _buildPasswordStrengthIndicator(),

                    const SizedBox(height: 20),

                    // Confirm Password TextFormField with validation
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(78, 195, 195, 195),
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 188, 187, 187),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUpWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(180),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.showLoginScreen,
                          child: const Text(
                            ' Login now!',
                            style: TextStyle(
                              color: Color.fromARGB(231, 24, 60, 45),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
