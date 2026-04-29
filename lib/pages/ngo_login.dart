import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/model/ngo_login_provider.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';

class NgoLogin extends ConsumerStatefulWidget {
  const NgoLogin({super.key});

  @override
  ConsumerState<NgoLogin> createState() => _NgoLoginState();
}

class _NgoLoginState extends ConsumerState<NgoLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Stream subscriptions
  StreamSubscription? settingsSubscription;
  StreamSubscription? approvedSubscription;

  // Tracked login state
  String? _loggedInEmail;
  String? _loggedInPassword;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    settingsSubscription?.cancel();
    approvedSubscription?.cancel();
    super.dispose();
  }

  void _startLoginSubscriptions(String email, String password) {
    _loggedInEmail = email;
    _loggedInPassword = password;

    // Listen to settings for auto_approved changes
    try {
      settingsSubscription = FirebaseFirestore.instance
          .collection('settings')
          .snapshots()
          .listen((settingsSnapshot) {
            if (!mounted) return;

            bool autoApprovedValue = false;
            if (settingsSnapshot.docs.isNotEmpty) {
              final settingsData = settingsSnapshot.docs.first.data();
              autoApprovedValue = settingsData['auto_approved'] ?? false;
            }

            if (autoApprovedValue) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully logged in'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const NgoDashboard()),
                );
              }
              return;
            }

            // Auto approval is OFF — listen to this NGO's approved field
            approvedSubscription = FirebaseFirestore.instance
                .collection('ngo-info-database')
                .where('email', isEqualTo: _loggedInEmail)
                .where('password', isEqualTo: _loggedInPassword)
                .snapshots()
                .listen((snapshot) {
                  if (!mounted) return;

                  if (snapshot.docs.isEmpty) return;

                  final data = snapshot.docs.first.data();
                  final isApproved = data['approved'] ?? false;

                  if (isApproved) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully logged in'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const NgoDashboard(),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ref.read(ngoLoginProvider.notifier).setLoading(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Your request is being processed, please wait for a moment',
                          ),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  }
                });
          });
    } catch (e) {
      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An unexpected error occurred. Please refresh the page',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(true);
      }

      try {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();

        // First verify credentials exist in Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('ngo-info-database')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          // Credentials not found
          if (context.mounted) {
            ref.read(ngoLoginProvider.notifier).setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid email or password'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } else {
          // Credentials verified — start stream subscriptions
          _startLoginSubscriptions(email, password);
        }
      } catch (e) {
        if (mounted) {
          ref.read(ngoLoginProvider.notifier).setLoading(false);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An unexpected error occurred, please try again later',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
          final isDesktop = constraints.maxWidth >= 1024;

          if (isDesktop) {
            return Row(
              children: [
                // Left side - Card
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

                // Right side - Image
                Expanded(
                  flex: 5,
                  child: Image.asset(
                    'assets/images/rescue_img2.webp',
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
    );
  }

  Widget _buildCardContent({required bool isMobile, required bool isTablet}) {
    return Container(
      decoration: SimpleDecoration.card(),
      padding: const EdgeInsets.all(AppSpacing.xxxxl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NgoAuth()),
                    );
                  }
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Login',
              style: AppText.welcomeTitle.copyWith(
                fontSize: isMobile ? 36 : 42,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              'Please enter your email and password to login.',
              style: AppText.subtitle.copyWith(fontSize: isMobile ? 16 : 18),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Email Address
            const Text('Email Address', style: AppText.fieldLabel),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: AppTextFields.textFieldDecoration(
                'Enter your email address',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field cannot be left empty';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Password
            const Text('Password', style: AppText.fieldLabel),
            const SizedBox(height: AppSpacing.sm),
            Consumer(
              builder: (context, ref, child) {
                if (!mounted) return const SizedBox.shrink();
                final obscurePassword = ref.watch(
                  ngoLoginProvider.select((v) => v.obscurePassword),
                );
                return TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration:
                      AppTextFields.textFieldDecoration(
                        'Enter your password',
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            if (mounted) {
                              ref
                                  .read(ngoLoginProvider.notifier)
                                  .togglePasswordVisibility();
                            }
                          },
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field cannot be left empty';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: isMobile ? 48 : AppSizes.submitButtonHeight,
              child: Consumer(
                builder: (context, ref, child) {
                  if (!mounted) return const SizedBox.shrink();
                  final isLoading = ref.watch(
                    ngoLoginProvider.select((v) => v.isLoading),
                  );
                  return ElevatedButton(
                    onPressed: isLoading ? null : _submitLogin,
                    style: AppButtons.submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.surfaceLight,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Submit', style: AppText.submitButton),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
