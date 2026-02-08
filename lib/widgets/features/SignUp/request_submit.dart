import 'package:flutter/material.dart';
import 'package:life_line_ngo/utils/styles.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';

class RequestSubmit extends StatelessWidget {
  const RequestSubmit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: primaryMaroon,
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF4CAF50),
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
