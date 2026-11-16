import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_service.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/pakistani_phone_formatter.dart';
import 'package:lgu_one/utils/web_layout.dart';

/// Form a signed-in student uses to share a startup idea with the society.
/// Pops with `true` once the idea is submitted.
class ShareIdeaScreen extends StatefulWidget {
  final User student;
  const ShareIdeaScreen({super.key, required this.student});

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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.student.uid)
          .get();
      final phone = _whatsapp.text.trim();
      await EsocietyService.instance.submitIdea(
        student: widget.student,
        profile: profile.data() ?? const {},
        title: _title.text.trim(),
        problem: _problem.text.trim(),
        solution: _solution.text.trim(),
        targetCustomers: _customers.text.trim(),
        category: _category,
        stage: _stage,
        teamSize: _teamSize,
        helpNeeded: _help.toList(),
        whatsapp: phone.isEmpty ? null : canonicalPakistaniPhone(phone),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showFlushbar(
          context,
          'Could not share your idea: $e',
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
    final theme = Theme.of(context);
    final wide = isWideWeb(context);

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
    ];

    final details = [
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _decoration('Category'),
        items: kIdeaCategories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _stage,
        decoration: _decoration('Stage'),
        items: kIdeaStages
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _stage = v ?? _stage),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: Text('Team size', style: theme.textTheme.bodyMedium)),
          IconButton.outlined(
            tooltip: 'Fewer',
            onPressed: _teamSize > 1 ? () => setState(() => _teamSize--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$_teamSize',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
      const SizedBox(height: 16),
      Text('What help are you looking for?', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kIdeaHelpOptions
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
      const SizedBox(height: 20),
      TextFormField(
        controller: _whatsapp,
        keyboardType: TextInputType.phone,
        inputFormatters: [PakistaniPhoneFormatter()],
        decoration: _decoration(
          'WhatsApp number (optional)',
          hint: '03xx xxx xxxx',
        ),
        validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.isEmpty) return null;
          return digits.length == 11 && digits.startsWith('03')
              ? null
              : 'Use an 11-digit number starting with 03.';
        },
      ),
      const SizedBox(height: 6),
      Text(
        'The society sees your name, LGU email, degree and semester from your '
        'profile, plus this number if you add it.',
        style: theme.textTheme.bodySmall,
      ),
    ];

    final submit = SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          _submitting ? 'Sharing…' : 'Share idea',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );

    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: EsType.heading(EsTokens.of(context))),
        const SizedBox(height: 14),
        ...children,
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Share an idea')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: wide
              ? WebScrollPage(
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share an idea',
                        style: EsType.title(
                          EsTokens.of(context),
                        ).copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell the Entrepreneurship Society what you want to '
                        'build. Their replies will show up under Your ideas.',
                        style: EsType.body(
                          EsTokens.of(context),
                        ).copyWith(color: EsTokens.of(context).muted),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: section('The idea', about)),
                          const SizedBox(width: 32),
                          Expanded(child: section('Details', details)),
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
                    section('The idea', about),
                    const SizedBox(height: 20),
                    section('Details', details),
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
