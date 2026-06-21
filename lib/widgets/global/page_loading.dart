import 'package:flutter/material.dart';
import 'package:life_line_ngo/styles/styles.dart';

Widget pageLoading(BuildContext context) {
  if(!context.mounted) return const SizedBox.shrink();
  return IgnorePointer(
    child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryMaroon,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),
                );
}