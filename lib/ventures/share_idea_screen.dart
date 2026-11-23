import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/esociety/esociety_models.dart';
import 'package:lgu_one/esociety/esociety_widgets.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/pakistani_phone_formatter.dart';
import 'package:lgu_one/utils/web_layout.dart';
import 'package:lgu_one/ventures/team_fields.dart';
import 'package:lgu_one/ventures/ventures_service.dart';

/// Opens the form for [student] and confirms once it is sent.
Future<void> shareIdea(BuildContext context, User student) async {
  final message = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => ShareIdeaScreen(student: student)),
  );
  if (message != null && context.mounted) {
    await showFlushbar(
      context,
      message,
      color: Colors.green.shade900,
      icon: Icons.check_circle_outline,
    );
  }
}

/// One form: the idea goes on the board, and to the Entrepreneurship
/// Society portal too when the student ticks the box. Pops with a
/// confirmation message once it is sent.
class ShareIdeaScreen extends StatefulWidget {
  final User student;
  const ShareIdeaScreen({super.key, required this.student});

  @override
  State<ShareIdeaScreen> createState() => _ShareIdeaScreenState();
}

class _ShareIdeaScreenState extends State<ShareIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _whatsapp = TextEditingController();
  final _team = TeamDraft();
  String _category = kIdeaCategories.first;
  bool _toSociety = false;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _whatsapp.dispose();
    _team.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final student = widget.student;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(student.uid)
          .get();
      await VenturesService.submit(
        student: student,
        profile: profile.data() ?? const {},
        title: _title.text.trim(),
        category: _category,
        whatsapp: canonicalPakistaniPhone(_whatsapp.text.trim()),
        draft: _team,
        toSociety: _toSociety,
      );
      if (mounted) {
        Navigator.pop(
          context,
          _toSociety
              ? 'Sent to the E-Society. It goes on the board once an admin '
                    'approves it.'
              : 'Posted. It goes on the board once an admin approves it.',
        );
      }
    } catch (e) {
      if (mounted) {
        showFlushbar(
          context,
          writeErrorText(e, action: 'Sending'),
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

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);

    final fields = <Widget>[
      TextFormField(
        controller: _title,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: _decoration(
          'Name of your idea',
          hint: 'e.g. Campus Bites: late-night food delivery',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Give your idea a name.' : null,
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _decoration('Category'),
        items: kIdeaCategories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _category = v ?? _category),
      ),
      const SizedBox(height: 16),
      TeamFields(draft: _team, decoration: _decoration),
      const SizedBox(height: 20),
      TextFormField(
        controller: _whatsapp,
        keyboardType: TextInputType.phone,
        inputFormatters: [PakistaniPhoneFormatter()],
        decoration: _decoration('WhatsApp number', hint: '03xx xxx xxxx'),
        validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (digits.isEmpty) return 'Add a number so people can reach you.';
          return digits.length == 11 && digits.startsWith('03')
              ? null
              : 'Use an 11-digit number starting with 03.';
        },
      ),
      const SizedBox(height: 12),
      Material(
        color: _toSociety ? t.moss.withValues(alpha: 0.08) : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _toSociety ? t.moss : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: _toSociety,
          onChanged: (v) => setState(() => _toSociety = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'Send to the Entrepreneurship Society',
            style: EsType.body(t).copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'They see your idea with your name, LGU email, degree and '
            'number, and send you a meeting time.',
            style: EsType.small(t),
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
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
            _submitting ? 'Sending…' : 'Send',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Share an idea')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideWeb(context) ? 32 : 16,
              vertical: 16,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: fields,
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
