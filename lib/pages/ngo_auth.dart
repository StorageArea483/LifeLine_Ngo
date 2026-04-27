import 'package:flutter/material.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/pages/ngo_login.dart';
import 'package:life_line_ngo/pages/ngo_select_screen.dart';

class NgoAuth extends StatelessWidget {
  const NgoAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            final isDesktop = constraints.maxWidth >= 1024;

            if (isDesktop) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppDecorations.pageLinearGradient,
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _buildCardContent(
                              isMobile: false,
                              isTablet: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right side - Image (matches reference: image flex:5 on right)
                  Expanded(
                    flex: 5,
                    child: Image.asset(
                      'assets/images/rescue_img3.webp',
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),
                ],
              );
            }

            // Mobile and Tablet layout
            return Container(
              decoration: const BoxDecoration(
                gradient: AppDecorations.pageLinearGradient,
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 500 : double.infinity,
                      ),
                      child: _buildCardContent(
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent({required bool isMobile, required bool isTablet}) {
    return Builder(
      builder: (context) => Container(
        decoration: SimpleDecoration.card(),
        padding: const EdgeInsets.all(AppSpacing.xxxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'LifeLine',
              style: AppText.welcomeTitle.copyWith(
                fontSize: isMobile ? 36 : 42,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              'Connecting helpers, restoring hope. Join our network to make a difference in times of crisis.',
              style: AppText.subtitle.copyWith(fontSize: isMobile ? 16 : 18),
            ),
            const SizedBox(height: AppSpacing.xxxxl),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: isMobile ? 48 : AppSizes.submitButtonHeight,
              child: ElevatedButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const NgoSelectScreen(),
                      ),
                    );
                  }
                },
                style: AppButtons.submit,
                child: const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: isMobile ? 48 : AppSizes.submitButtonHeight,
              child: OutlinedButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const NgoLogin()),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDecorations.primaryButtonRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Login',
                  style: AppText.button.copyWith(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Footer text
            const Center(
              child: Text(
                'Already have an account? Use Login to access your dashboard.',
                style: AppText.small,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
