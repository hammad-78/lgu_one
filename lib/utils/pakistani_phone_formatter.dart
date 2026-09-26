import 'package:flutter/services.dart';

class PakistaniPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(RegExp(r'\D'), '')
        .substring(
          0,
          newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 11),
        );
    final digitsBeforeCursor = newValue.text
        .substring(
          0,
          newValue.selection.extentOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, digits.length);
    final formatted = _formatPhone(digits);
    final cursorOffset = _cursorOffset(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  String _formatPhone(String digits) {
    if (digits.length <= 4) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
  }

  int _cursorOffset(String formatted, int digitCount) {
    if (digitCount == 0) return 0;
    var seen = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (formatted[index] != ' ') seen++;
      if (seen == digitCount) return index + 1;
    }
    return formatted.length;
  }
}

String canonicalPakistaniPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('0') && digits.length == 11
      ? '92${digits.substring(1)}'
      : digits;
}

String displayPakistaniPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final localDigits = digits.startsWith('92') && digits.length == 12
      ? '0${digits.substring(2)}'
      : digits;
  return PakistaniPhoneFormatter()
      .formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: localDigits),
      )
      .text;
}
