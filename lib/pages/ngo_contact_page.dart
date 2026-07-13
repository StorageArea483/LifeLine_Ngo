import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';

import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/providers/ngo_contact_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/ngo_rescuer_chat.dart';
import 'package:life_line_ngo/widgets/global/page_loading.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';
import 'package:life_line_ngo/widgets/ngo_chat_screen.dart';

class NgoContactPage extends ConsumerStatefulWidget {
  const NgoContactPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NgoContactPageState();
}

class _NgoContactPageState extends ConsumerState<NgoContactPage> {
  FirebaseFirestore? victimFirestore;

  // project-life-line database credentials
  static const FirebaseOptions _victimOptions = FirebaseOptions(
    apiKey: 'AIzaSyByihQ3YBdrJUrAAxFSX3257fUMa0AJ6uo',
    appId: '1:503939690280:android:aff06bb9fb777faf792a1d',
    messagingSenderId: '503939690280',
    projectId: 'project-life-line',
    storageBucket: 'project-life-line.firebasestorage.app',
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  Future<void> _initSecondaryFirebase() async {
    if (mounted) {
      ref.read(victimContactLoadingProvider.notifier).state = true;
    }
    try {
      FirebaseApp victimApp;

      // Victim Firebase
      try {
        victimApp = Firebase.app('project-life-line');
      } catch (_) {
        victimApp = await Firebase.initializeApp(
          name: 'project-life-line',
          options: _victimOptions,
        );
      }

      victimFirestore = FirebaseFirestore.instanceFor(app: victimApp);

      await _fetchAssignedVictims();
      await _fetchAssignedRescuers();

      if (mounted) {
        ref.read(victimContactLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(victimContactLoadingProvider.notifier).state = false;
        pageMessage(
          'An unexpected error occurred. Please try again.',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoDashboard(), context);
      }
    }
  }

  Future<void> _fetchAssignedVictims() async {
    if (victimFirestore == null) return;

    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (ngoDocId == null) return;

      // Fetch the NGO's own doc from the default (life-line-ngo) Firestore
      final ngoDoc = await FirebaseFirestore.instance
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .get();

      if (!ngoDoc.exists) return;

      final assigned = ngoDoc.data()?['assigned'] as Map<String, dynamic>?;
      if (assigned == null || assigned.isEmpty) return;

      final victims = <Map<String, dynamic>>[];

      for (final entry in assigned.entries) {
        final victimId = entry.key;
        final severity = entry.value ?? 'N/A';

        final victimDoc = await victimFirestore!
            .collection('users')
            .doc(victimId)
            .get();

        if (!victimDoc.exists) continue;

        final data = victimDoc.data()!;

        victims.add({
          'id': victimDoc.id,
          'name': data['name'] ?? 'N/A',
          'photoURL': data['photoURL'] ?? '',
          'online': data['online'] ?? false,
          'severity': severity,
        });
      }

      if (mounted) {
        ref.read(assignedVictimsProvider.notifier).state = victims;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchAssignedRescuers() async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (ngoDocId == null) return;

      // Fetch all documents inside the rescuer-requests subcollection
      final rescuerRequestsSnapshot = await FirebaseFirestore.instance
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .get();

      if (rescuerRequestsSnapshot.docs.isEmpty) return;

      final rescuers = <Map<String, dynamic>>[];

      for (final doc in rescuerRequestsSnapshot.docs) {
        final data = doc.data();
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();

        rescuers.add({
          'id': doc.id,
          'fullName': fullName.isEmpty ? 'N/A' : fullName,
          'photoUrl': data['photoUrl'] ?? '',
          'online': data['online'] ?? false,
        });
      }

      if (mounted) {
        ref.read(assignedRescuersProvider.notifier).state = rescuers;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      drawer: buildDrawer(context),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

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
                            _buildHeader(isMobile),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                return _buildBody(ref);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              if (!mounted) return const SizedBox.shrink();
              final isLoading = ref.watch(victimContactLoadingProvider);
              if (!isLoading) return const SizedBox.shrink();
              return pageLoading(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryMaroon.withValues(alpha: 0.05),
            AppColors.accentRose.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon,
              borderRadius: BorderRadius.circular(12),
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    pageNavigation(const NgoDashboard(), context);
                  }
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Victims currently assigned to your organization',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    final victims = ref.watch(assignedVictimsProvider);
    final rescuers = ref.watch(assignedRescuersProvider);

    if (victims.isEmpty && rescuers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No contacts assigned yet',
                style: AppText.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...victims.map((victim) => _buildVictimCard(victim)),
        ...rescuers.map((rescuer) => _buildRescuerCard(rescuer)),
      ],
    );
  }

  Widget _buildVictimCard(Map<String, dynamic> victim) {
    final name = victim['name'] ?? 'N/A';
    final photoURL = victim['photoURL'] ?? '';
    final bool isOnline = victim['online'] ?? false;
    final severity = victim['severity'] ?? 'N/A';
    const avatarSize = 56.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        mouseCursor: SystemMouseCursors.click,
        onTap: () {
          pageNavigation(
            NgoChatScreen(
              victimId: victim['id']!,
              victimName: name,
              photoUrl: photoURL,
            ),
            context,
          );
        },
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.1),
                child: photoURL.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoURL,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: AppColors.primaryMaroon,
                              size: 28,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Icon(
                              Icons.person,
                              color: AppColors.primaryMaroon.withValues(
                                alpha: 0.5,
                              ),
                              size: 28,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.primaryMaroon,
                        size: 28,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: avatarSize * 0.28,
                  height: avatarSize * 0.28,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceLight, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          name,
          style: AppText.fieldLabel.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkCharcoal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '• $severity',
                  style: AppText.small.copyWith(
                    color: AppColors.primaryMaroon,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRescuerCard(Map<String, dynamic> rescuer) {
    final fullName = rescuer['fullName'] ?? 'N/A';
    final photoUrl = rescuer['photoUrl'] ?? '';
    final bool isOnline = rescuer['online'] ?? false;
    const avatarSize = 56.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMaroon.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        mouseCursor: SystemMouseCursors.click,
        onTap: () {
          pageNavigation(
            NgoRescuerChat(
              rescuerId: rescuer['id'] ?? '',
              rescuerName: fullName,
              rescuerPhotoUrl: photoUrl,
            ),
            context,
          );
        },
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppColors.primaryMaroon.withValues(alpha: 0.1),
                child: photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: AppColors.primaryMaroon,
                              size: 28,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Icon(
                              Icons.person,
                              color: AppColors.primaryMaroon.withValues(
                                alpha: 0.5,
                              ),
                              size: 28,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.primaryMaroon,
                        size: 28,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: avatarSize * 0.28,
                  height: avatarSize * 0.28,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceLight, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          fullName,
          style: AppText.fieldLabel.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkCharcoal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isOnline ? 'Online' : 'Offline',
            style: AppText.small.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
