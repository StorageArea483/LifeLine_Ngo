import 'package:flutter/material.dart';
import 'package:life_line_ngo/services/functions/transitions_in_pages.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/features/Login/ngo_authentication.dart';
import 'package:life_line_ngo/widgets/features/SignUp/role_select_screen.dart';

class NgoAuth extends StatelessWidget {
  const NgoAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxxxl),
                decoration: AppContainers.cardContainer,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LifeLine',
                      style: AppText.welcomeTitle.copyWith(fontSize: 42),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Connecting helpers, restoring hope. Join our network\nto make a difference in times of crisis.',
                      style: AppText.formDescription,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                    SizedBox(
                      width: 300,
                      height: AppSizes.submitButtonHeight,
                      child: ElevatedButton(
                        onPressed: () =>
                            pageTransition(context, const RoleSelectScreen()),
                        style: AppButtons.submit,
                        child: Text('Sign Up', style: AppText.submitButton),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 300,
                      height: AppSizes.submitButtonHeight,
                      child: OutlinedButton(
                        onPressed: () =>
                            pageTransition(context, const NgoAuthentication()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDecorations.primaryButtonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: AppText.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
