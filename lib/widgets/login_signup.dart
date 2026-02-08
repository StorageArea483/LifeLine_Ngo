import 'package:flutter/material.dart';
import 'package:life_line_ngo/services/functions/transitions_in_pages.dart';
import 'package:life_line_ngo/utils/styles.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';
import 'package:life_line_ngo/widgets/features/Login/ngo_authentication.dart';
import 'package:life_line_ngo/widgets/features/SignUp/role_select_screen.dart';

class LoginSignup extends StatelessWidget {
  const LoginSignup({super.key});

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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
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
                            pageTransition(context, RoleSelectScreen()),
                        style: AppButtons.submit,
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 300,
                      height: AppSizes.submitButtonHeight,
                      child: OutlinedButton(
                        onPressed: () =>
                            pageTransition(context, NgoAuthentication()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryMaroon,
                          side: const BorderSide(
                            color: primaryMaroon,
                            width: 2,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        child: const Text('Login'),
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
