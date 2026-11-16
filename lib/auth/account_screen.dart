import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/student_profile_view.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/utils/web_layout.dart';

/// Student account: Google sign-in / sign-up (LGU email only) when signed out,
/// and the student's profile when signed in.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, _) {
        final student = StudentAuthService.instance.currentStudent;
        if (student != null) {
          return StudentProfileView(key: ValueKey(student.uid), user: student);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Account')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideWeb(context) ? 520 : 440,
                  ),
                  child: const _SignInPanel(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignInPanel extends StatefulWidget {
  const _SignInPanel();

  @override
  State<_SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<_SignInPanel> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await StudentAuthService.instance.signInWithGoogle();
    } on StudentAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final supported = StudentAuthService.instance.isSupported;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_circle, size: 96, color: primary),
        const SizedBox(height: 12),
        Text(
          'Student Sign in / Sign up',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 10),
        Text(
          'Use your university Google account (ending in .lgu.edu.pk). '
          'New students get a profile created automatically.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: (_loading || !supported) ? null : _signIn,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.login),
            label: Text(
              _loading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (!supported) ...[
          const SizedBox(height: 12),
          Text(
            'Google sign-in is not available on this platform yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ],
    );
  }
}
