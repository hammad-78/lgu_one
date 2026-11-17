import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/pakistani_phone_formatter.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/team_fields.dart';
import 'package:lgu_one/ventures/ventures_service.dart';

/// One form for a student's venture. They choose what they need: feedback
/// from the Entrepreneurship Society (a private idea), teammates (a public
/// post on the board), or both, linked. Pops with a confirmation message
/// once it is sent.
class ShareIdeaScreen extends StatefulWidget {
  final User student;
  final bool forSociety;
  final bool findTeam;
  const ShareIdeaScreen({
    super.key,
    required this.student,
    this.forSociety = true,
    this.findTeam = false,
  });

  @override
  State<ShareIdeaScreen> createState() => _ShareIdeaScreenState();
}

class _ShareIdeaScreenState extends State<ShareIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _problem = TextEditingController();
  final _solution = TextEditingController();
  final _customers = TextEditingController();
  final _whatsapp = TextEditingController();
  final _team = TeamDraft();
  late bool _society = widget.forSociety;
  late bool _teammates = widget.findTeam;
  String _category = kIdeaCategories.first;
  String _stage = kIdeaStages.first;
  int _teamSize = 1;
  final Set<String> _help = {};
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _problem, _solution, _customers, _whatsapp]) {
      c.dispose();
    }
    _team.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_society && !_teammates) {
      showFlushbar(
        context,
        'Choose society feedback, teammates, or both.',
        color: Colors.red.shade900,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final student = widget.student;
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(student.uid)
          .get();
      final profile = profileDoc.data() ?? const <String, dynamic>{};
      final profileName = (profile['name'] ?? '').toString().trim();
      final ownerName = profileName.isNotEmpty
          ? profileName
          : (student.displayName ?? '');
      final phone = _whatsapp.text.trim();
      final whatsapp = phone.isEmpty ? null : canonicalPakistaniPhone(phone);
      final title = _title.text.trim();

      final String message;
      if (_society) {
        await EsocietyService.instance.submitIdea(
          student: student,
          profile: profile,
          title: title,
          problem: _problem.text.trim(),
          solution: _solution.text.trim(),
          targetCustomers: _customers.text.trim(),
          category: _category,
          stage: _stage,
          teamSize: _teammates ? _team.members : _teamSize,
          helpNeeded: {..._help, if (_teammates) 'Team members'}.toList(),
          whatsapp: whatsapp,
          teamPost: _teammates
              ? VenturesService.postInfo(
                  student: student,
                  ownerName: ownerName,
                  title: title,
                  category: _category,
                  whatsapp: whatsapp!,
                  draft: _team,
                )
              : null,
        );
        message = _teammates
            ? 'Idea shared. Your team goes on the board once an admin '
                  'approves it.'
            : "Idea shared. The society's replies will appear here.";
      } else {
        await VenturesService.postTeam(
          student: student,
          ownerName: ownerName,
          title: title,
          category: _category,
          whatsapp: whatsapp!,
          draft: _team,
        );
        message =
            'Team posted. It goes on the board once an admin approves '
            'it.';
      }
      if (mounted) Navigator.pop(context, message);
    } catch (e) {
      if (mounted) {
        showFlushbar(
          context,
          'Could not send it. Check your connection and try again.',
          color: Colors.red.shade900,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? what : null;

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final theme = Theme.of(context);
    final wide = isWideWeb(context);

    final needs = [
      _NeedOption(
        title: 'Feedback from the E-Society',
        subtitle:
            'Private to you and the society. They reply here, review it and '
            'may meet you.',
        value: _society,
        onChanged: (v) => setState(() => _society = v),
      ),
      const SizedBox(height: 8),
      _NeedOption(
        title: 'Teammates',
        subtitle:
            'A public post on the board so students with the skills you '
            'need can contact you.',
        value: _teammates,
        onChanged: (v) => setState(() => _teammates = v),
      ),
    ];

    final about = [
      TextFormField(
        controller: _title,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: _decoration(
          'Name of your idea',
          hint: 'e.g. Campus Bites: late-night food delivery',
        ),
        validator: (v) => _required(v, 'Give your idea a name.'),
      ),
      if (_society) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _problem,
          minLines: 3,
          maxLines: 6,
          maxLength: 800,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(
            'What problem does it solve?',
            hint: 'Who has this problem and why it matters',
          ),
          validator: (v) => _required(v, 'Describe the problem it solves.'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _solution,
          minLines: 3,
          maxLines: 6,
          maxLength: 800,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(
            'Your solution',
            hint: 'How it works and what makes it different',
          ),
          validator: (v) => _required(v, 'Describe your solution.'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customers,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(
            'Target customers (optional)',
            hint: 'e.g. Hostel students, small shops in Lahore',
          ),
        ),
      ],
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _decoration('Category'),
        items: kIdeaCategories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
    ];

    final details = [
      DropdownButtonFormField<String>(
        initialValue: _stage,
        decoration: _decoration('Stage'),
        items: kIdeaStages
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _stage = v ?? _stage),
      ),
      if (!_teammates) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Team size', style: theme.textTheme.bodyMedium),
            ),
            IconButton.outlined(
              tooltip: 'Fewer',
              onPressed: _teamSize > 1
                  ? () => setState(() => _teamSize--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$_teamSize',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'More',
              onPressed: _teamSize < 20
                  ? () => setState(() => _teamSize++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Text('What help are you looking for?', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kIdeaHelpOptions
            // Picking teammates above covers this one.
            .where((h) => !(_teammates && h == 'Team members'))
            .map(
              (h) => FilterChip(
                label: Text(h),
                selected: _help.contains(h),
                onSelected: (on) =>
                    setState(() => on ? _help.add(h) : _help.remove(h)),
              ),
            )
            .toList(),
      ),
    ];

    final contact = [
      TextFormField(
        controller: _whatsapp,
        keyboardType: TextInputType.phone,
        inputFormatters: [PakistaniPhoneFormatter()],
        decoration: _decoration(
          _teammates ? 'WhatsApp number' : 'WhatsApp number (optional)',
          hint: '03xx xxx xxxx',
        ),
        validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.isEmpty) {
            return _teammates
                ? 'Add a number so students can reach you.'
                : null;
          }
          return digits.length == 11 && digits.startsWith('03')
              ? null
              : 'Use an 11-digit number starting with 03.';
        },
      ),
      const SizedBox(height: 6),
      Text(
        [
          if (_society)
            'The society sees your name, LGU email, degree and semester from '
                'your profile, plus this number if you add it.',
          if (_teammates)
            'Students on the board see your name and this number. Your '
                'problem and solution stay private to the society.',
        ].join(' '),
        style: theme.textTheme.bodySmall,
      ),
    ];

    final label = _society
        ? (_submitting ? 'Sharing…' : 'Share idea')
        : (_submitting ? 'Posting…' : 'Post team');
    final submit = SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _submitting || (!_society && !_teammates) ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.send_rounded),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );

    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: EsType.heading(t)),
        const SizedBox(height: 14),
        ...children,
      ],
    );

    final teamSection = section('Your team', [
      TeamFields(draft: _team, decoration: _decoration),
    ]);
    final screenTitle = _society ? 'Share an idea' : 'Post a team';

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: wide
              ? WebScrollPage(
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        screenTitle,
                        style: EsType.title(t).copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us what you want to build and what you need to '
                        'get it going. It shows up under My ventures.',
                        style: EsType.body(t).copyWith(color: t.muted),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      section('What do you need?', [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: needs[0]),
                            const SizedBox(width: 16),
                            Expanded(child: needs[2]),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: section('The idea', about)),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_society) ...[
                                  section('Details', details),
                                  const SizedBox(height: 28),
                                ],
                                if (_teammates) ...[
                                  teamSection,
                                  const SizedBox(height: 28),
                                ],
                                section('Contact', contact),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 320, child: submit),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    section('What do you need?', needs),
                    const SizedBox(height: 24),
                    section('The idea', about),
                    if (_society) ...[
                      const SizedBox(height: 20),
                      section('Details', details),
                    ],
                    if (_teammates) ...[
                      const SizedBox(height: 24),
                      teamSection,
                    ],
                    const SizedBox(height: 24),
                    section('Contact', contact),
                    const SizedBox(height: 24),
                    submit,
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A checkable card for one thing the student needs.
class _NeedOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NeedOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    return Material(
      color: value ? t.moss.withValues(alpha: 0.08) : t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: value ? t.moss : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EsType.body(
                          t,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: EsType.small(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
