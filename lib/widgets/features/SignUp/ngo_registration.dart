import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:life_line_ngo/services/functions/transitions_in_pages.dart';
import 'package:life_line_ngo/widgets/features/Login/ngo_authentication.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:life_line_ngo/model/store_info_db.dart';
import 'package:life_line_ngo/utils/styles.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';
import 'package:life_line_ngo/widgets/features/SignUp/upload_ngo_file.dart';

class NgoRegistration extends StatefulWidget {
  final String? ngoName;
  final String? ngoLogo;
  const NgoRegistration({super.key, this.ngoName, this.ngoLogo});

  @override
  State<NgoRegistration> createState() => _NgoRegistrationState();
}

class _NgoRegistrationState extends State<NgoRegistration> {
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

  // Selected program (only one can be selected)
  String? selectedProgram;
  bool? programSelection;

  // Loading state
  bool isLoading = false;

  // File data for upload
  Uint8List? fileBytes;
  String? fileName;
  String? fileMimeType;

  // Store document ID for updates
  String? _docId;

  // Store uploaded file path for deletion
  String? _uploadedFilePath;

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
    setState(() {
      selectedProgram = selectedProgram == program ? null : program;
      programSelection = true;
    });
  }

  Future<void> _submitForm() async {
    if (programSelection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one checkbox.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fileBytes == null || fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a document in order to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String? documentUrl;

        // Upload file to Supabase if selected
        if (fileBytes != null && fileName != null) {
          // Check if file is different from previously uploaded file
          final sanitizedName = fileName!
              .replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '_')
              .toLowerCase();

          // Create folder path using NGO name and branch name
          final ngoFolderName =
              widget.ngoName
                  ?.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
                  .toLowerCase() ??
              'unknown_ngo';

          final branchFolderName = branchNameController.text
              .trim()
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
              .toLowerCase();

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final uploadFileName =
              '$ngoFolderName/$branchFolderName/${timestamp}_$sanitizedName';

          // Only upload if file is different
          if (_uploadedFilePath != uploadFileName) {
            try {
              final supabase = Supabase.instance.client;

              // Delete old file if exists
              if (_uploadedFilePath != null) {
                try {
                  await supabase.storage.from('ngo-documents').remove([
                    _uploadedFilePath!,
                  ]);
                } catch (e) {
                  // Ignore delete errors
                }
              }

              // Upload new file
              await supabase.storage
                  .from('ngo-documents')
                  .uploadBinary(
                    uploadFileName,
                    fileBytes!,
                    fileOptions: FileOptions(contentType: fileMimeType),
                  );

              documentUrl = supabase.storage
                  .from('ngo-documents')
                  .getPublicUrl(uploadFileName);

              _uploadedFilePath = uploadFileName;
            } catch (e) {
              if (mounted) {
                setState(() => isLoading = false);
              }
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File upload failed: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          } else {
            // Use existing file URL
            final supabase = Supabase.instance.client;
            documentUrl = supabase.storage
                .from('ngo-documents')
                .getPublicUrl(_uploadedFilePath!);
          }
        }

        // Save to Firestore (update if docId exists, create if not)
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
          setState(() => isLoading = false);
          if (context.mounted) {
            _showSuccessDialog();
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
              backgroundColor: Colors.red,
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
            width: isMobileDialog ? double.infinity : 500,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: EdgeInsets.all(
              isMobileDialog ? AppSpacing.lg : AppSpacing.xxl,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
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
                  if (isMobileDialog)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: primaryMaroon,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Edit Form',
                                  style: TextStyle(color: Colors.white),
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
                                Navigator.of(dialogContext).pop();
                                pageTransition(context, NgoAuthentication());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: primaryMaroon,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Login Page',
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: primaryMaroon,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Edit Form',
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                pageTransition(context, NgoAuthentication());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: primaryMaroon,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Login Page',
                                  style: TextStyle(color: Colors.white),
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
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile
                            ? double.infinity
                            : (isTablet ? 700 : 600),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo Header
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: primaryMaroon,
                                    size: isMobile
                                        ? 20
                                        : AppSizes.primaryIconSize,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'LifeLine',
                                    style: isMobile
                                        ? AppText.appHeader.copyWith(
                                            fontSize: 16,
                                          )
                                        : AppText.appHeader,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),

                            // NGO Info Row
                            if (isMobile)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentRose.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: widget.ngoLogo != null
                                        ? Image.asset(widget.ngoLogo!)
                                        : const SizedBox(),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    widget.ngoName ?? '',
                                    style: AppText.fieldLabel.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentRose.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: widget.ngoLogo != null
                                        ? Image.asset(widget.ngoLogo!)
                                        : const SizedBox(),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Text(
                                      widget.ngoName ?? '',
                                      style: AppText.fieldLabel.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.md),

                            Text(
                              'Please provide the following information for verification.',
                              style: isMobile
                                  ? AppText.formDescription.copyWith(
                                      fontSize: 14,
                                    )
                                  : AppText.formDescription,
                              textAlign: isMobile
                                  ? TextAlign.center
                                  : TextAlign.start,
                            ),
                            SizedBox(
                              height: isMobile
                                  ? AppSpacing.xl
                                  : AppSpacing.xxxl,
                            ),

                            // Registration Number
                            Text(
                              'Registration Number / Certificate',
                              style: AppText.fieldLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                                if (!allowedCharsRegex.hasMatch(value.trim())) {
                                  return 'Only letters, numbers, hyphens and slashes are allowed';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Address
                            Text(
                              'Head Office Address + Local Branch Address',
                              style: AppText.fieldLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: addressController,
                              maxLines: 4,
                              decoration: AppTextFields.textFieldDecoration(
                                'Please specify if it\'s the Abbottabad office or a regional office.',
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
                            const SizedBox(height: AppSpacing.xl),

                            // Branch Name
                            Text('Branch Name', style: AppText.fieldLabel),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: branchNameController,
                              decoration: AppTextFields.textFieldDecoration(
                                'e.g., Abbottabad Branch',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'This field cannot be left empty';
                                }
                                final regex = RegExp(r"^[A-Za-z0-9\s,'/]+$");
                                if (!regex.hasMatch(value.trim())) {
                                  return 'Only letters, numbers are allowed';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Contact Details
                            Text('Contact Details', style: AppText.fieldLabel),
                            const SizedBox(height: AppSpacing.sm),
                            if (isMobile) ...[
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
                              const SizedBox(height: AppSpacing.md),
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
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration:
                                          AppTextFields.textFieldDecoration(
                                            'Phone',
                                          ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
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
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration:
                                          AppTextFields.textFieldDecoration(
                                            'Email',
                                          ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
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
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.xl),

                            // Password
                            Text('Password', style: AppText.fieldLabel),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.xl),

                            // Key Personnel
                            Text('Key Personnel', style: AppText.fieldLabel),
                            const SizedBox(height: AppSpacing.sm),
                            if (isMobile) ...[
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
                              const SizedBox(height: AppSpacing.md),
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
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: directorNameController,
                                      decoration:
                                          AppTextFields.textFieldDecoration(
                                            'Name of Director / CEO',
                                          ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
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
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TextFormField(
                                      controller: projectManagerController,
                                      decoration:
                                          AppTextFields.textFieldDecoration(
                                            'Project Manager or HR',
                                          ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
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
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.xl),

                            // Programs
                            Text(
                              'Programs / Services Offered',
                              style: AppText.fieldLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (isMobile)
                              Column(
                                children: [
                                  CheckboxListTile(
                                    value: selectedProgram == 'Earthquake',
                                    onChanged: (_) =>
                                        _onProgramChanged('Earthquake'),
                                    title: Text(
                                      'Earthquake',
                                      style: AppText.small.copyWith(
                                        color: darkCharcoal,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: primaryMaroon,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  CheckboxListTile(
                                    value: selectedProgram == 'Floods',
                                    onChanged: (_) =>
                                        _onProgramChanged('Floods'),
                                    title: Text(
                                      'Floods',
                                      style: AppText.small.copyWith(
                                        color: darkCharcoal,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: primaryMaroon,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  CheckboxListTile(
                                    value: selectedProgram == 'Health',
                                    onChanged: (_) =>
                                        _onProgramChanged('Health'),
                                    title: Text(
                                      'Health',
                                      style: AppText.small.copyWith(
                                        color: darkCharcoal,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: primaryMaroon,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: CheckboxListTile(
                                      value: selectedProgram == 'Earthquake',
                                      onChanged: (_) =>
                                          _onProgramChanged('Earthquake'),
                                      title: Text(
                                        'Earthquake',
                                        style: AppText.small.copyWith(
                                          color: darkCharcoal,
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: primaryMaroon,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: CheckboxListTile(
                                      value: selectedProgram == 'Floods',
                                      onChanged: (_) =>
                                          _onProgramChanged('Floods'),
                                      title: Text(
                                        'Floods',
                                        style: AppText.small.copyWith(
                                          color: darkCharcoal,
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: primaryMaroon,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: CheckboxListTile(
                                      value: selectedProgram == 'Health',
                                      onChanged: (_) =>
                                          _onProgramChanged('Health'),
                                      title: Text(
                                        'Health',
                                        style: AppText.small.copyWith(
                                          color: darkCharcoal,
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: primaryMaroon,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.md),

                            // Geographical Coverage
                            Text(
                              'Geographical Coverage',
                              style: AppText.fieldLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.xl),

                            // Past Experience
                            Text('Past Experience', style: AppText.fieldLabel),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.xl),

                            // Upload
                            Text(
                              'Proof / Documentation',
                              style: AppText.fieldLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            UploadNgoFile(
                              onFileSelected: (bytes, name, mime) {
                                fileBytes = bytes;
                                fileName = name;
                                fileMimeType = mime;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxxl),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: AppSizes.submitButtonHeight,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: AppButtons.submit,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('Submit for Authentication'),
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
      ),
    );
  }
}
