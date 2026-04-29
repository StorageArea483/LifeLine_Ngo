import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/pages/show_victim_info.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class NgoDashboard extends ConsumerWidget {
  const NgoDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      drawer: buildDrawer(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            final isCompact = isMobile || isTablet;

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.borderColor, width: 1),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
                  ),
                  child: const NavBar(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActionButtons(context, isCompact),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildStatusSection(isCompact),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isCompact) {
    final actionButtons = [
      {
        'title': 'View Victims',
        'icon': Icons.people_outline,
        'onTap': () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ShowVictimInfo()),
          );
        },
      },
      {'title': 'Relief Operations', 'icon': Icons.location_on, 'onTap': () {}},
      {'title': 'Manage Volunteers', 'icon': Icons.group, 'onTap': () {}},
      {'title': 'Submit Reports', 'icon': Icons.description, 'onTap': () {}},
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actionButtons
            .map(
              (btn) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _ActionCard(
                  title: btn['title'] as String,
                  icon: btn['icon'] as IconData,
                  onTap: btn['onTap'] as VoidCallback,
                ),
              ),
            )
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actionButtons
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                child: _ActionCard(
                  title: entry.value['title'] as String,
                  icon: entry.value['icon'] as IconData,
                  onTap: entry.value['onTap'] as VoidCallback,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatusSection(bool isCompact) {
    final stats = [
      {
        'title': 'Active Ops',
        'value': '8',
        'subtitle': '2 New',
        'color': Colors.orange,
      },
      {
        'title': 'Volunteers',
        'value': '150',
        'subtitle': '+12 On-site',
        'color': Colors.purple,
      },
      {
        'title': 'Critical Alerts',
        'value': '3',
        'subtitle': 'Needs Attention',
        'color': Colors.red,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NGO Command Center',
          style: AppText.appHeader.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Welcome back. Here is the current status of relief operations.',
          style: AppText.formDescription.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isCompact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stats
                .map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _StatCard(
                      title: stat['title'] as String,
                      value: stat['value'] as String,
                      subtitle: stat['subtitle'] as String,
                      color: stat['color'] as Color,
                    ),
                  ),
                )
                .toList(),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stats
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        right: entry.key < stats.length - 1 ? AppSpacing.xl : 0,
                      ),
                      child: SizedBox(
                        width: 280,
                        child: _StatCard(
                          title: entry.value['title'] as String,
                          value: entry.value['value'] as String,
                          subtitle: entry.value['subtitle'] as String,
                          color: entry.value['color'] as Color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// Extracted Widgets

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkCharcoal.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primaryMaroon, size: 24),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.fieldLabel.copyWith(
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: color, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  style: AppText.fieldLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppText.welcomeTitle.copyWith(
              fontSize: 32,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppText.small.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
