import 'package:flutter/material.dart';
import 'package:lgu_one/auth/profile_photo.dart';

/// Colors for the Ventures and E-Society screens. One accent (the app's
/// green), text in ink and grey, red only for destructive things.
class EsTokens {
  final Color ink;
  final Color muted;
  final Color moss;
  final Color rule;
  final Color surface;
  final Color clay;

  const EsTokens._({
    required this.ink,
    required this.muted,
    required this.moss,
    required this.rule,
    required this.surface,
    required this.clay,
  });

  static const _light = EsTokens._(
    ink: Color(0xFF16261F),
    muted: Color(0xFF68756F),
    moss: Color(0xFF2E7D4F),
    rule: Color(0xFFE3E8E4),
    surface: Color(0xFFF3F5F3),
    clay: Color(0xFFB03A2E),
  );

  static const _dark = EsTokens._(
    ink: Color(0xFFE8F1EC),
    muted: Color(0xFF93A69C),
    moss: Color(0xFF8FD19E),
    rule: Color(0xFF1F4537),
    surface: Color(0xFF0A2C21),
    clay: Color(0xFFE59A86),
  );

  static EsTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Type scale: 22 / 16 / 15 / 13, set by weight rather than decoration.
class EsType {
  static TextStyle title(EsTokens t) => TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: t.ink,
  );
  static TextStyle heading(EsTokens t) => TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: t.ink,
  );
  static TextStyle body(EsTokens t) =>
      TextStyle(fontSize: 15, height: 1.5, color: t.ink);
  static TextStyle small(EsTokens t) =>
      TextStyle(fontSize: 13, height: 1.35, color: t.muted);
}

// ─── Small pieces ───────────────────────────────────────────────────────────

/// Round avatar with a photo, or the first letter of [name].
class PersonAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  const PersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: t.surface,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w600,
          color: t.muted,
        ),
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image(
        image: profilePhotoProvider(photoUrl!),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// A heading and its content, with no box around it.
class EsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const EsSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: EsType.heading(t))),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Label and value pairs, label column on the left.
class FactList extends StatelessWidget {
  final List<(String, String)> facts;
  const FactList(this.facts, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      children: [
        for (final f in facts)
          if (f.$2.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(f.$1, style: EsType.small(t)),
                  ),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: EsType.body(t).copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// A list item on a soft tinted background, with a small gap below it.
/// Tappable when [onTap] is set.
class EsPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const EsPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
