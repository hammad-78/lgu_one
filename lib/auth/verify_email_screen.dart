import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/auth/signIn.dart';
import 'package:lgu_one/home_screen.dart';
import 'package:lgu_one/utils/utils.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _isResending = false;
  bool _isVerified = false;
  Timer? _cooldownTimer;
  Timer? _automaticCheckTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initial check
    _checkVerifiedSilently();
    
    // Automatically check every 3 seconds to catch the link click
    _automaticCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerifiedSilently();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _automaticCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from their email app to our app
    if (state == AppLifecycleState.resumed) {
      _checkVerifiedSilently();
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      Utils().toastMessage("Verification email sent! Check your inbox & SPAM folder.");
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      Utils().toastMessage(e.message ?? "Could not send email");
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// Refreshes the user status. 
  /// Using getIdToken(true) is essential to sync the 'emailVerified' flag locally.
  Future<void> _checkVerifiedSilently() async {
    if (_isVerified || !mounted) return;
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null) {
        await user.reload();
        // Force refresh the token to update the claims (like emailVerified)
        await user.getIdToken(true);
        
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null && freshUser.emailVerified) {
          if (mounted) {
            setState(() => _isVerified = true);
            _handleSuccessVerification(freshUser);
          }
        }
      }
    } catch (e) {
      debugPrint("Verification check failed: $e");
    }
  }

  Future<void> _checkVerifiedManually() async {
    if (_isVerified) return;
    setState(() => _isChecking = true);
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null) {
        await user.reload();
        await user.getIdToken(true);
        
        final freshUser = auth.currentUser;

        if (!mounted) return;

        if (freshUser != null && freshUser.emailVerified) {
          setState(() => _isVerified = true);
          _handleSuccessVerification(freshUser);
        } else {
          Utils().toastMessage("Verification not detected yet. Check your inbox and SPAM folder.");
        }
      }
    } catch (e) {
      Utils().toastMessage("Verification check failed. Try again.");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _handleSuccessVerification(User user) async {
    _automaticCheckTimer?.cancel();
    
    // Save the verified status to Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': true,
        'role': 'student',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore update failed: $e");
    }

    if (!mounted) return;
    Utils().toastMessage("Email verified successfully!");
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _cleanupAndExit() async {
    if (_isVerified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
    
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF021E16) : const Color(0xFF4CAF50);
    final secondaryColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF81C784);
    final email = FirebaseAuth.instance.currentUser?.email ?? "your email";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cleanupAndExit();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF021E16) : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 100, width: 100,
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
                      child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Verify your email",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "A verification link has been sent to:\n$email",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 30),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Important Notice",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "1. Check your SPAM or JUNK folder.\n2. Once you click the link, the app will automatically continue.\n3. If it doesn't, click the button below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkVerifiedManually,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isChecking
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("I've verified, check now"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: (_isResending || _cooldownSeconds > 0) ? null : _resendEmail,
                      child: Text(
                        _cooldownSeconds > 0 ? "Resend in ${_cooldownSeconds}s" : "Resend verification email",
                        style: TextStyle(color: secondaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cleanupAndExit,
                      child: const Text("Cancel and use a different email", style: TextStyle(decoration: TextDecoration.underline, color: Colors.grey)),
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
