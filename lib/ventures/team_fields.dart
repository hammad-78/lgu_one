import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';

/// Roles students most often look for. Anything else can be typed in.
const List<String> kTeamRoles = [
  'App developer',
  'Web developer',
  'Backend developer',
  'UI/UX designer',
  'Graphic designer',
  'Marketing',
  'Content writer',
  'Video editor',
  'Business / finance',
  'Sales',
];

/// What a team post says, being filled in.
class TeamDraft {
  final TextEditingController pitch;
  final List<String> roles;
  int members;
  int target;

  TeamDraft({String pitch = '', int members = 1})
    : pitch = TextEditingController(text: pitch),
      roles = [],
      members = members.clamp(1, 20),
      target = (members + 2).clamp(2, 20);

  void dispose() => pitch.dispose();
}

/// The team half of a form: a public pitch, the roles needed and the team
/// size now and wanted. Must sit inside a [Form] so the pitch validates.
class TeamFields extends StatefulWidget {
  final TeamDraft draft;
  final InputDecoration Function(String label, {String? hint}) decoration;
  const TeamFields({super.key, required this.draft, required this.decoration});

  @override
  State<TeamFields> createState() => _TeamFieldsState();
}

class _TeamFieldsState extends State<TeamFields> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _addCustom() {
    final role = _custom.text.trim();
    if (role.isEmpty) return;
    final d = widget.draft;
    if (!d.roles.any((r) => r.toLowerCase() == role.toLowerCase())) {
      setState(() => d.roles.add(role));
    }
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final d = widget.draft;
    final custom = d.roles.where((r) => !kTeamRoles.contains(r)).toList();
    return FormField<List<String>>(
      validator: (_) =>
          d.roles.isEmpty ? 'Pick at least one role you need.' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: d.pitch,
            minLines: 2,
            maxLines: 5,
            maxLength: 400,
            textCapitalization: TextCapitalization.sentences,
            decoration: widget.decoration(
              'Pitch for the board',
              hint: 'What you are building and who you want to join',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Write a short pitch so students know what it is.'
                : null,
          ),
          Text(
            'Everyone on the board sees this, your name, the roles and your '
            'WhatsApp number.',
            style: EsType.small(t),
          ),
          const SizedBox(height: 18),
          Text('Who do you need?', style: EsType.body(t)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in [...kTeamRoles, ...custom])
                FilterChip(
                  label: Text(r),
                  selected: d.roles.contains(r),
                  onSelected: (on) {
                    setState(() => on ? d.roles.add(r) : d.roles.remove(r));
                    field.didChange(d.roles);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) {
                    _addCustom();
                    field.didChange(d.roles);
                  },
                  decoration: widget
                      .decoration('Another role')
                      .copyWith(counterText: '', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  _addCustom();
                  field.didChange(d.roles);
                },
                child: const Text('Add'),
              ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 18),
          _Stepper(
            label: 'People on the team now',
            value: d.members,
            min: 1,
            max: 20,
            onChanged: (v) => setState(() {
              d.members = v;
              if (d.target <= v) d.target = (v + 1).clamp(2, 20);
            }),
          ),
          const SizedBox(height: 8),
          _Stepper(
            label: 'Team size you want',
            value: d.target,
            min: (d.members + 1).clamp(2, 20),
            max: 20,
            onChanged: (v) => setState(() => d.target = v),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: EsType.body(t))),
        IconButton.outlined(
          tooltip: 'Fewer',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.outlined(
          tooltip: 'More',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
