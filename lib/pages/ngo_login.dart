import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/providers/ngo_login_provider.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';

class NgoLogin extends ConsumerStatefulWidget {
  const NgoLogin({super.key});

  @override
  ConsumerState<NgoLogin> createState() => _NgoLoginState();
}

class _NgoLoginState extends ConsumerState<NgoLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Firestore instances
  FirebaseFirestore? _adminFirestore;
  final FirebaseFirestore _ngoFirestore = FirebaseFirestore.instance;

  // life-line-admin project credentials
  static const FirebaseOptions _adminFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyCEoP-ISJx1dn1EM7Pt3ikEXlSCkmcpMLY',
    appId: '1:135703361476:web:3a4d9e2ec37c8e3d125691',
    messagingSenderId: '135703361476',
    projectId: 'life-line-admin',
    authDomain: 'life-line-admin.firebaseapp.com',
    storageBucket: 'life-line-admin.firebasestorage.app',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initSecondaryFirebase() async {
    if (mounted) {
      ref.read(ngoLoginProvider.notifier).setLoading(true);
    }

    try {
      FirebaseApp adminApp;

      try {
        adminApp = Firebase.app('life-line-admin');
      } catch (_) {
        adminApp = await Firebase.initializeApp(
          name: 'life-line-admin',
          options: _adminFirebaseOptions,
        );
      }

      _adminFirestore = FirebaseFirestore.instanceFor(app: adminApp);

      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);

        pageMessage(
          'An unexpected error occurred, please try again',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _checkLoginApproval(String email, String password) async {
    if (_adminFirestore == null) {
      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        pageMessage(
          'An unexpected error occurred. Please try again.',
          context,
          AppColors.error,
        );
      }
      return;
    }

    try {
      // Check settings from life-line-admin for auto_approved value
      final settingsSnapshot = await _adminFirestore!
          .collection('settings')
          .limit(1)
          .get();

      if (!mounted) return;

      bool autoApprovedValue = false;
      if (settingsSnapshot.docs.isNotEmpty) {
        final settingsData = settingsSnapshot.docs.first.data();
        autoApprovedValue = settingsData['auto approved'] ?? false;
      }

      if (autoApprovedValue && mounted) {
        // Auto approval is ON — login directly
        final idExtracted = await _storeNgoDocId(email, password);
        if (!mounted) return;
        ref.read(ngoLoginProvider.notifier).setLoading(false);

        if (idExtracted) {
          pageNavigation(const NgoDashboard(), context);
        }
      }

      // Auto approval is OFF — check this NGO's approved field in life-line-ngo
      final snapshot = await _ngoFirestore
          .collection('ngo-info-database')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty && mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        pageMessage('Invalid email or password', context, AppColors.error);
        return;
      }

      final data = snapshot.docs.first.data();
      final isBlocked = data['blocked'] ?? false;
      final isApproved = data['approved'] ?? false;

      if (isBlocked && mounted) {
        // NGO is blocked — show message
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        pageMessage(
          'Your account has been blocked. Please contact support for guidance.',
          context,
          AppColors.error,
        );
        return;
      }

      if (isApproved && mounted) {
        // NGO is approved — proceed with login
        final idExtracted = await _storeNgoDocId(email, password);
        if (!mounted) return;
        ref.read(ngoLoginProvider.notifier).setLoading(false);

        if (idExtracted) {
          pageNavigation(const NgoDashboard(), context);
        } else {
          pageMessage(
            'An unexpected error occurred, please retry',
            context,
            AppColors.error,
          );
        }
      } else {
        // NGO is not approved yet
        if (!mounted) return;
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        pageMessage(
          'Your request is being processed, please wait for approval',
          context,
          AppColors.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(ngoLoginProvider.notifier).setLoading(false);
        rethrow;
      }
    }
  }

  Future<bool> _storeNgoDocId(String email, String password) async {
    try {
      final snapshot = await _ngoFirestore
          .collection('ngo-info-database')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final ngoDocId = snapshot.docs.first.id;
        ref.read(ngoDasboardProvider.notifier).setNgoDocId(ngoDocId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
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

        // First verify credentials exist in life-line-ngo Firestore
        final snapshot = await _ngoFirestore
            .collection('ngo-info-database')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          // Credentials not found
          if (context.mounted) {
            ref.read(ngoLoginProvider.notifier).setLoading(false);
            pageMessage('Invalid email or password', context, AppColors.error);
          }
        } else {
          // Credentials verified — check login approval
          _checkLoginApproval(email, password);
        }
      } catch (e) {
        if (mounted) {
          ref.read(ngoLoginProvider.notifier).setLoading(false);
        }
        if (context.mounted) {
          pageMessage(
            'An unexpected error occurred, please try again later',
            context,
            AppColors.error,
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
                  pageNavigation(const NgoAuth(), context);
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
