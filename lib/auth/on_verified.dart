import 'package:flutter/material.dart';

class LguVerifiedTap extends StatelessWidget {
  final Widget child;
  final VoidCallback onVerified;

  const LguVerifiedTap({
    super.key,
    required this.child,
    required this.onVerified,
  });

  static final RegExp _lguRegex = RegExp(
    r'^[a-z]{2}\d{2}-[a-z]+-\d+@[a-z]+\.lgu\.edu\.pk$',
  );

  // ✅ Static method — call this directly from any onTap without wrapping
  static Future<void> verify(
      BuildContext context, {
        required VoidCallback onVerified,
      }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50);
    final dialogBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = highlight.withValues(alpha: isDark ? 0.4 : 0.5);

    final emailController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: highlight.withValues(alpha: 0.35)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlight.withValues(alpha: isDark ? 0.15 : 0.1),
                  ),
                  child: Icon(Icons.school_outlined, color: highlight, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'LGU Verification',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This section is only for LGU students. Please enter your university email to continue.',
                  style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'LGU Email',
                    hintText: 'ab00-abc-000@cs.lgu.edu.pk',
                    prefixIcon: Icon(Icons.email_outlined, color: highlight, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    errorText: errorText,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: highlight, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white60 : Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlight,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  final email = emailController.text.trim().toLowerCase();
                  if (email.isEmpty) {
                    setDialogState(() => errorText = 'Please enter your LGU email.');
                    return;
                  }
                  if (!_lguRegex.hasMatch(email)) {
                    setDialogState(() => errorText = 'Not a valid LGU email address.');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Verify'),
              ),
            ],
          );
        },
      ),
    ).then((verified) {
      if (verified == true) onVerified();
    });
  }

  // Widget wrapper — still useful for elements that don't have their own
  // gesture handler (plain Containers, images, custom painted widgets, etc.)
  Future<void> _showVerificationDialog(BuildContext context) =>
      verify(context, onVerified: onVerified);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showVerificationDialog(context),
      child: child,
    );
  }
}