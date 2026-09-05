import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rememberedEmailKey = 'remembered_lgu_student_email';

Future<bool> showLguEmailAuthDialog(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  final rememberedEmail = preferences.getString(_rememberedEmailKey);

  if (_isLguEmail(rememberedEmail)) return true;
  if (!context.mounted) return false;

  final emailController = TextEditingController();
  var rememberMe = false;
  var isClosing = false;
  String? errorText;

  final authorizedEmail = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('LGU Student Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your LGU Student email to continue.'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'LGU Student email',
                    hintText: 'student@lgu.edu.pk',
                    errorText: errorText,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: rememberMe,
                  title: const Text('Remember me'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => rememberMe = value ?? false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (isClosing) return;
                  isClosing = true;
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (isClosing) return;
                  final email = emailController.text.trim().toLowerCase();
                  if (!_isLguEmail(email)) {
                    setState(() {
                      errorText = 'Use a valid LGU Student email (e.g., student@lgu.edu.pk)';
                    });
                    return;
                  }

                  if (dialogContext.mounted) {
                    isClosing = true;
                    Navigator.pop(dialogContext, email);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );

  await Future<void>.delayed(kThemeAnimationDuration);
  emailController.dispose();
  if (authorizedEmail == null) return false;

  if (rememberMe) {
    await preferences.setString(_rememberedEmailKey, authorizedEmail);
  }
  return true;
}

bool _isLguEmail(String? email) {
  if (email == null) return false;
  return RegExp(r'lgu\.edu\.pk$', caseSensitive: false)
      .hasMatch(email.trim());
}