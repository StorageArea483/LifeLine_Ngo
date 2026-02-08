import 'package:flutter/material.dart';

void pageTransition(BuildContext context, Widget targetScreenWidget) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) => targetScreenWidget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Animation<Offset> nextPageAnimation = Tween<Offset>(
          begin: Offset(1.0, 0.0),
          end: Offset(0.0, 0.0),
        ).animate(animation);
        return SlideTransition(position: nextPageAnimation, child: child);
      },
      transitionDuration: Duration(milliseconds: 300),
    ),
  );
}
