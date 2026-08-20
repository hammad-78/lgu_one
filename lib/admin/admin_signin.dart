import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_home.dart';
import '../utils/utils.dart';

class AdminSignin extends StatefulWidget {
  const AdminSignin({super.key});

  @override
  State<AdminSignin> createState() => _AdminSigninState();
}

class _AdminSigninState extends State<AdminSignin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = credential.user;
      if (user == null) throw Exception("Authentication failed");

      // Check the 'admins' collection
      final DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        _showError("Access Denied: This account is not in the Admin database.");
        return;
      }

      final data = adminDoc.data() as Map<String, dynamic>?;
      
      // Robust admin check (handles bool, string, and role fields)
      final bool isAdmin = data?['isAdmin'] == true || 
                          data?['isAdmin']?.toString().toLowerCase() == 'true' ||
                          data?['role']?.toString().toLowerCase() == 'admin';

      if (!isAdmin) {
        await _auth.signOut();
        _showError("Access Denied: You do not have administrator permissions.");
        return;
      }

      if (!mounted) return;
      Utils().toastMessage("Access Granted");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHome()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential': return 'Invalid email or password.';
      case 'wrong-password': return 'Incorrect password.';
      case 'too-many-requests': return 'Account temporarily locked. Try again later.';
      default: return 'Sign-in failed ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Admin Sign In"),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 90,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "LGU Connect Admin",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Enter email" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    onFieldSubmitted: (_) => _handleSignIn(),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Enter password" : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Sign In"),
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
