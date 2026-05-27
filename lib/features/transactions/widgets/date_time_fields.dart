import 'package:flutter/material.dart';

import 'amount_field.dart';

class DateTimeFields extends StatelessWidget {
  const DateTimeFields({
    super.key,
    required this.dateController,
    required this.timeController,
  });

  final TextEditingController dateController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: dateController,
            decoration: transactionFieldDecoration('Dátum'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: timeController,
            decoration: transactionFieldDecoration('Idő'),
          ),
        ),
      ],
    );
  }
}
