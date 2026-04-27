import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/services/functions/transitions_in_pages.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/features/ngo_dasboard.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';

class NgoAuthentication extends StatefulWidget {
  const NgoAuthentication({super.key});

  @override
  State<NgoAuthentication> createState() => _NgoAuthenticationState();
}

class _NgoAuthenticationState extends State<NgoAuthentication> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Password visibility
  bool obscurePassword = true;

  // Loading state
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final email = emailController.text.trim();
        final password = passwordController.text.trim();

        // Fetch all documents from ngo-info-database
        final snapshot = await FirebaseFirestore.instance
            .collection('ngo-info-database')
            .get();

        bool userFound = false;
        bool isApproved = false;

        // Loop through all documents to find matching email and password
        for (var doc in snapshot.docs) {
          final data = doc.data();

          if (data['email'] == email && data['password'] == password) {
            userFound = true;
            isApproved = data['approved'] ?? false;
            break;
          }
        }

        if (mounted) {
          setState(() => isLoading = false);
        }

        if (!userFound) {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid email or password'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } else if (isApproved) {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Successfully logged in'),
                backgroundColor: AppColors.success,
              ),
            );
            // ignore: use_build_context_synchronously
            pageTransition(context, const NgoDashboard());
          }
        } else {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Your request is being processed, please wait for a moment',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: AppContainers.cardContainer,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => pageTransition(
                                    context,
                                    const LoginSignup(),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              // Card Title
                              Text('Login', style: AppText.formTitle),
                              const SizedBox(height: AppSpacing.md),

                              // Description
                              Text(
                                'Please enter your email and password to login.',
                                style: AppText.formDescription,
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Email Address
                              Text('Email Address', style: AppText.fieldLabel),
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
                              Text('Password', style: AppText.fieldLabel),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration:
                                    AppTextFields.textFieldDecoration(
                                      'Enter your password',
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'This field cannot be left empty';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: AppSizes.submitButtonHeight,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submitLogin,
                                  style: AppButtons.submit,
                                  child: isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.surfaceLight,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Submit',
                                          style: AppText.submitButton,
                                        ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
