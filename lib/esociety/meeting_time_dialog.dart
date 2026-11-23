import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';

/// Picks a meeting time plus one line of text (a place for the society, a
/// note for the student). [clash] explains why a time can't be used, or
/// returns null when it is free. Returns null if cancelled.
Future<(DateTime, String)?> showMeetingTimeDialog(
  BuildContext context, {
  required String title,
  required String textLabel,
  required String confirmLabel,
  DateTime? initial,
  String initialText = '',
  String? Function(DateTime at)? clash,
}) => showDialog<(DateTime, String)>(
  context: context,
  builder: (_) => _MeetingTimeDialog(
    title: title,
    textLabel: textLabel,
    confirmLabel: confirmLabel,
    initial: initial,
    initialText: initialText,
    clash: clash,
  ),
);

class _MeetingTimeDialog extends StatefulWidget {
  final String title;
  final String textLabel;
  final String confirmLabel;
  final DateTime? initial;
  final String initialText;
  final String? Function(DateTime at)? clash;
  const _MeetingTimeDialog({
    required this.title,
    required this.textLabel,
    required this.confirmLabel,
    required this.initial,
    required this.initialText,
    required this.clash,
  });

  @override
  State<_MeetingTimeDialog> createState() => _MeetingTimeDialogState();
}

class _MeetingTimeDialogState extends State<_MeetingTimeDialog> {
  late DateTime? _at =
      widget.initial != null && widget.initial!.isAfter(DateTime.now())
      ? widget.initial
      : null;
  late final _text = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final start = _at ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at ?? DateTime(0, 1, 1, 11)),
    );
    if (time == null) return;
    setState(
      () => _at = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final at = _at;
    final problem = at == null
        ? null
        : at.isBefore(DateTime.now())
        ? 'That time has already passed.'
        : widget.clash?.call(at);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                at == null ? 'Pick date and time' : kMeetingFormat.format(at),
              ),
            ),
            if (problem != null) ...[
              const SizedBox(height: 8),
              Text(problem, style: EsType.small(t).copyWith(color: t.clay)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.textLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: at == null || problem != null
              ? null
              : () => Navigator.pop(context, (at, _text.text.trim())),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
