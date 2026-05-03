import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';
import 'package:life_line_ngo/pages/show_victim_info.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class NgoDashboard extends ConsumerStatefulWidget {
  const NgoDashboard({super.key});

  @override
  ConsumerState<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends ConsumerState<NgoDashboard> {
  FirebaseFirestore? _victimFirestore;
  StreamSubscription? _victimSubscription;

  // life-line-victim database credentials
  static const FirebaseOptions _victimFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyCgdeU_737w9twNR2zt5dzyG5EXK5uKxR0',
    appId: '1:909144850972:web:a9eb7a5cfcec7e437c55d9',
    messagingSenderId: '909144850972',
    projectId: 'life-line-victim-27aaa',
    authDomain: 'life-line-victim-27aaa.firebaseapp.com',
    storageBucket: 'life-line-victim-27aaa.firebasestorage.app',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVictimFirebase();
    });
  }

  @override
  void dispose() {
    _victimSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initVictimFirebase() async {
    if (mounted) {
      ref.read(ngoDasboardProvider.notifier).setLoading(true);
    }
    try {
      final secondaryApp = await Firebase.initializeApp(
        name: 'life-line-victim',
        options: _victimFirebaseOptions,
      );
      _victimFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);
      _listenToVictimCount();
      if (mounted) {
        ref.read(ngoDasboardProvider.notifier).setLoading(false);
      }
    } catch (e) {
      // If already initialized, get the existing instance
      try {
        final existingApp = Firebase.app('life-line-victim');
        _victimFirestore = FirebaseFirestore.instanceFor(app: existingApp);
        _listenToVictimCount();
        if (mounted) {
          ref.read(ngoDasboardProvider.notifier).setLoading(false);
        }
      } catch (e) {
        if (mounted) {
          ref.read(ngoDasboardProvider.notifier).setLoading(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred, Please re-login'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const NgoAuth()),
          );
        }
      }
    }
  }

  void _listenToVictimCount() {
    if (_victimFirestore == null) return;

    try {
      // Cancel existing subscription before reassigning
      _victimSubscription?.cancel();
      _victimSubscription = _victimFirestore!
          .collection('users')
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            final victimCount = snapshot.docs.length;
            if (mounted) {
              ref
                  .read(ngoDasboardProvider.notifier)
                  .setVictimCount(victimCount);
            }
          });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final victimCount = ref.watch(
      ngoDasboardProvider.select((v) => v.victimCount),
    );

    final stats = [
      {
        'title': 'Active Users',
        'value': victimCount.toString(),
        'subtitle': 'Registered Victims',
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
