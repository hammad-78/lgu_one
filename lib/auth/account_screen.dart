import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/student_profile_view.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/utils/app_cached_image.dart';
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _CampusBackground(),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideWeb(context) ? 480 : 420,
                      ),
                      child: const _SignInPanel(),
                    ),
                  ),
                ),
              ),
            ],
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
    final supported = StudentAuthService.instance.isSupported;
    const onPhoto = Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your campus,\nin one app.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: onPhoto,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'News, jobs, events, societies and lost & found from '
          'Lahore Garrison University, made by students for students.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: onPhoto.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 32),
        _GoogleSignInButton(
          loading: _loading,
          onPressed: (_loading || !supported) ? null : _signIn,
        ),
        const SizedBox(height: 12),
        Text(
          supported
              ? 'Use your university mail ending in .lgu.edu.pk'
              : 'Google sign-in is not available on this platform yet.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onPhoto.withValues(alpha: 0.7),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF8A80)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Blurred LGU campus photo with a dark fade so the text stays readable.
class _CampusBackground extends StatelessWidget {
  const _CampusBackground();

  static const _photoUrl =
      'https://student.lgu.edu.pk/Content/Theme2/images/blur_login_img.jpg';

  @override
  Widget build(BuildContext context) {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3D2E), Color(0xFF021E16)],
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: fallback),
        if (kIsWeb)
          // The LGU server sends no CORS headers, so Flutter web can't draw
          // the image itself; let the browser show it as a plain <img>.
          Image.network(
            _photoUrl,
            fit: BoxFit.cover,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (_, _, _) => fallback,
          )
        else
          const AppCachedImage(
            imageUrl: _photoUrl,
            memCacheWidth: 1200,
            memCacheHeight: 1600,
            placeholder: fallback,
            errorWidget: fallback,
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.4, 1],
              colors: [Color(0x66000000), Color(0x88000000), Color(0xEE000000)],
            ),
          ),
        ),
      ],
    );
  }
}

/// White pill button in Google's sign-in style: the "G" mark and
/// "Sign in with Google".
class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.85),
          disabledForegroundColor: const Color(0xFF1F1F1F),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : const CustomPaint(
                    size: Size.square(20),
                    painter: _GoogleLogoPainter(),
                  ),
            const SizedBox(width: 12),
            Text(
              loading ? 'Signing in…' : 'Sign in with Google',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws Google's four-colour "G" so no image asset is needed.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Angles run clockwise from 3 o'clock; the opening sits top-right.
    canvas.drawArc(
      rect,
      _rad(-140),
      _rad(100),
      false,
      arc(const Color(0xFFEA4335)),
    );
    canvas.drawArc(
      rect,
      _rad(135),
      _rad(85),
      false,
      arc(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      _rad(45),
      _rad(90),
      false,
      arc(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      _rad(0),
      _rad(45),
      false,
      arc(const Color(0xFF4285F4)),
    );
    // Blue crossbar from the centre to the right edge.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
