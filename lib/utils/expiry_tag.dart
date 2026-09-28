import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryTag extends StatelessWidget {
  final DateTime? expiryDate;

  const ExpiryTag({super.key, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final isExpired =
        expiryDate != null && expiryDate!.isBefore(DateTime.now());
    final color = isExpired ? Colors.red : Colors.orange.shade800;
    final label = expiryDate == null
        ? 'NO EXPIRY'
        : '${isExpired ? 'EXPIRED' : 'EXPIRES'} ${DateFormat('dd MMM yyyy').format(expiryDate!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
