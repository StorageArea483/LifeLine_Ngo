import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/providers/ngo_select_screen_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/pages/ngo_registration.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';

class NgoSelectScreen extends StatefulWidget {
  const NgoSelectScreen({super.key});

  @override
  State<NgoSelectScreen> createState() => _NgoSelectScreenState();
}

class _NgoSelectScreenState extends State<NgoSelectScreen> {
  final List<Map<String, String>> ngoList = [
    {
      'name': 'Alkhidmat Foundation',
      'image': 'assets/Logos/Alkhidmat_Logo.webp',
    },
    {
      'name': 'Saibaan Development Organization',
      'image': 'assets/Logos/Saibaan_Organiztion_Logo.webp',
    },
    {
      'name': 'Rural Development Organization (RDO) Abbottabad',
      'image': 'assets/Logos/Rural_Development_Organization.webp',
    },
    {
      'name': 'Omar Asghar Khan Foundation',
      'image': 'assets/Logos/Omar_Asghar_Foundation_Logo.webp',
    },
    {
      'name': 'Pak Irish Rehabilitation Centre (PIRC)',
      'image': 'assets/Logos/Pak_Irish_Center_Logo.webp',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/rescue_img.webp',
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
                        child: Column(
                          children: [
                            // Main Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.all(
                                isMobile ? AppSpacing.xl : AppSpacing.xxxxl,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (mounted) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NgoAuth(),
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
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Select Your NGO',
                                    style: AppText.formTitle.copyWith(
                                      fontSize: isMobile ? 24 : 32,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Choose the NGO you officially represent.',
                                    style: AppText.formDescription.copyWith(
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  SizedBox(
                                    height: isMobile
                                        ? AppSpacing.xl
                                        : AppSpacing.xxl,
                                  ),

                                  // NGO List
                                  Consumer(
                                    builder: (context, ref, child) {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: ngoList.length,
                                        itemBuilder: (context, index) {
                                          if (!mounted) {
                                            return const SizedBox.shrink();
                                          }
                                          final selectedIndex = ref.watch(
                                            selectedIndexProvider,
                                          );
                                          final ngo = ngoList[index];
                                          final isSelected =
                                              selectedIndex == index;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                if (mounted) {
                                                  ref
                                                          .read(
                                                            selectedIndexProvider
                                                                .notifier,
                                                          )
                                                          .state =
                                                      index;
                                                }
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                            .withOpacity(0.1)
                                                      : AppColors.surfaceLight,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.borderColor,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(
                                                  isMobile
                                                      ? AppSpacing.md
                                                      : AppSpacing.lg,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: isMobile ? 40 : 48,
                                                      height: isMobile
                                                          ? 40
                                                          : 48,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .borderLight,
                                                        ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      child: Image.asset(
                                                        ngo['image']!,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: isMobile
                                                          ? AppSpacing.md
                                                          : AppSpacing.lg,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        ngo['name']!,
                                                        style: AppText
                                                            .fieldLabel
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: isMobile
                                                                  ? 14
                                                                  : 16,
                                                            ),
                                                      ),
                                                    ),
                                                    Consumer(
                                                      builder: (context, ref, child) {
                                                        if (!mounted) {
                                                          return const SizedBox.shrink();
                                                        }
                                                        final selectedIndex =
                                                            ref.watch(
                                                              selectedIndexProvider,
                                                            );
                                                        return Radio<int>(
                                                          value: index,
                                                          groupValue:
                                                              selectedIndex,
                                                          onChanged: (value) {
                                                            if (mounted) {
                                                              ref
                                                                      .read(
                                                                        selectedIndexProvider
                                                                            .notifier,
                                                                      )
                                                                      .state =
                                                                  value!;
                                                            }
                                                          },
                                                          activeColor:
                                                              AppColors.primary,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  SizedBox(
                                    height: isMobile
                                        ? AppSpacing.xl
                                        : AppSpacing.xxl,
                                  ),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isMobile
                                        ? 48
                                        : AppSizes.submitButtonHeight,
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final selectedIndex = ref.watch(
                                          selectedIndexProvider,
                                        );
                                        return ElevatedButton(
                                          onPressed: () {
                                            if (mounted) {
                                              Navigator.of(
                                                context,
                                              ).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) => NgoRegistration(
                                                    ngoName:
                                                        ngoList[selectedIndex]['name'] ??
                                                        '',
                                                    ngoLogo:
                                                        ngoList[selectedIndex]['image'] ??
                                                        '',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: AppButtons.submit,
                                          child: const Text(
                                            'Continue',
                                            style: AppText.submitButton,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
