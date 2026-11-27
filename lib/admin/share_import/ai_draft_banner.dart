import 'package:flutter/material.dart';

/// Shown above a publish form that AI filled from a WhatsApp share.
class AiDraftBanner extends StatelessWidget {
  /// Label for moving the draft to the other section, e.g. "Move to Jobs".
  final String switchLabel;
  final VoidCallback onSwitch;

  const AiDraftBanner({
    super.key,
    required this.switchLabel,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Filled in by AI from WhatsApp. Check it before publishing.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onSwitch, child: Text(switchLabel)),
        ],
      ),
    );
  }
}
