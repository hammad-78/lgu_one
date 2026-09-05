import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/auth/verify_email_screen.dart';
import '../../utils/utils.dart';
import '../round_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool loading = false;

  /// LGU EMAIL REGEX - Supports prefixes like f20, fa22, sp23 and subdomains
  final RegExp lguRegex = RegExp(
    r'^[a-z]+\d{2}-[a-z]+-\d+@([a-z]+\.)?lgu\.edu\.pk$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim().toLowerCase(),
          password: passwordController.text.trim(),
        );

        try {
          await userCredential.user!.sendEmailVerification();
          Utils().toastMessage("Verification email sent! Check your inbox & SPAM folder.");
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
          );
        } catch (e) {
          // If mail fails, delete the user immediately so Auth stays clean
          await userCredential.user!.delete();
          Utils().toastMessage("Failed to send verification email. Try again.");
        }
      } on FirebaseAuthException catch (e) {
        Utils().toastMessage(e.message.toString());
      } catch (e) {
        Utils().toastMessage("An unexpected error occurred");
      } finally {
        if (mounted) setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF021E16) : const Color(0xFF4CAF50);
    final secondaryColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF81C784);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF021E16) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.school, size: 80, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 25),
                    Text("LGU Connect", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "LGU Student Email",
                        hintText: "fa22-bscs-001@lgu.edu.pk",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Enter email";
                        if (!lguRegex.hasMatch(value.trim())) {
                          return "Enter valid LGU email (e.g. fa22-bscs-001@lgu.edu.pk)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? "Minimum 6 characters" : null,
                    ),
                    const SizedBox(height: 35),
                    RoundButton(
                      title: "Signup",
                      width: double.infinity,
                      loading: loading,
                      ontap: signup,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Already have an account? Login", style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
                    ),
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
