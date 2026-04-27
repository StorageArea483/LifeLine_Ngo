import 'package:flutter/material.dart';
import 'package:life_line_ngo/styles/styles.dart';

class RequestSubmit extends StatelessWidget {
  const RequestSubmit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: AppSizes.primaryIconSize,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('LifeLine', style: AppText.appHeader),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Title
                      Text('Request Submitted', style: AppText.formTitle),
                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      Text(
                        'Your request has been submitted, please wait while we\nreview your documents. We\'ll notify you once there is an\nupdate.',
                        style: AppText.formDescription,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxxxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
