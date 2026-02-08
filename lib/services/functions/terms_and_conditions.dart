import 'package:flutter/material.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';

void showPolicyDialog(BuildContext context, String title, String body) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'SFPro',
          fontWeight: FontWeight.w700,
          color: primaryMaroon,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(
              fontFamily: 'SFPro',
              fontSize: 18,
              color: lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: primaryMaroon, fontFamily: 'SFPro'),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryMaroon,
            side: const BorderSide(color: primaryMaroon, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You agreed to our terms and conditions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
          child: const Text(
            'I Agree',
            style: TextStyle(
              color: primaryMaroon,
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
