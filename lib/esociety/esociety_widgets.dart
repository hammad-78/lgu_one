import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lgu_one/auth/profile_photo.dart';
import 'package:lgu_one/esociety/esociety_models.dart';

/// Colors for the Entrepreneurship Society screens. One accent (the app's
/// green), text in ink and grey, red only for closing or destructive
/// things. No fills or shadows: structure comes from type and hairlines.
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

  Color statusColor(IdeaStatus s) => switch (s) {
    IdeaStatus.declined || IdeaStatus.withdrawn => clay,
    IdeaStatus.submitted => muted,
    _ => moss,
  };

  Color appointmentColor(AppointmentState s) => switch (s) {
    AppointmentState.confirmed => moss,
    AppointmentState.reschedule => clay,
    AppointmentState.proposed || AppointmentState.cancelled => muted,
  };
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

// ─── Stage track ────────────────────────────────────────────────────────────

/// The path an idea moves along: Submitted, In review, Shortlisted,
/// Accepted. A thin line with small dots; reached stages are green. A
/// declined idea stops in red where it got to; a withdrawn one shows a line
/// of text instead.
class StageTrack extends StatelessWidget {
  final IdeaStatus status;
  final IdeaStatus? closedFrom;

  /// Optional line under each stage (used to explain the path).
  final List<String>? captions;
  const StageTrack({
    super.key,
    required this.status,
    this.closedFrom,
    this.captions,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    if (status == IdeaStatus.withdrawn) {
      return Text('Withdrawn by the student', style: EsType.small(t));
    }

    final declined = status == IdeaStatus.declined;
    final reached = declined
        ? (closedFrom?.trackIndex ?? 0).clamp(0, 3)
        : status.trackIndex;
    const stops = IdeaStatus.track;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stops.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Container(
                        width: i == reached ? 10 : 7,
                        height: i == reached ? 10 : 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i > reached
                              ? t.rule
                              : (declined && i == reached ? t.clay : t.moss),
                        ),
                      ),
                      if (i < stops.length - 1)
                        Expanded(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: i < reached ? t.moss : t.rule,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    declined && i == reached
                        ? IdeaStatus.declined.label
                        : stops[i].label,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: i == reached
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: declined && i == reached
                          ? t.clay
                          : i <= reached
                          ? t.ink
                          : t.muted,
                    ),
                  ),
                ),
                if (captions != null && i < captions!.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: Text(
                      captions![i],
                      style: EsType.small(t).copyWith(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Meetings ───────────────────────────────────────────────────────────────

/// The latest meeting for an idea, as plain type: the day on the left,
/// then time and place, the reply state, any note and [actions].
class MeetingBlock extends StatelessWidget {
  final Idea idea;
  final bool forSociety;
  final List<Widget> actions;

  /// Shown above the time, e.g. the idea title in lists of meetings.
  final String? contextLine;
  final VoidCallback? onTap;
  const MeetingBlock({
    super.key,
    required this.idea,
    required this.forSociety,
    this.actions = const [],
    this.contextLine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final at = idea.appointmentAt!;
    final state = idea.appointmentState ?? AppointmentState.proposed;
    final cancelled = state == AppointmentState.cancelled;
    final past = at.isBefore(DateTime.now());
    final faded = cancelled || past;
    final strong = faded ? t.muted : t.ink;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${at.day}',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: strong,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                DateFormat('MMM').format(at),
                style: EsType.small(t).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contextLine != null)
                Text(
                  contextLine!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsType.small(t),
                ),
              Text(
                [
                  '${DateFormat('EEEE').format(at)}, ${kTimeFormat.format(at)}',
                  if (idea.appointmentPlace.isNotEmpty) idea.appointmentPlace,
                ].join(', '),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: strong,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                past && !cancelled
                    ? 'Took place'
                    : state.label(forSociety: forSociety),
                style: EsType.small(t).copyWith(
                  color: past && !cancelled
                      ? t.muted
                      : t.appointmentColor(state),
                ),
              ),
              if (idea.appointmentNote.isNotEmpty && !faded) ...[
                const SizedBox(height: 6),
                Text(
                  idea.appointmentNote,
                  style: EsType.body(t).copyWith(fontSize: 14),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}

/// Small action under a meeting. [primary] is the one filled button;
/// [danger] is red text; anything else is green text.
class MeetingAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;
  final bool primary;
  const MeetingAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    if (primary) {
      return FilledButton(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    // A tinted background makes the button's edge line up with the text
    // above it, instead of floating on invisible padding.
    final color = danger ? t.clay : t.moss;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// ─── Small pieces ───────────────────────────────────────────────────────────

/// Status as plain colored text.
class StatusText extends StatelessWidget {
  final IdeaStatus status;
  const StatusText(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Text(
      status.label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.statusColor(status),
      ),
    );
  }
}

/// Read-only row of stars.
class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const StarRow(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Semantics(
      label: '$rating out of 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < rating ? t.moss : t.rule,
          ),
        ),
      ),
    );
  }
}

/// Tappable 1–5 star picker.
class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarPicker({super.key, required this.value, required this.onChanged});

  static const _meaning = [
    'Needs a lot of work',
    'Early, with gaps',
    'Promising',
    'Strong',
    'Exceptional',
  ];

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final n = i + 1;
            return IconButton(
              tooltip: '$n of 5',
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(n),
              icon: Icon(
                n <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 30,
                color: n <= value ? t.moss : t.muted,
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            value == 0 ? 'Pick a rating' : _meaning[value - 1],
            style: EsType.small(t),
          ),
        ),
      ],
    );
  }
}

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

/// Small dot for unread activity.
class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Unread',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: EsTokens.of(context).moss,
          shape: BoxShape.circle,
        ),
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
