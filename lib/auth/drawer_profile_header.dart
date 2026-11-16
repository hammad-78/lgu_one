import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/account_screen.dart';
import 'package:lgu_one/auth/profile_photo.dart';
import 'package:lgu_one/auth/student_auth_service.dart';

/// Top of the navigation drawer: the signed-in student's photo, name, email
/// and degree/semester, or a sign-in prompt. Tapping it opens Account.
class DrawerProfileHeader extends StatelessWidget {
  /// True inside a [Drawer], which must close before Account opens. False in
  /// the always-visible web sidebar, where popping would leave the home screen.
  final bool inDrawer;

  const DrawerProfileHeader({super.key, this.inDrawer = true});

  void _openAccount(BuildContext context) {
    if (inDrawer) Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlight = theme.colorScheme.primary;

    return Material(
      color: theme.cardTheme.color,
      child: InkWell(
        onTap: () => _openAccount(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: highlight.withValues(alpha: isDark ? 0.3 : 0.25),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            // The sidebar sits below the app bar, so no status-bar inset.
            top: inDrawer,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, inDrawer ? 24 : 22, 12, 20),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, _) {
                  final student = StudentAuthService.instance.currentStudent;
                  if (student == null) return const _SignedOut();
                  return StreamBuilder<
                    DocumentSnapshot<Map<String, dynamic>>
                  >(
                    stream: StudentAuthService.instance.profileStream(
                      student.uid,
                    ),
                    builder: (context, snap) => _SignedIn(
                      user: student,
                      data: snap.data?.data() ?? const {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  final User user;
  final Map<String, dynamic> data;
  const _SignedIn({required this.user, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final saved = (data['name'] ?? '').toString().trim();
    final name = saved.isNotEmpty
        ? saved
        : (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'LGU Student';
    final degree = (data['degree'] ?? '').toString().trim();
    final sem = data['semester'];
    final study = [
      if (degree.isNotEmpty) degree,
      if (sem is int) 'Semester $sem',
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(url: profilePhotoUrl(data, user.photoURL)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    study.isEmpty ? 'Add your degree and semester' : study,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: study.isEmpty ? muted : primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ],
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Avatar(url: null),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Use your LGU Google account to set up your profile',
                    style: TextStyle(fontSize: 13, color: muted, height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primary),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final photo = url;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardTheme.color,
        border: Border.all(color: primary, width: 2),
      ),
      child: ClipOval(
        child: SizedBox.square(
          dimension: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, size: 36, color: primary),
              ),
              if (photo != null)
                Image(
                  key: ValueKey(photo),
                  image: profilePhotoProvider(photo),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
