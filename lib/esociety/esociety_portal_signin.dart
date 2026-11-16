import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_portal_screen.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/utils/web_layout.dart';

/// Entry to the Entrepreneurship Society portal. Opens the portal straight
/// away when the signed-in account is a society member (or an admin);
/// otherwise shows the portal sign-in.
class EsocietyPortalEntry extends StatefulWidget {
  const EsocietyPortalEntry({super.key});

  @override
  State<EsocietyPortalEntry> createState() => _EsocietyPortalEntryState();
}

class _EsocietyPortalEntryState extends State<EsocietyPortalEntry> {
  String? _checkedUid;
  Future<EsocietyMember?>? _memberFuture;

  Future<EsocietyMember?> _memberFor(User user) {
    if (_checkedUid != user.uid || _memberFuture == null) {
      _checkedUid = user.uid;
      _memberFuture = EsocietyService.instance.memberFor(user);
    }
    return _memberFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (user == null || user.isAnonymous) {
          return const _PortalSignIn();
        }
        return FutureBuilder<EsocietyMember?>(
          future: _memberFor(user),
          builder: (context, member) {
            if (member.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (member.data != null) {
              return EsocietyPortalScreen(
                key: ValueKey(user.uid),
                member: member.data!,
              );
            }
            return _PortalSignIn(signedInAs: user.email);
          },
        );
      },
    );
  }
}

class _PortalSignIn extends StatefulWidget {
  /// Set when someone is signed in whose account has no portal access.
  final String? signedInAs;
  const _PortalSignIn({this.signedInAs});

  @override
  State<_PortalSignIn> createState() => _PortalSignInState();
}

class _PortalSignInState extends State<_PortalSignIn> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final member = await EsocietyService.instance.memberFor(cred.user!);
      if (member == null) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(
            () => _error =
                'This account does not have access to the E-Society portal.',
          );
        }
      }
      // On success the entry widget swaps this screen for the portal.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'user-not-found' ||
            'invalid-credential' ||
            'wrong-password' => 'Invalid email or password.',
            'too-many-requests' => 'Too many attempts. Try again later.',
            _ => 'Sign-in failed (${e.code}).',
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = isWideWeb(context);

    final form = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/idea_icon.png',
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'E-Society Portal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For Entrepreneurship Society members',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (widget.signedInAs != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'You are signed in as ${widget.signedInAs}, which has no '
                        'portal access. Signing in below switches accounts.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter password' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('E-Society Portal')),
      body: wide
          ? Row(
              children: [
                Expanded(flex: 5, child: _brandPanel(context)),
                Expanded(flex: 4, child: form),
              ],
            )
          : form,
    );
  }

  Widget _brandPanel(BuildContext context) {
    final theme = Theme.of(context);
    const onHero = Colors.white;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 0, 24),
      padding: const EdgeInsets.all(48),
      decoration: webHeroDecoration(context),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rocket_launch_outlined, size: 60, color: onHero),
          const SizedBox(height: 24),
          Text(
            'LGU Entrepreneurship Society',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 38,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: onHero,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Review the ideas students share, reply to them, set meeting '
              'dates, and give feedback on student collaborations.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 1.55,
                color: onHero.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
