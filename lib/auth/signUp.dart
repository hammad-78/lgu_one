import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/home_screen.dart';

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

  /// LGU EMAIL REGEX
  final RegExp lguRegex = RegExp(
    r'^[a-z]{2}\d{2}-[a-z]+-\d+@[a-z]+\.lgu\.edu\.pk$',
  );

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        /// SEND EMAIL VERIFICATION
        await _auth.currentUser!.sendEmailVerification();

        Utils().toastMessage(
          "Verification email sent",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        Utils().toastMessage(
          e.message.toString(),
        );
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
    final textColor = isDark ? Colors.white : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF021E16)
          : Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
          ),

          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// LOGO ICON
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
                      "Create your student account",
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
                        hintText: "fa25-bscs-103@cs.lgu.edu.pk",
                        labelText: "LGU Email",
                        prefixIcon: Icon(
                          Icons.email,
                          color: primaryColor,
                        ),

                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0B3D2E)
                            : Colors.white,

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
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
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
                      obscureText: true,

                      decoration: InputDecoration(
                        hintText: "Enter Password",
                        labelText: "Password",
                        prefixIcon: Icon(
                          Icons.lock,
                          color: primaryColor,
                        ),

                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0B3D2E)
                            : Colors.white,

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
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                      ),

                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Password";
                        }

                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 35),

                    /// SIGNUP BUTTON
                    RoundButton(
                      title: "Signup",
                      width: double.infinity,
                      ontap: () {
                        signup();
                      },
                    ),

                    const SizedBox(height: 18),

                    /// LOGIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          child: Text(
                            "Login",
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
                      onPressed: () {
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