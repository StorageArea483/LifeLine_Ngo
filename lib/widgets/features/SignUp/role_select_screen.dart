import 'package:flutter/material.dart';
import 'package:life_line_ngo/services/functions/transitions_in_pages.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/features/SignUp/ngo_registration.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  int? selectedIndex;

  final List<Map<String, String>> ngoList = [
    {
      'name': 'Alkhidmat Foundation',
      'image': 'assets/Logos/Alkhidmat_Logo.png',
    },
    {
      'name': 'Saibaan Development Organization',
      'image': 'assets/Logos/Saibaan_Organiztion_Logo.png',
    },
    {
      'name': 'Rural Development Organization (RDO) Abbottabad',
      'image': 'assets/Logos/Rural_Development_Organization.png',
    },
    {
      'name': 'Omar Asghar Khan Foundation',
      'image': 'assets/Logos/Omar_Asghar_Foundation_Logo.png',
    },
    {
      'name': 'Pak Irish Rehabilitation Centre (PIRC)',
      'image': 'assets/Logos/Pak_Irish_Center_Logo.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 48),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => pageTransition(context, const LoginSignup()),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text('Select Your NGO', style: AppText.formTitle),
                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    'Choose the NGO you officially represent. Only one option can be selected.',
                    style: AppText.formDescription,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // NGO List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ngoList.length,
                    itemBuilder: (context, index) {
                      final ngo = ngoList[index];
                      final isSelected = selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppDecorations.cardRadius,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.borderLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.asset(ngo['image']!),
                              ),
                              const SizedBox(width: AppSpacing.lg),

                              // NGO Name
                              Expanded(
                                child: Text(
                                  ngo['name']!,
                                  style: AppText.fieldLabel.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // Radio button
                              Radio<int>(
                                value: index,
                                // ignore: deprecated_member_use
                                groupValue: selectedIndex,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  setState(() {
                                    selectedIndex = value;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.submitButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Logic will be implemented later
                        if (selectedIndex == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please select your NGO.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } else {
                          pageTransition(
                            context,
                            NgoRegistration(
                              ngoName: ngoList[selectedIndex!]['name'],
                              ngoLogo: ngoList[selectedIndex!]['image'],
                            ),
                          );
                        }
                      },
                      style: AppButtons.submit,
                      child: Text('Continue', style: AppText.submitButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
