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

/// Posts a team for an idea already shared with the society. Pops with a
/// confirmation message once it is sent.
class TeamPostScreen extends StatefulWidget {
  final User student;
  final Idea idea;
  const TeamPostScreen({super.key, required this.student, required this.idea});

  @override
  State<TeamPostScreen> createState() => _TeamPostScreenState();
}

class _TeamPostScreenState extends State<TeamPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _team = TeamDraft(members: widget.idea.teamSize);
  late final _whatsapp = TextEditingController(
    text: widget.idea.whatsapp ?? '',
  );
  bool _submitting = false;

  @override
  void dispose() {
    _team.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final student = widget.student;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(student.uid)
          .get();
      final name = (profile.data()?['name'] ?? '').toString().trim();
      await VenturesService.postTeam(
        student: student,
        ownerName: name.isNotEmpty ? name : (student.displayName ?? ''),
        title: widget.idea.title,
        category: widget.idea.category,
        whatsapp: canonicalPakistaniPhone(_whatsapp.text.trim()),
        draft: _team,
        idea: widget.idea,
      );
      if (mounted) {
        Navigator.pop(
          context,
          'Team posted. It goes on the board once an admin approves it.',
        );
      }
    } catch (_) {
      if (mounted) {
        showFlushbar(
          context,
          'Could not post your team. Check your connection and try again.',
          color: Colors.red.shade900,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EsTokens.of(context);
    final wide = isWideWeb(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Find teammates')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 32 : 16,
              vertical: wide ? 32 : 16,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.idea.title, style: EsType.title(t)),
                      const SizedBox(height: 6),
                      Text(
                        'This goes on the public board. Your problem and '
                        'solution stay private to the society.',
                        style: EsType.body(t).copyWith(color: t.muted),
                      ),
                      const SizedBox(height: 24),
                      TeamFields(draft: _team, decoration: _decoration),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _whatsapp,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PakistaniPhoneFormatter()],
                        decoration: _decoration(
                          'WhatsApp number',
                          hint: '03xx xxx xxxx',
                        ),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digits.isEmpty) {
                            return 'Add a number so students can reach you.';
                          }
                          return digits.length == 11 && digits.startsWith('03')
                              ? null
                              : 'Use an 11-digit number starting with 03.';
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _submitting ? 'Posting…' : 'Post team',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
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
