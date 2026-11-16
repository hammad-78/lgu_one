import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgu_one/auth/profile_photo.dart';
import 'package:lgu_one/auth/profile_setup_view.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/web_layout.dart';

/// The signed-in student's account page. Opens read-only; the Edit button on
/// the completion card switches it to edit mode, where Save sits in the app
/// bar. Email and university are always locked.
class StudentProfileView extends StatefulWidget {
  final User user;
  const StudentProfileView({super.key, required this.user});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  static const int _maxSemester = 10;
  static const int _bioMax = 200;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _degree = TextEditingController();
  final _bio = TextEditingController();
  int? _semester;
  String? _photoUrl;

  // Photo changes made in edit mode, applied only on Save.
  Uint8List? _pendingPhoto;
  bool _pendingRemove = false;

  Map<String, dynamic> _data = const {};
  StreamSubscription<dynamic>? _sub;
  bool _loaded = false;
  bool _editing = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.user.photoURL;
    _name.text = widget.user.displayName ?? '';
    for (final c in [_name, _degree, _bio]) {
      c.addListener(_refresh);
    }
    _sub = StudentAuthService.instance.profileStream(widget.user.uid).listen((
      snapshot,
    ) {
      if (!mounted) return;
      _data = snapshot.data() ?? const {};
      _loaded = true;
      // Never overwrite what the student is typing.
      if (!_editing) _applyData();
      setState(() {});
    }, onError: (_) {});
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Copies the saved profile into the form fields.
  void _applyData() {
    final savedName = (_data['name'] ?? '').toString();
    _name.text = savedName.isNotEmpty
        ? savedName
        : (widget.user.displayName ?? '');
    _degree.text = (_data['degree'] ?? '').toString();
    _bio.text = (_data['bio'] ?? '').toString();
    final sem = _data['semester'];
    _semester = (sem is int && sem >= 1 && sem <= _maxSemester) ? sem : null;
    // A saved null means the student removed their photo, so only fall back
    // to the Google photo when the profile has never stored one.
    _photoUrl = profilePhotoUrl(_data, widget.user.photoURL);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _name.dispose();
    _degree.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      !_pendingRemove &&
      (_pendingPhoto != null || (_photoUrl?.isNotEmpty ?? false));

  void _clearPendingPhoto() {
    _pendingPhoto = null;
    _pendingRemove = false;
  }

  double get _completion {
    final done = [
      _name.text.trim().isNotEmpty,
      _degree.text.trim().isNotEmpty,
      _semester != null,
      _bio.text.trim().isNotEmpty,
    ].where((v) => v).length;
    return done / 4;
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    _applyData();
    _clearPendingPhoto();
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _uploading = _pendingPhoto != null || _pendingRemove;
    });
    try {
      // Photo first: if Storage refuses, nothing else is half-saved.
      if (_pendingRemove) {
        await StudentAuthService.instance.removeProfilePhoto(
          widget.user.uid,
        );
        _photoUrl = null;
      } else if (_pendingPhoto != null) {
        _photoUrl = await StudentAuthService.instance.uploadProfilePhoto(
          widget.user.uid,
          _pendingPhoto!,
        );
      }
      _clearPendingPhoto();

      await StudentAuthService.instance.updateProfile(
        widget.user.uid,
        name: _name.text,
        degree: _degree.text,
        semester: _semester,
        bio: _bio.text,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploading = false;
        _editing = false;
      });
      await showFlushbar(
        context,
        'Profile saved.',
        color: Colors.green.shade900,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploading = false;
      });
      await showFlushbar(
        context,
        'Could not save your profile. Please try again.',
        color: Colors.red.shade900,
        icon: Icons.error_outline,
      );
    }
  }

  /// WhatsApp-style photo menu: camera, gallery and, when there is a photo,
  /// a red Remove option.
  Future<void> _changePhoto() async {
    final hasPhoto = _hasPhoto;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Profile photo',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
              ),
              // Web has no camera picker here; the browser file dialog
              // covers both.
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(kIsWeb ? 'Upload photo' : 'Gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: error),
                  title: Text('Remove photo', style: TextStyle(color: error)),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'remove') {
      await _removePhoto();
      return;
    }
    final source = choice == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      // Preview only; uploaded when the student presses Save.
      setState(() {
        _pendingPhoto = bytes;
        _pendingRemove = false;
      });
    } catch (e) {
      debugPrint('Profile photo pick error: $e');
      if (!mounted) return;
      await showFlushbar(
        context,
        'Could not open that photo. Try a different one.',
        color: Colors.red.shade900,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your photo will be deleted when you save your changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Deleted from Storage only when the student presses Save.
    setState(() {
      _pendingPhoto = null;
      _pendingRemove = true;
    });
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Do you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await StudentAuthService.instance.signOut();
  }

  PreferredSizeWidget _appBar(ThemeData theme) {
    if (!_editing) return AppBar(title: const Text('Account'));

    final fg = theme.appBarTheme.foregroundColor ?? Colors.white;
    return AppBar(
      title: const Text('Edit Profile'),
      automaticallyImplyLeading: false,
      leadingWidth: 84,
      leading: TextButton(
        onPressed: _saving ? null : _save,
        style: TextButton.styleFrom(foregroundColor: fg),
        child: _saving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
            : const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
      actions: [
        IconButton(
          tooltip: 'Cancel',
          onPressed: _saving ? null : _cancelEditing,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = isWideWeb(context);

    // First sign-in: ask for the basics before showing the profile. Finishing
    // or skipping sets setupDone, and the profile stream swaps this out.
    if (_loaded && StudentAuthService.needsSetup(_data)) {
      final saved = (_data['name'] ?? '').toString().trim();
      return ProfileSetupView(
        user: widget.user,
        initialName: saved.isNotEmpty ? saved : (widget.user.displayName ?? ''),
      );
    }

    return PopScope(
      // Back leaves edit mode first instead of closing the page.
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _cancelEditing();
      },
      child: Scaffold(
        appBar: _appBar(theme),
        body: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: wide ? _wideLayout(theme) : _narrowLayout(theme),
                ),
        ),
      ),
    );
  }

  // Phone / narrow layout.
  Widget _narrowLayout(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _avatar(theme, primary),
              const SizedBox(height: 24),
              _completionCard(theme, primary),
              const SizedBox(height: 20),
              _section(
                theme: theme,
                icon: Icons.person_outline,
                title: 'Basic Information',
                children: [
                  _nameField(theme),
                  _emailField(theme),
                  _universityField(theme),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                theme: theme,
                icon: Icons.school_outlined,
                title: 'Academic Details',
                children: [_degreeField(theme), _semesterField(theme)],
              ),
              const SizedBox(height: 20),
              _section(
                theme: theme,
                icon: Icons.edit_note,
                title: 'About You',
                children: [_bioField(theme)],
              ),
              if (!_editing) ...[
                const SizedBox(height: 24),
                _signOutButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Wide (web) layout: ID card on the left, form grid on the right.
  Widget _wideLayout(ThemeData theme) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: WebConstrained(
          maxWidth: 1080,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: _idCard(theme)),
              const SizedBox(width: 32),
              Expanded(child: _formSurface(theme)),
            ],
          ),
        ),
      ),
    );
  }

  /// The student's profile drawn as a university ID card.
  Widget _idCard(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final heading = theme.textTheme.headlineMedium?.color;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final value = _completion;

    final name = _name.text.trim().isEmpty ? 'LGU Student' : _name.text.trim();
    final degree = _degree.text.trim();
    final study = [
      if (degree.isNotEmpty) degree,
      if (_semester != null) 'Semester $_semester',
    ].join(', ');

    const band = 116.0;
    const photo = 120.0;

    return Material(
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green band with the app mark; the photo overlaps its lower edge.
          SizedBox(
            // Photo plus its 4px padding and 2.5px border on each side.
            height: band + photo / 2 + 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: band,
                  padding: const EdgeInsets.fromLTRB(20, 16, 18, 0),
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [Color(0xFF0B3D2E), Color(0xFF145A45)]
                          : const [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/lgu_connect_icon.png',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'LGU Connect',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Student',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  top: band - photo / 2 - 4,
                  child: _avatar(theme, primary, size: photo),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  study.isEmpty ? 'Add your degree and semester' : study,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: study.isEmpty ? muted : primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email ?? '',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
                const SizedBox(height: 22),
                Divider(height: 1, color: primary.withValues(alpha: 0.2)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile completion',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: heading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _progressBar(primary, value),
                const SizedBox(height: 22),
                if (_editing)
                  Text(
                    'Make your changes, then press Save at the top.',
                    style: TextStyle(fontSize: 13, color: muted),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _startEditing,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit profile'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One surface holding all fields, split by headings rather than cards.
  Widget _formSurface(ThemeData theme) {
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _groupHeading(theme, Icons.person_outline, 'Basic information'),
            const SizedBox(height: 18),
            pair(_nameField(theme), _emailField(theme)),
            const SizedBox(height: 16),
            _universityField(theme),
            const SizedBox(height: 34),
            _groupHeading(theme, Icons.school_outlined, 'Academic details'),
            const SizedBox(height: 18),
            pair(_degreeField(theme), _semesterField(theme)),
            const SizedBox(height: 34),
            _groupHeading(theme, Icons.edit_note, 'About you'),
            const SizedBox(height: 18),
            _bioField(theme),
          ],
        ),
      ),
    );
  }

  Widget _groupHeading(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  // Shared fields, used by both layouts.

  Widget _nameField(ThemeData theme) => TextFormField(
    controller: _name,
    readOnly: !_editing,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    maxLength: 60,
    decoration: _decoration(
      theme,
      label: 'Name',
      icon: Icons.badge_outlined,
    ).copyWith(counterText: ''),
    validator: (v) => (v ?? '').trim().isEmpty ? 'Name is required' : null,
  );

  Widget _emailField(ThemeData theme) =>
      _locked(theme, 'Email', Icons.mail_outline, widget.user.email ?? '');

  Widget _universityField(ThemeData theme) => _locked(
    theme,
    'University',
    Icons.account_balance_outlined,
    'Lahore Garrison University',
  );

  Widget _degreeField(ThemeData theme) => TextFormField(
    controller: _degree,
    readOnly: !_editing,
    textCapitalization: TextCapitalization.characters,
    textInputAction: TextInputAction.next,
    maxLength: 40,
    decoration: _decoration(
      theme,
      label: 'Degree Program',
      icon: Icons.school,
      hint: _editing ? 'e.g. BSCS' : 'Not set',
    ).copyWith(counterText: ''),
  );

  Widget _bioField(ThemeData theme) => TextFormField(
    controller: _bio,
    readOnly: !_editing,
    minLines: 3,
    maxLines: 5,
    maxLength: _bioMax,
    textCapitalization: TextCapitalization.sentences,
    decoration: _decoration(
      theme,
      label: 'Bio',
      icon: Icons.notes,
      hint: _editing ? 'A line or two about yourself' : 'Not set',
    ).copyWith(alignLabelWithHint: true, counterText: _editing ? null : ''),
  );

  Widget _signOutButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      onPressed: _signOut,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Sign out'),
    ),
  );

  Widget _progressBar(Color primary, double value) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: 9,
        backgroundColor: primary.withValues(alpha: 0.18),
        valueColor: AlwaysStoppedAnimation(primary),
      ),
    ),
  );

  Widget _semesterField(ThemeData theme) {
    final decoration = _decoration(
      theme,
      label: 'Semester',
      icon: Icons.calendar_month_outlined,
    );

    if (!_editing) {
      return TextFormField(
        key: ValueKey('semester-view-$_semester'),
        initialValue: _semester == null ? '' : 'Semester $_semester',
        readOnly: true,
        decoration: decoration.copyWith(hintText: 'Not set'),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _semester,
      decoration: decoration,
      borderRadius: BorderRadius.circular(14),
      items: [
        for (var i = 1; i <= _maxSemester; i++)
          DropdownMenuItem(value: i, child: Text('Semester $i')),
      ],
      onChanged: (v) => setState(() => _semester = v),
    );
  }

  ImageProvider _photoProvider(String url) => profilePhotoProvider(url);

  Widget _avatar(ThemeData theme, Color primary, {double size = 108}) {
    final pending = _pendingPhoto;
    final photo = _photoUrl;
    final hasPhoto = _hasPhoto;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Solid ring so a background (like the ID card band) never shows
            // through the gap between border and photo.
            color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
            border: Border.all(color: primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: primary.withValues(alpha: 0.15),
                    child: Icon(Icons.person, size: 58, color: primary),
                  ),
                  if (hasPhoto)
                    Image(
                      // Key forces a reload when a new photo replaces the old.
                      key: pending != null
                          ? ObjectKey(pending)
                          : ValueKey(photo),
                      image: pending != null
                          ? MemoryImage(pending)
                          : _photoProvider(photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, _) {
                        debugPrint('Profile photo load error: $error');
                        return const SizedBox.shrink();
                      },
                    ),
                  if (_uploading)
                    const ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_editing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: primary,
              shape: CircleBorder(
                side: BorderSide(
                  color: theme.scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _changePhoto,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.photo_camera,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _completionCard(ThemeData theme, Color primary) {
    final value = _completion;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile Completion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                if (_editing)
                  const SizedBox(width: 8)
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: TextButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 9,
                  backgroundColor: primary.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 19),
                ),
              ],
            ),
            for (final child in children) ...[
              const SizedBox(height: 16),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _locked(ThemeData theme, String label, IconData icon, String value) {
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return TextFormField(
      initialValue: value,
      enabled: false,
      style: TextStyle(color: muted),
      decoration: _decoration(theme, label: label, icon: icon).copyWith(
        filled: true,
        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        suffixIcon: Icon(Icons.lock_outline, size: 20, color: muted),
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
      disabledBorder: border(line),
      // Read-only fields should not look focused when tapped.
      focusedBorder: _editing ? border(primary, 2) : border(line),
    );
  }
}
