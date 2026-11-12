import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gate for features that require an LGU student email
/// (Lost & Found, Student Collaboration).
class LguEmailGate {
  static const String prefsKey = 'lgu_student_email';

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@([A-Za-z0-9\-]+\.)*lgu\.edu\.pk$',
    caseSensitive: false,
  );

  static bool isValid(String email) => _emailRegex.hasMatch(email.trim());

  static Future<String?> savedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(prefsKey);
    return (email != null && isValid(email)) ? email : null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  /// Returns true if the user may enter the feature: either a valid email is
  /// already stored, or the user enters one in the dialog.
  static Future<bool> ensureVerified(BuildContext context) async {
    if (await savedEmail() != null) return true;
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LguEmailDialog(),
    );
    return result ?? false;
  }
}

class _LguEmailDialog extends StatefulWidget {
  const _LguEmailDialog();

  @override
  State<_LguEmailDialog> createState() => _LguEmailDialogState();
}

class _LguEmailDialogState extends State<_LguEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _remember = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_remember) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LguEmailGate.prefsKey, _controller.text.trim());
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LGU Student Email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your LGU student email to continue.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@students.lgu.edu.pk',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email is required';
                if (!LguEmailGate.isValid(value)) {
                  return 'Enter a valid email ending with .lgu.edu.pk';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Remember me'),
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
