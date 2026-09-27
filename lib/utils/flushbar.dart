import "package:another_flushbar/flushbar.dart";
import 'package:flutter/material.dart';

Flushbar flushbar(String message, {Color? color, IconData? icon}) {
  return Flushbar(
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    ),
    duration: const Duration(seconds: 3),
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: color ?? Colors.green.shade900,
    icon: Icon(icon ?? Icons.info_outline, size: 24.0, color: Colors.white),
    margin: const EdgeInsets.all(10.0),
    padding: const EdgeInsets.all(10.0),
    borderRadius: BorderRadius.circular(20.0),
    isDismissible: false,
  );
}

Future<void> showFlushbar(
  BuildContext context,
  String message, {
  Color? color,
  IconData? icon,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  await flushbar(message, color: color, icon: icon).show(context);
}
