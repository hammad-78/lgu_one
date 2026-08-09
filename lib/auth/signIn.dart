import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/auth/signUp.dart';
import '../../home_screen.dart';
import '../../utils/utils.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RegExp lguRegex = RegExp(
    r'^[a-z]{2}\d{2}-[a-z]+-\d+@[a-z]+\.lgu\.edu\.pk$',
  );

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        Utils().toastMessage(e.message.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF021E16)
        : const Color(0xFF4CAF50);
    final secondaryColor = isDark
        ? const Color(0xFFD4AF37) // Gold
        : const Color(0xFF81C784); // Soft Green

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// LOGO
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// APP NAME
                    Text(
                      "LGU Connect",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign in with your LGU account",
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// EMAIL FIELD
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "fa22-bscs-1113@cs.lgu.edu.pk",
                        labelText: "LGU Email",
                        prefixIcon: Icon(
                          Icons.email,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? secondaryColor.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter LGU Email";
                        }
                        if (!lguRegex.hasMatch(value.trim())) {
                          return "Enter valid LGU student email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    /// PASSWORD FIELD
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Enter Password",
                        labelText: "Password",
                        prefixIcon: Icon(
                          Icons.lock,
                          color: primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? secondaryColor.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Password";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 35),

                    /// LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// SIGNUP REDIRECT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Signup",
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// CONTINUE WITHOUT ACCOUNT
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: secondaryColor,
                      ),
                      child: Text(
                        "Continue without an account",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                          color: secondaryColor,
                        ),
                      ),
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