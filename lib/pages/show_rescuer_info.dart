import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/rescuer_info_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_loading.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class ShowRescuerInfo extends ConsumerStatefulWidget {
  const ShowRescuerInfo({super.key});

  @override
  ConsumerState<ShowRescuerInfo> createState() => _ShowRescuerInfoState();
}

class _ShowRescuerInfoState extends ConsumerState<ShowRescuerInfo> {
  final TextEditingController _searchController = TextEditingController();
  FirebaseFirestore? _rescuerFirestore;

  // life-line-rescuer database credentials
  static const FirebaseOptions _rescuerFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyDs-CoAc_fqrB-3BMl4N7pYSavyNV72zUQ',
    appId: '1:494066243537:android:ffdb36137d6d3cb1a4b2f0',
    messagingSenderId: '494066243537',
    projectId: 'life-line-rescuer-b1f1c',
    storageBucket: 'life-line-rescuer-b1f1c.firebasestorage.app',
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
      _initRescuerFirebase();
    });
  }

  Future<void> _initRescuerFirebase() async {
    if (mounted) {
      ref.read(rescuerPageProvider.notifier).setLoading(true);
    }

    try {
      FirebaseApp rescuerApp;
      try {
        rescuerApp = Firebase.app('life-line-rescuer');
      } catch (_) {
        rescuerApp = await Firebase.initializeApp(
          name: 'life-line-rescuer',
          options: _rescuerFirebaseOptions,
        );
      }
      _rescuerFirestore = FirebaseFirestore.instanceFor(app: rescuerApp);
      await _fetchRescuers();
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error fetching rescuers, please try again',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoDashboard(), context);
      }
    }
  }

  Future<void> _fetchRescuers() async {
    if (_rescuerFirestore == null) return;

    try {
      final snapshot = await _rescuerFirestore!
          .collection('users')
          .where('status', isEqualTo: 'approved')
          .get();

      if (!mounted) return;

      final allRescuers = snapshot.docs.map((doc) => doc.data()).toList();

      final searchTerm = _searchController.text;

      List<Map<String, dynamic>> finalList;

      if (searchTerm.isEmpty) {
        finalList = allRescuers;
      } else {
        finalList = allRescuers.where((rescuer) {
          final firstName = (rescuer['firstName'] ?? '').toString();
          final lastName = (rescuer['lastName'] ?? '').toString();
          final fullName = '$firstName $lastName';
          return fullName.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
      }

      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setRescuers(finalList);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshRescuers() async {
    if (mounted) {
      ref.read(rescuerPageProvider.notifier).setLoading(true);
    }

    try {
      await _fetchRescuers();
    } catch (e) {
      if (mounted) {
        pageMessage('Error refreshing rescuer data', context, AppColors.error);
      }
    } finally {
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _removeUser(String id) async {
    if (_rescuerFirestore == null) return;

    if (mounted) {
      ref.read(rescuerPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _rescuerFirestore!
          .collection('users')
          .where('id', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage('Rescuer removed successfully', context, AppColors.success);
        await _fetchRescuers();
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error removing rescuer, please try again',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _blockUser(String id) async {
    if (_rescuerFirestore == null) return;

    if (mounted) {
      ref.read(rescuerPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _rescuerFirestore!
          .collection('users')
          .where('id', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'blocked': true});
      }

      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage('Rescuer blocked successfully', context, AppColors.success);
        await _fetchRescuers();
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error blocking rescuer, please retry',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _unblockUser(String id) async {
    if (_rescuerFirestore == null) return;

    if (mounted) {
      ref.read(rescuerPageProvider.notifier).setLoading(true);
    }

    try {
      final querySnapshot = await _rescuerFirestore!
          .collection('users')
          .where('id', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'blocked': false});
      }

      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage(
          'Rescuer unblocked successfully',
          context,
          AppColors.success,
        );
        await _fetchRescuers();
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerPageProvider.notifier).setLoading(false);
        pageMessage(
          'Error unblocking rescuer, please retry',
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
                  rescuerPageProvider.select((v) => v.isLoading),
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
                  'Rescuer Management',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and monitor registered Rescuers',
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
                          hintText: 'Enter rescuer name to search...',
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
                        onPressed: refreshRescuers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Search Rescuers',
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
                            hintText: 'Enter rescuer name to search...',
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
                        onPressed: refreshRescuers,
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
                          'Search Rescuers',
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
    final rescuers = ref.watch(rescuerPageProvider.select((v) => v.rescuers));

    if (rescuers.isEmpty) {
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
                'No Rescuers data found',
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
        ? _buildMobileRescuerList(ref)
        : _buildWebRescuerTable();
  }

  Widget _buildWebRescuerTable() {
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
              final rescuers = ref.watch(
                rescuerPageProvider.select((v) => v.rescuers),
              );
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(3),
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
                            'Full Name',
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
                            'Registered With',
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
                            'Branch Name',
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
                              'Remove',
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
                              'Block',
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
                  ...rescuers.asMap().entries.map((entry) {
                    final rescuer = entry.value;
                    final firstName = rescuer['firstName'] ?? '';
                    final lastName = rescuer['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim().isEmpty
                        ? 'N/A'
                        : '$firstName $lastName'.trim();
                    final ngoName = rescuer['ngoName'] ?? 'N/A';
                    final branchName = rescuer['branchName'] ?? 'N/A';
                    final id = rescuer['id'] ?? '';
                    final isBlocked = rescuer['blocked'] ?? false;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: AppColors.softBackground.withValues(alpha: 0.3),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      children: [
                        // Full Name Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              fullName,
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
                        // Registered With (NGO) Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              ngoName,
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
                        // Branch Name Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              branchName,
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
                        // Remove Cell
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
                                  if (id.isNotEmpty) {
                                    _removeUser(id);
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
                        // Block / Unblock Cell
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
                                  if (id.isNotEmpty) {
                                    isBlocked
                                        ? _unblockUser(id)
                                        : _blockUser(id);
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

  Widget _buildMobileRescuerList(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final rescuers = ref.watch(rescuerPageProvider.select((v) => v.rescuers));
    return Column(
      children: rescuers.map((rescuer) => _buildMobileCard(rescuer)).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> rescuer) {
    final firstName = rescuer['firstName'] ?? '';
    final lastName = rescuer['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim().isEmpty
        ? 'N/A'
        : '$firstName $lastName'.trim();
    final ngoName = rescuer['ngoName'] ?? 'N/A';
    final branchName = rescuer['branchName'] ?? 'N/A';
    final id = rescuer['id'] ?? '';
    final isBlocked = rescuer['blocked'] ?? false;

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
              fullName,
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
                _RescuerMobileInfoRow(
                  label: 'NGO',
                  value: ngoName,
                  isBlocked: isBlocked,
                ),
                const SizedBox(height: AppSpacing.md),
                _RescuerMobileInfoRow(
                  label: 'Branch',
                  value: branchName,
                  isBlocked: isBlocked,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _RescuerMobileActionButton(
                        label: 'Remove',
                        color: AppColors.error,
                        onPressed: () {
                          if (id.isNotEmpty) _removeUser(id);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: _RescuerMobileActionButton(
                        label: isBlocked ? 'Unblock' : 'Block',
                        color: isBlocked
                            ? AppColors.success
                            : AppColors.warning,
                        onPressed: () {
                          if (id.isNotEmpty) {
                            isBlocked ? _unblockUser(id) : _blockUser(id);
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

class _RescuerMobileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlocked;

  const _RescuerMobileInfoRow({
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

class _RescuerMobileActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _RescuerMobileActionButton({
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
