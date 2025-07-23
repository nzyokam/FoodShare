import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('Password reset link sent! Check your email.'),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(content: Text(e.message.toString()));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color.fromARGB(255, 152, 166, 152),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'lib/assets/2.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 30),
          Text(
            'FoodShare',
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'Enter your email to receive password reset link',
              style: TextStyle(fontSize: 16),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(25.0),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: const Color.fromARGB(78, 195, 195, 195),
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          MaterialButton(
            onPressed: passwordReset,
            color: const Color(0xFF2E7D32),
            textColor: Colors.white,
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }
}
