import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/victim_info_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_loading.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class ShowVictimInfo extends ConsumerStatefulWidget {
  const ShowVictimInfo({super.key});

  @override
  ConsumerState<ShowVictimInfo> createState() => _ShowVictimInfoState();
}

class _ShowVictimInfoState extends ConsumerState<ShowVictimInfo> {
  final TextEditingController _searchController = TextEditingController();
  FirebaseFirestore? _victimFirestore;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVictimFirebase();
    });
  }

  Future<void> _initVictimFirebase() async {
    if (mounted) {
      ref.read(victimPageProvider.notifier).setLoading(true);
    }

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

      await _fetchVictims();

      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);

        pageMessage(
          'Error fetching victims, please try again',
          context,
          AppColors.error,
        );

        pageNavigation(const NgoDashboard(), context);
      }
    }
  }

  Future<void> _fetchVictims() async {
    if (_victimFirestore == null) return;

    try {
      final snapshot = await _victimFirestore!.collection('users').get();

      if (!mounted) return;

      final allVictims = snapshot.docs.map((doc) => doc.data()).toList();

      final searchTerm = _searchController.text;

      List<Map<String, dynamic>> finalList;

      if (searchTerm.isEmpty) {
        finalList = allVictims;
      } else {
        finalList = allVictims.where((victim) {
          final name = (victim['name'] ?? '').toString();
          return name.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
      }

      if (mounted) {
        ref.read(victimPageProvider.notifier).setVictims(finalList);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshVictims() async {
    if (mounted) {
      ref.read(victimPageProvider.notifier).setLoading(true);
    }

    try {
      await _fetchVictims();
    } catch (e) {
      if (mounted) {
        pageMessage('Error refreshing user data', context, AppColors.error);
      }
    } finally {
      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _removeUser(String email) async {
    if (_victimFirestore == null) return;

    if (mounted) {
      ref.read(victimPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _victimFirestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage('User removed successfully', context, AppColors.success);
        await _fetchVictims(); // Refresh data after removal
      }
    } catch (e) {
      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error removing user, please try again',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _blockUser(String email) async {
    if (_victimFirestore == null) return;

    if (mounted) {
      ref.read(victimPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _victimFirestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'blocked': true});
      }

      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage('User blocked successfully', context, AppColors.success);
        await _fetchVictims(); // Refresh data after blocking
      }
    } catch (e) {
      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error blocking User, please retry',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _unblockUser(String email) async {
    if (_victimFirestore == null) return;

    if (mounted) {
      ref.read(victimPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _victimFirestore!
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'blocked': false});
      }

      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage('User unblocked successfully', context, AppColors.success);
        await _fetchVictims(); // Refresh data after unblocking
      }
    } catch (e) {
      if (mounted) {
        ref.read(victimPageProvider.notifier).setLoading(false);
        pageMessage(
          'Errorblocking User, please retry',
          context,
          AppColors.error,
        );
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
                            _buildSearchBar(isMobile),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                return _buildContent(isMobile, isTablet, ref);
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
            Consumer(
              builder: (context, ref, child) {
                if (!mounted) return const SizedBox.shrink();
                final isLoading = ref.watch(
                  victimPageProvider.select((v) => v.isLoading),
                );
                if (!isLoading) return const SizedBox.shrink();
                return pageLoading(context);
              },
            ),
          ],
        ),
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
                  'User Management',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and monitor registered Users',
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

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.softBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Enter User name to search...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: refreshVictims,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Search Users',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Enter User name to search...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: refreshVictims,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Search Users',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet, WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victims = ref.watch(victimPageProvider.select((v) => v.victims));

    if (victims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No Victims data found',
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

    return isMobile || isTablet
        ? _buildMobileVictimList(ref)
        : _buildWebVictimTable();
  }

  Widget _buildWebVictimTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Content using Table widget
          Consumer(
            builder: (context, ref, child) {
              if (!mounted) return const SizedBox.shrink();
              final victims = ref.watch(
                victimPageProvider.select((v) => v.victims),
              );
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon.withValues(alpha: 0.03),
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'Name',
                            style: AppText.formDescription.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'Contact Information',
                            style: AppText.formDescription.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'Location',
                            style: AppText.formDescription.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: Text(
                              'Remove User',
                              style: AppText.formDescription.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: Text(
                              'Actions',
                              style: AppText.formDescription.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data Rows
                  ...victims.asMap().entries.map((entry) {
                    final victim = entry.value;
                    final name = victim['name'] ?? 'N/A';
                    final email = victim['email'] ?? 'N/A';
                    final String location = victim['location'] ?? 'N/A';
                    final isBlocked = victim['blocked'] ?? false;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: AppColors.softBackground.withValues(alpha: 0.3),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      children: [
                        // Name Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              name,
                              style: AppText.fieldLabel.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: isBlocked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Contact Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              email,
                              style: AppText.fieldLabel.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: isBlocked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Location Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              location.isEmpty ? 'N/A' : location,
                              maxLines: 4,
                              style: AppText.fieldLabel.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: isBlocked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Remove User Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (email != 'N/A') {
                                    _removeUser(email);
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.accentRose,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Actions Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (email != 'N/A') {
                                    isBlocked
                                        ? _unblockUser(email)
                                        : _blockUser(email);
                                  }
                                },
                                icon: isBlocked
                                    ? const Icon(
                                        Icons.block,
                                        color: AppColors.accentRose,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.lock_open,
                                        color: AppColors.accentRose,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileVictimList(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victims = ref.watch(victimPageProvider.select((v) => v.victims));
    return Column(
      children: victims.map((victim) => _buildMobileCard(victim)).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> victim) {
    final name = victim['name'] ?? 'N/A';
    final email = victim['email'] ?? 'N/A';
    final String location = victim['location'] ?? 'N/A';
    final isBlocked = victim['blocked'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header Section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkCharcoal,
                decoration: isBlocked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _MobileInfoRow(
                  label: 'Email',
                  value: email,
                  isBlocked: isBlocked,
                ),
                const SizedBox(height: AppSpacing.md),
                _MobileInfoRow(
                  label: 'Location',
                  value: location.isEmpty ? 'N/A' : location,
                  isBlocked: isBlocked,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _MobileActionButton(
                        label: 'Remove',
                        color: AppColors.error,
                        onPressed: () {
                          if (email != 'N/A') _removeUser(email);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: _MobileActionButton(
                        label: isBlocked ? 'Unblock' : 'Block',
                        color: isBlocked
                            ? AppColors.success
                            : AppColors.warning,
                        onPressed: () {
                          if (email != 'N/A') {
                            isBlocked ? _unblockUser(email) : _blockUser(email);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlocked;

  const _MobileInfoRow({
    required this.label,
    required this.value,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 4,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
              decoration: isBlocked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MobileActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MobileActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
