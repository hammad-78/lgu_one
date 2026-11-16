import 'package:flutter/material.dart';
import 'package:lgu_one/auth/profile_photo.dart';
import 'package:lgu_one/esociety/esociety_models.dart';

/// Colored pill showing an idea's status.
class IdeaStatusChip extends StatelessWidget {
  final IdeaStatus status;
  final bool dense;
  const IdeaStatusChip(this.status, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Color.lerp(status.color, Colors.white, 0.35)!
        : status.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only row of stars.
class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const StarRow(this.rating, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFFFB300),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i + 1;
        return IconButton(
          tooltip: '$n star${n == 1 ? '' : 's'}',
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(n),
          icon: Icon(
            n <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 32,
            color: const Color(0xFFFFB300),
          ),
        );
      }),
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
    final theme = Theme.of(context);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
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

/// Small green dot for unread activity.
class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// The latest appointment for an idea, with its reply state.
class AppointmentCard extends StatelessWidget {
  final Idea idea;
  final List<Widget> actions;
  const AppointmentCard({
    super.key,
    required this.idea,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = idea.appointmentAt!;
    final state = idea.appointmentState ?? AppointmentState.proposed;
    final cancelled = state == AppointmentState.cancelled;
    final past = at.isBefore(DateTime.now());
    final isDark = theme.brightness == Brightness.dark;
    final stateColor = isDark
        ? Color.lerp(state.color, Colors.white, 0.35)!
        : state.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DateTile(date: at, faded: cancelled || past),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      past && !cancelled ? 'Past appointment' : 'Appointment',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      kAppointmentFormat.format(at),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (idea.appointmentPlace.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                idea.appointmentPlace,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (idea.appointmentNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              idea.appointmentNote,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.circle, size: 9, color: stateColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.label,
                  style: TextStyle(
                    color: stateColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final bool faded;
  const _DateTile({required this.date, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = faded
        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
        : theme.colorScheme.primary;
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Text(
            months[date.month - 1],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled block of text in an idea's details.
class IdeaField extends StatelessWidget {
  final String label;
  final String value;
  const IdeaField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered card used for idea list items and side panels.
class EsocietyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  const EsocietyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(
                alpha: highlighted ? 0.8 : (isDark ? 0.3 : 0.22),
              ),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
