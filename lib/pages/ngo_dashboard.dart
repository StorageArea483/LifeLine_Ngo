import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:life_line_ngo/pages/critical_alerts.dart';
import 'package:life_line_ngo/pages/manage_rescuers.dart';
import 'package:life_line_ngo/pages/ngo_login.dart';
import 'package:life_line_ngo/pages/show_rescuer_info.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/pages/show_victim_info.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class NgoDashboard extends ConsumerStatefulWidget {
  const NgoDashboard({super.key});

  @override
  ConsumerState<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends ConsumerState<NgoDashboard> {
  FirebaseFirestore? _victimFirestore;
  final FirebaseFirestore _ngoFirestore = FirebaseFirestore.instance;
  StreamSubscription? _requestSubscription;
  late AudioPlayer _audioPlayer;

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
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    if (!mounted) return;

    // Set loading to true at the very beginning of all initialization tasks
    ref.read(ngoDasboardProvider.notifier).setLoading(true);

    try {
      // Run all async initialization tasks concurrently
      await Future.wait([
        _initializeAudio(),
        _initVictimFirebase(),
        _fetchRescuerCount(),
      ]);

      // Set up the listener synchronously after other setups
      if (mounted) {
        _listenToRequestCount();
      }
    } catch (e) {
      if (mounted) {
        pageMessage(
          'An unexpected error occurred, please retry',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoLogin(), context);
      }
    } finally {
      if (mounted) {
        ref.read(ngoDasboardProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setAsset('assets/audio/warning-sound.mp3');
      await _audioPlayer.setLoopMode(LoopMode.all);
    } catch (e) {
      if (mounted) {
        pageMessage(
          'An unexpected error occurred, please retry',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoLogin(), context);
      }
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initVictimFirebase() async {
    try {
      FirebaseApp victimApp;

      try {
        victimApp = Firebase.app('life-line-victim');
      } catch (_) {
        victimApp = await Firebase.initializeApp(
          name: 'life-line-victim',
          options: _victimFirebaseOptions,
        );
      }

      _victimFirestore = FirebaseFirestore.instanceFor(app: victimApp);

      await _fetchVictimCount();
    } catch (e) {
      if (mounted) {
        pageMessage(
          'An unexpected error occurred, Please re-login',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoLogin(), context);
      }
    }
  }

  Future<void> _fetchVictimCount() async {
    if (_victimFirestore == null) return;

    try {
      final snapshot = await _victimFirestore!.collection('users').get();
      if (!mounted) return;
      final victimCount = snapshot.docs.length;
      if (mounted) {
        ref.read(ngoDasboardProvider.notifier).setVictimCount(victimCount);
      }
    } catch (e) {
      rethrow;
    }
  }

  void _listenToRequestCount() {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (ngoDocId == null) return;

      // Cancel existing subscription before reassigning
      _requestSubscription?.cancel();
      _requestSubscription = _ngoFirestore
          .collection('requests')
          .where('ngoId', isEqualTo: ngoDocId)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            final requestCount = snapshot.docs.length;
            if (mounted) {
              ref
                  .read(ngoDasboardProvider.notifier)
                  .setNotificationCount(requestCount);

              // Play or stop audio based on request count
              _handleAudioPlayback(requestCount);
            }
          });
    } catch (e) {
      if (mounted) {
        pageMessage('Audio, failed to start', context, AppColors.error);
        pageNavigation(const NgoLogin(), context);
      }
    }
  }

  Future<void> _fetchRescuerCount() async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (ngoDocId == null) return;

      final snapshot = await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .where('status', isEqualTo: 'pending')
          .get();

      if (!mounted) return;
      final rescuerCount = snapshot.docs.length;

      if (mounted) {
        ref.read(ngoDasboardProvider.notifier).setRescuerCount(rescuerCount);
      }
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Failed to fetch rescuer requests',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _handleAudioPlayback(int requestCount) async {
    try {
      if (requestCount > 0) {
        if (!_audioPlayer.playing) {
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _stopAudio() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
    } catch (e) {
      if (mounted) {
        pageMessage('Failed to stop audio', context, AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      drawer: buildDrawer(context),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
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
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 1,
                        ),
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
            Consumer(
              builder: (context, ref, child) {
                if (!mounted) return const SizedBox.shrink();
                final isLoading = ref.watch(
                  ngoDasboardProvider.select((v) => v.isLoading),
                );
                if (!isLoading) return const SizedBox.shrink();
                return IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryMaroon,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isCompact) {
    final actionButtons = [
      {
        'title': 'Manage Victims',
        'icon': Icons.people_outline,
        'onTap': () {
          pageNavigation(const ShowVictimInfo(), context);
        },
      },
      {
        'title': 'Manage Rescuers',
        'icon': Icons.group,
        'onTap': () {
          pageNavigation(const ShowRescuerInfo(), context);
        },
      },
      {'title': 'Relief Operations', 'icon': Icons.location_on, 'onTap': () {}},
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
    if (!mounted) return const SizedBox.shrink();
    final victimCount = ref.watch(
      ngoDasboardProvider.select((v) => v.victimCount),
    );
    if (!mounted) return const SizedBox.shrink();
    final notificationCount = ref.watch(
      ngoDasboardProvider.select((v) => v.notificationCount),
    );
    if (!mounted) return const SizedBox.shrink();
    final rescuerCount = ref.watch(
      ngoDasboardProvider.select((v) => v.rescuerCount),
    );

    final stats = [
      {
        'title': 'Active Users',
        'value': victimCount.toString(),
        'subtitle': 'Registered Victims',
        'color': Colors.orange,
        'hasNotification': false,
      },
      {
        'title': 'Volunteers',
        'value': rescuerCount.toString(),
        'subtitle': 'Rescuer Requests',
        'color': Colors.purple,
        'hasNotification': true,
        'notificationCount': rescuerCount,
      },
      {
        'title': 'Critical Alerts',
        'value': notificationCount.toString(),
        'subtitle': 'Needs Attention',
        'color': Colors.red,
        'hasNotification': true,
        'notificationCount': notificationCount,
        'onTap': _stopAudio,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'NGO Command Center',
          style: AppText.appHeader.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
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
                      hasNotification:
                          stat['hasNotification'] as bool? ?? false,
                      notificationCount: stat['notificationCount'] as int? ?? 0,
                      onTap: stat['onTap'] as VoidCallback?,
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
                          hasNotification:
                              entry.value['hasNotification'] as bool? ?? false,
                          notificationCount:
                              entry.value['notificationCount'] as int? ?? 0,
                          onTap: entry.value['onTap'] as VoidCallback?,
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
  final bool hasNotification;
  final int notificationCount;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.hasNotification = false,
    this.notificationCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (title == 'Active Users') {
            pageNavigation(const ShowVictimInfo(), context);
          } else if (title == 'Volunteers') {
            pageNavigation(const ManageRescuers(), context);
          } else if (title == 'Critical Alerts') {
            // Stop audio playback
            onTap?.call();
            if (context.mounted) {
              pageNavigation(const CriticalAlerts(), context);
            }
          }
        },
        child: Container(
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
          child: Stack(
            children: [
              Column(
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
              if (hasNotification && notificationCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
