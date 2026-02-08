import 'package:flutter/material.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';

// Simple, lightweight styles for the LifeLine app.

class AppDecorations {
  static const double cardRadius = 12;
  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(cardRadius),
  );

  static const double textFieldRadius = 10;
  static const BorderRadius textFieldBorderRadius = BorderRadius.all(
    Radius.circular(textFieldRadius),
  );

  static const double submitButtonRadius = 10;
  static const double dialogButtonRadius = 8;
}

class AppText {
  static const TextStyle base = TextStyle(fontFamily: 'SFPro');

  static final TextStyle appHeader = base.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: darkCharcoal,
  );

  static final TextStyle welcomeTitle = base.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: 36,
    color: darkCharcoal,
  );

  static final TextStyle formTitle = base.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: darkCharcoal,
  );

  static final TextStyle formDescription = base.copyWith(
    fontSize: 16,
    color: lightText,
  );

  static final TextStyle fieldLabel = base.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: darkCharcoal,
  );

  static final TextStyle small = base.copyWith(fontSize: 14, color: lightText);

  static final TextStyle link = base.copyWith(
    fontSize: 14,
    color: primaryMaroon,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle submitButton = base.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Colors.white,
  );

  static final TextStyle textFieldHint = base.copyWith(color: lightText);
}

class AppButtons {
  static final ButtonStyle submit = ElevatedButton.styleFrom(
    backgroundColor: primaryMaroon,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDecorations.submitButtonRadius),
    ),
    foregroundColor: Colors.white,
    textStyle: AppText.submitButton,
  );
}

class AppContainers {
  static const BoxDecoration pageContainer = BoxDecoration(
    color: softBackground,
  );

  static const BoxDecoration cardContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: AppDecorations.cardBorderRadius,
  );
}

class AppTextFields {
  static InputDecoration textFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppText.textFieldHint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: primaryMaroon, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double xxxxl = 32;
}

class AppSizes {
  static const double submitButtonHeight = 56;
  static const double primaryIconSize = 26;
}
