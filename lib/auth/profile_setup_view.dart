import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/utils/flushbar.dart';

/// Shown once, right after a student's first sign-in: confirms their name and
/// asks for degree, semester and bio. "Skip for now" is always available.
class ProfileSetupView extends StatefulWidget {
  final User user;

  /// Name already on the profile (from Google on first sign-in).
  final String initialName;

  const ProfileSetupView({
    super.key,
    required this.user,
    required this.initialName,
  });

  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  static const int _maxSemester = 10;
  static const int _bioMax = 200;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  final _degree = TextEditingController();
  final _bio = TextEditingController();
  int? _semester;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _degree.dispose();
    _bio.dispose();
    super.dispose();
  }

  String get _firstName {
    final first = widget.initialName.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'there' : first;
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // Saving sets setupDone; the Account screen then shows the profile.
      await StudentAuthService.instance.updateProfile(
        widget.user.uid,
        name: _name.text,
        degree: _degree.text,
        semester: _semester,
        bio: _bio.text,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showFlushbar(
        context,
        'Could not save your profile. Please try again.',
        color: Colors.red.shade900,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    try {
      await StudentAuthService.instance.skipSetup(widget.user.uid);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _skip,
            style: TextButton.styleFrom(
              foregroundColor: theme.appBarTheme.foregroundColor,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_firstName',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your LGU account is ready. Tell other students what '
                      'you study. You can change this any time from Account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 60,
                      decoration: _decoration(
                        theme,
                        label: 'Name',
                        icon: Icons.badge_outlined,
                      ).copyWith(counterText: ''),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _degree,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      maxLength: 40,
                      decoration: _decoration(
                        theme,
                        label: 'Degree Program',
                        icon: Icons.school,
                        hint: 'e.g. BSCS',
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _semester,
                      decoration: _decoration(
                        theme,
                        label: 'Semester',
                        icon: Icons.calendar_month_outlined,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      items: [
                        for (var i = 1; i <= _maxSemester; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text('Semester $i'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _semester = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bio,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: _bioMax,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        theme,
                        label: 'Bio',
                        icon: Icons.notes,
                        hint: 'A line or two about yourself',
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _finish,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Finish setup',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _skip,
                        child: const Text('Skip for now'),
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

  InputDecoration _decoration(
    ThemeData theme, {
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final primary = theme.colorScheme.primary;
    final line = theme.colorScheme.onSurface.withValues(alpha: 0.2);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, color: primary),
      border: border(line),
      enabledBorder: border(line),
      focusedBorder: border(primary, 2),
    );
  }
}
