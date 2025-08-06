// auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../services/auth_service.dart';
import '../services/social_auth_service.dart';
import '../pages/forgot_password_page.dart';
import '../utils/onboarding_helper.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _socialAuthService = SocialAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _loadingProvider = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingProvider = 'email';
    });

    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await OnboardingHelper.markOnboardingAsSeen();
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      _showError(message);
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = '';
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingProvider = 'google';
    });

    try {
      final userCredential = await _socialAuthService.signInWithGoogle();
      if (userCredential != null) {
        await OnboardingHelper.markOnboardingAsSeen();
        // Navigation handled by AuthGate
      }
    } catch (e) {
      _showError('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = '';
        });
      }
    }
  }

  // Future<void> _signInWithApple() async {
  //   // Check if Apple Sign In is available
  //   if (!kIsWeb) {
  //     // For mobile, we need to import Platform conditionally
  //     try {
  //       // Use dynamic check for platform
  //       final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  //       final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

  //       if (!isIOS && !isMacOS) {
  //         _showError(
  //           'Apple Sign In is only available on Apple devices and web',
  //         );
  //         return;
  //       }
  //     } catch (e) {
  //       // Platform check failed, proceed anyway
  //     }
  //   }

  //   setState(() {
  //     _isLoading = true;
  //     _loadingProvider = 'apple';
  //   });

  //   try {
  //     final userCredential = await _socialAuthService.signInWithApple();
  //     if (userCredential != null) {
  //       await OnboardingHelper.markOnboardingAsSeen();
  //       // Navigation handled by AuthGate
  //     }
  //   } catch (e) {
  //     _showError('Apple sign-in failed: ${e.toString()}');
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //         _loadingProvider = '';
  //       });
  //     }
  //   }
  // }

  // Future<void> _signInWithGitHub() async {
  //   setState(() {
  //     _isLoading = true;
  //     _loadingProvider = 'github';
  //   });

  //   try {
  //     final userCredential = await _socialAuthService.signInWithGitHub();
  //     if (userCredential != null) {
  //       await OnboardingHelper.markOnboardingAsSeen();
  //       // Navigation handled by AuthGate
  //     }
  //   } catch (e) {
  //     _showError('GitHub sign-in failed: ${e.toString()}');
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //         _loadingProvider = '';
  //       });
  //     }
  //   }
  // }

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
                    'Welcome back, you\'ve been missed!',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),
                  // Social Login Buttons
                  _buildSocialLoginButton(
                    onPressed: _signInWithGoogle,
                    icon: 'lib/assets/google_logo.png',
                    label: 'Continue with Google',
                    isLoading: _isLoading && _loadingProvider == 'google',
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    borderColor: Colors.grey[300]!,
                  ),
                  const SizedBox(height: 20),
                  // Or divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(160),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 12),
                  // Email TextField
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Email',
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
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password TextField
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
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
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: _isLoading
                              ? Colors.grey
                              : const Color.fromARGB(231, 24, 60, 45),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading && _loadingProvider == 'email'
                          ? null
                          : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading && _loadingProvider == 'email'
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Apple Sign-In - Show on web and Apple platforms
                  // if (kIsWeb ||
                  //     defaultTargetPlatform == TargetPlatform.iOS ||
                  //     defaultTargetPlatform == TargetPlatform.macOS) ...[
                  //   _buildSocialLoginButton(
                  //     onPressed: _signInWithApple,
                  //     icon: 'lib/assets/apple_logo.png',
                  //     label: 'Continue with Apple',
                  //     isLoading: _isLoading && _loadingProvider == 'apple',
                  //     backgroundColor: Colors.black,
                  //     textColor: Colors.white,
                  //     useIconFont: true,
                  //     iconData: Icons.apple,
                  //   ),
                  //   const SizedBox(height: 12),
                  // ],

                  // GitHub Sign-In - Only show on web
                  // if (kIsWeb) ...[
                  //   _buildSocialLoginButton(
                  //     onPressed: _signInWithGitHub,
                  //     icon: 'lib/assets/github_logo.png',
                  //     label: 'Continue with GitHub',
                  //     isLoading: _isLoading && _loadingProvider == 'github',
                  //     backgroundColor: const Color(0xFF24292e),
                  //     textColor: Colors.white,
                  //     useIconFont: true,
                  //     iconData: Icons.code,
                  //   ),
                  // ],
                  const SizedBox(height: 25),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(180),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : widget.showRegisterScreen,
                        child: Text(
                          ' Register now!',
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.grey
                                : const Color.fromARGB(231, 24, 60, 45),
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
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required String icon,
    required String label,
    required bool isLoading,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    bool useIconFont = false,
    IconData? iconData,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading && !isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (useIconFont && iconData != null)
                    Icon(iconData, size: 20)
                  else
                    Image.asset(
                      icon,
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(iconData ?? Icons.login, size: 20);
                      },
                    ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
