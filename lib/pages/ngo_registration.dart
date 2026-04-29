import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/model/ngo_reg_provider.dart';
import 'package:life_line_ngo/pages/ngo_login.dart';
import 'package:life_line_ngo/widgets/store_ngo_info.dart';
import 'package:life_line_ngo/pages/ngo_select_screen.dart';
import 'package:life_line_ngo/services/appwrite_service.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/upload_ngo_info.dart';

class NgoRegistration extends ConsumerStatefulWidget {
  final String ngoName;
  final String ngoLogo;
  const NgoRegistration({
    super.key,
    required this.ngoName,
    required this.ngoLogo,
  });

  @override
  ConsumerState<NgoRegistration> createState() => _NgoRegistrationState();
}

class _NgoRegistrationState extends ConsumerState<NgoRegistration> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController registrationNumberController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController directorNameController = TextEditingController();
  final TextEditingController projectManagerController =
      TextEditingController();
  final TextEditingController geographicalCoverageController =
      TextEditingController();
  final TextEditingController pastExperienceController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();

  // Store document ID for updates
  String? _docId;

  @override
  void dispose() {
    registrationNumberController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    directorNameController.dispose();
    projectManagerController.dispose();
    geographicalCoverageController.dispose();
    pastExperienceController.dispose();
    passwordController.dispose();
    branchNameController.dispose();
    super.dispose();
  }

  void _onProgramChanged(String program) {
    if (mounted) {
      ref.read(ngoRegProvider.notifier).setSelectedProgram(program);
    }
  }

  Future<void> _submitForm() async {
    if (!mounted) return;
    final selectedProgram = ref.read(ngoRegProvider).selectedProgram;
    if (selectedProgram.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one checkbox.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (mounted) {
        ref.read(ngoRegProvider.notifier).setLoading(true);
      }
      try {
        String? documentUrl;
        if (!mounted) return;
        final fileBytes = ref.read(ngoRegProvider).fileBytes;
        if (!mounted) return;
        final fileName = ref.read(ngoRegProvider).fileName;

        // Only upload a new document if user selected a new file
        if (fileBytes != null && fileName != null) {
          final appwriteService = AppwriteService();

          // Check if there's an existing document URL to delete
          if (_docId != null) {
            try {
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('ngo-info-database')
                  .doc(_docId)
                  .get();

              if (docSnapshot.exists) {
                final existingUrl =
                    docSnapshot.data()?['documentUrl'] as String?;

                // If an existing URL exists, delete the old file from Appwrite
                if (existingUrl != null && existingUrl.isNotEmpty) {
                  try {
                    final uri = Uri.parse(existingUrl);
                    final fileId =
                        uri.pathSegments[uri.pathSegments.indexOf('files') + 1];

                    await appwriteService.deleteFile(
                      bucketId: '69f180590004b2f6de27',
                      fileId: fileId,
                    );
                  } catch (deleteError) {
                    // Log error but continue with upload
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'An unexpected error occurred, please retry',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const NgoSelectScreen(),
                        ),
                      );
                    }
                  }
                }
              }
            } catch (firestoreError) {
              // Log error but continue with upload
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('An unexpected error occurred, please retry'),
                    backgroundColor: AppColors.error,
                  ),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const NgoSelectScreen(),
                  ),
                );
              }
            }
          }

          // Upload the new document
          documentUrl = await appwriteService.uploadDocument(
            fileBytes: fileBytes,
            fileName: fileName,
            ngoName: widget.ngoName,
            branchNumber: branchNameController.text.trim(),
          );
        }

        if (!mounted) return;
        final selectedProgram = ref.read(ngoRegProvider).selectedProgram;

        _docId = await addUserDetails(
          docId: _docId,
          ngoName: widget.ngoName,
          ngoLogo: widget.ngoLogo,
          registrationNumber: registrationNumberController.text.trim(),
          address: addressController.text.trim(),
          branchName: branchNameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          directorName: directorNameController.text.trim(),
          projectManager: projectManagerController.text.trim(),
          geographicalCoverage: geographicalCoverageController.text.trim(),
          pastExperience: pastExperienceController.text.trim(),
          selectedProgram: selectedProgram,
          documentUrl: documentUrl,
        );

        if (mounted) {
          ref.read(ngoRegProvider.notifier).setLoading(false);
          if (context.mounted) {
            _showSuccessDialog();
          }
        }
      } catch (e) {
        if (mounted) {
          ref.read(ngoRegProvider.notifier).setLoading(false);
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred, please try again'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isMobileDialog = screenWidth < 600;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobileDialog ? 16 : 40,
            vertical: 24,
          ),
          child: Container(
            width: isMobileDialog ? double.infinity : 350,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: EdgeInsets.all(
              isMobileDialog ? AppSpacing.lg : AppSpacing.xxl,
            ),
            decoration: AppContainers.cardContainer,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: isMobileDialog ? 60 : 80,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Request Submitted Successfully',
                    style: AppText.fieldLabel.copyWith(
                      fontSize: isMobileDialog ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Please wait for some time while we review and check your documents. You can check your status by entering your email address and password that you used in the form. Once you are verified, you will be able to log into the system.',
                    style: isMobileDialog
                        ? AppText.small.copyWith(fontSize: 12)
                        : AppText.small,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (mounted) {
                                // Clear file state to prevent duplicate uploads
                                ref
                                    .read(ngoRegProvider.notifier)
                                    .setFileBytes(null);
                                ref
                                    .read(ngoRegProvider.notifier)
                                    .setFileName(null);
                                ref
                                    .read(ngoRegProvider.notifier)
                                    .setDroppedFile(null);
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryMaroon,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(
                                    AppDecorations.primaryButtonRadius,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Edit Form',
                                style: AppText.submitButton,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const NgoLogin(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.primaryMaroon,
                                  width: 2,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                    AppDecorations.primaryButtonRadius,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: AppText.submitButton.copyWith(
                                  color: AppColors.primaryMaroon,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/rescue_img3.webp',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 700,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.all(
                            isMobile ? AppSpacing.xl : AppSpacing.xxxxl,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Back Button & NGO Info
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (mounted) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NgoSelectScreen(),
                                          ),
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
                                Row(
                                  children: [
                                    Container(
                                      width: isMobile ? 40 : 48,
                                      height: isMobile ? 40 : 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        widget.ngoLogo,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.ngoName,
                                            style: AppText.fieldLabel.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: isMobile ? 15 : 17,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Registration Form',
                                            style: AppText.small.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: isMobile ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  'Please provide the following information for verification.',
                                  style: AppText.formDescription.copyWith(
                                    fontSize: isMobile ? 14 : 15,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 20 : 24),

                                // Registration Number
                                _buildFieldLabel(
                                  'Registration Number / Certificate',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: registrationNumberController,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'e.g., RG123-ABC/45',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Registration Number is required';
                                    }
                                    final allowedCharsRegex = RegExp(
                                      r'^[A-Za-z0-9\-/\\]+$',
                                    );
                                    if (!allowedCharsRegex.hasMatch(
                                      value.trim(),
                                    )) {
                                      return 'Only letters, numbers, hyphens and slashes are allowed';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Address
                                _buildFieldLabel(
                                  'Head Office + Branch Address',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: addressController,
                                  maxLines: 4,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Specify office location',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Address is required';
                                    }
                                    final regExp = RegExp(
                                      r"^[a-zA-Z0-9\s,.\-#/():']{10,200}$",
                                    );
                                    if (!regExp.hasMatch(value.trim())) {
                                      return 'Address format seems invalid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Branch Name
                                _buildFieldLabel('Branch Name'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: branchNameController,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'e.g., Abbottabad Branch',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field cannot be left empty';
                                    }
                                    final regex = RegExp(
                                      r"^[A-Za-z0-9\s,'/]+$",
                                    );
                                    if (!regex.hasMatch(value.trim())) {
                                      return 'Only letters, numbers are allowed';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Phone
                                _buildFieldLabel('Phone Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Phone',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    final regExp = RegExp(
                                      r'^(?:\+92\s?|0)?(?:3\d{2}-?\d{7}|(21|22|42|51|61|71|81|92)-?\d{7})$',
                                    );
                                    if (!regExp.hasMatch(value.trim())) {
                                      return 'Enter a valid Pakistani phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email
                                _buildFieldLabel('Email Address'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Email',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    final regExp = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                                    );
                                    if (!regExp.hasMatch(value.trim())) {
                                      return 'Enter a valid email address';
                                    }
                                    final allowedDomains = ['gmail.com'];
                                    final domain = value
                                        .trim()
                                        .split('@')
                                        .last
                                        .toLowerCase();
                                    if (!allowedDomains.contains(domain)) {
                                      return 'Please check spelling';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password
                                _buildFieldLabel('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Enter your password',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field cannot be left empty';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Director Name
                                _buildFieldLabel('Name of Director / CEO'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: directorNameController,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Name of Director / CEO',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Director / CEO name is required';
                                    }
                                    final regExp = RegExp(
                                      r"^[A-Za-z]+(?:[ .-][A-Za-z]+)*$",
                                    );
                                    if (!regExp.hasMatch(value.trim())) {
                                      return 'Enter a valid name (letters only, no numbers or symbols)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Project Manager
                                _buildFieldLabel('Project Manager or HR'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: projectManagerController,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Project Manager or HR',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Project Manager name is required';
                                    }
                                    final regExp = RegExp(
                                      r"^[A-Za-z]+(?:[ .-][A-Za-z]+)*$",
                                    );
                                    if (!regExp.hasMatch(value.trim())) {
                                      return 'Enter a valid name (letters only, no numbers or symbols)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Programs
                                _buildFieldLabel('Programs / Services Offered'),
                                const SizedBox(height: 8),
                                Consumer(
                                  builder: (context, ref, child) {
                                    if (!mounted) {
                                      return const SizedBox.shrink();
                                    }
                                    final selectedProgram = ref.watch(
                                      ngoRegProvider.select(
                                        (v) => v.selectedProgram,
                                      ),
                                    );
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          value:
                                              selectedProgram == 'Earthquake',
                                          onChanged: (_) =>
                                              _onProgramChanged('Earthquake'),
                                          title: Text(
                                            'Earthquake',
                                            style: AppText.small.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: AppColors.primaryMaroon,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        CheckboxListTile(
                                          value: selectedProgram == 'Floods',
                                          onChanged: (_) =>
                                              _onProgramChanged('Floods'),
                                          title: Text(
                                            'Floods',
                                            style: AppText.small.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: AppColors.primaryMaroon,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        CheckboxListTile(
                                          value: selectedProgram == 'Medical',
                                          onChanged: (_) =>
                                              _onProgramChanged('Medical'),
                                          title: Text(
                                            'Medical',
                                            style: AppText.small.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: AppColors.primaryMaroon,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Geographical Coverage
                                _buildFieldLabel('Geographical Coverage'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: geographicalCoverageController,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'e.g., Abbottabad, KPK',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field cannot be left empty';
                                    }
                                    final regex = RegExp(
                                      r"^[A-Za-z0-9\s,.:\/\-']+$",
                                    );
                                    if (!regex.hasMatch(value)) {
                                      return 'Enter a valid Geographical Coverage (e.g. Abbottabad, KPK)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Past Experience
                                _buildFieldLabel('Past Experience'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: pastExperienceController,
                                  maxLines: 4,
                                  decoration: AppTextFields.textFieldDecoration(
                                    'Describe previous disaster-relief projects with years.',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'This field cannot be left empty';
                                    }
                                    final regex = RegExp(
                                      r"^[A-Za-z0-9.,():\/\-\s']+$",
                                    );
                                    if (!regex.hasMatch(value)) {
                                      return "Only letters, numbers, spaces, and basic punctuation are allowed.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Upload
                                _buildFieldLabel('Proof / Documentation'),
                                const SizedBox(height: 8),
                                UploadNgoFile(
                                  onFileSelected: (bytes, name, mime) {
                                    if (mounted) {
                                      ref
                                          .read(ngoRegProvider.notifier)
                                          .setFileBytes(bytes);
                                      ref
                                          .read(ngoRegProvider.notifier)
                                          .setFileName(name);
                                    }
                                  },
                                ),
                                SizedBox(height: isMobile ? 32 : 40),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isMobile
                                      ? 48
                                      : AppSizes.submitButtonHeight,
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      if (!mounted) {
                                        return const SizedBox.shrink();
                                      }
                                      final isLoading = ref
                                          .watch(ngoRegProvider)
                                          .isLoading;
                                      return ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : _submitForm,
                                        style: AppButtons.submit,
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: AppColors
                                                          .surfaceLight,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Text(
                                                'Submit for Authentication',
                                                style: AppText.submitButton,
                                              ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppText.fieldLabel.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }
}
