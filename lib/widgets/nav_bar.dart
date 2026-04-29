import 'package:flutter/material.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/pages/ngo_login.dart';
import 'package:life_line_ngo/pages/show_victim_info.dart';
import 'package:life_line_ngo/styles/styles.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_bg_removed.webp',
                    width: 42,
                    height: 42,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Flexible(
                    child: Text(
                      'LifeLine',
                      style: AppText.appHeader,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu
            isMobile || isTablet
                ? Builder(
                    builder: (BuildContext scaffoldContext) {
                      return IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: AppColors.darkCharcoal,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Scaffold.of(scaffoldContext).openDrawer();
                        },
                      );
                    },
                  )
                : Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NgoDashboard(),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Dashboard',
                                style: AppText.base,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ShowVictimInfo(),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'View Victims',
                                style: AppText.base,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              child: const Text('Reports', style: AppText.base),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'SOS Logs',
                                style: AppText.base,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (mounted) {}
                              },
                              child: const Text(
                                'Settings',
                                style: AppText.base,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton(
                              onPressed: () {
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const NgoAuth(),
                                    ),
                                  );
                                }
                              },
                              style: AppButtons.submit,
                              child: Text(
                                'Logout',
                                style: AppText.fieldLabel.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: Container(
      color: AppColors.surfaceLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryMaroon),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/app_bg_removed.webp',
                    width: 32,
                    height: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'LifeLine',
                  style: AppText.appHeader.copyWith(
                    color: AppColors.surfaceLight,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.dashboard,
              color: AppColors.primaryMaroon,
            ),
            title: const Text('Dashboard', style: AppText.fieldLabel),
            onTap: () {
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const NgoDashboard()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.people_outline,
              color: AppColors.primaryMaroon,
            ),
            title: const Text('View Victims', style: AppText.fieldLabel),
            onTap: () {
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ShowVictimInfo(),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.assessment,
              color: AppColors.primaryMaroon,
            ),
            title: const Text('Reports', style: AppText.fieldLabel),
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primaryMaroon),
            title: const Text('SOS Logs', style: AppText.fieldLabel),
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.primaryMaroon),
            title: const Text('Settings', style: AppText.fieldLabel),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const NgoLogin()),
                    );
                  }
                },
                style: AppButtons.submit,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
