import 'package:flutter/material.dart';

/// Shows a dialog asking the user to enter the secret code for a listing.
/// Returns the trimmed code the user typed, or null if they cancelled.
///
/// Callers are responsible for verifying the code (via
/// [LostFoundService.verifySecretKey]) and re-showing this with an
/// [errorText] if it didn't match.
Future<String?> promptForSecretKey(
    BuildContext context, {
      required String title,
      String? errorText,
    }) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: 'Secret code',
          hintText: 'e.g. K7F2QXTM',
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}