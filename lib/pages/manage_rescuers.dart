import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/manage_rescuers_provider.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_loading.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class ManageRescuers extends ConsumerStatefulWidget {
  const ManageRescuers({super.key});

  @override
  ConsumerState<ManageRescuers> createState() => _ManageRescuersState();
}

class _ManageRescuersState extends ConsumerState<ManageRescuers> {
  final FirebaseFirestore _ngoFirestore = FirebaseFirestore.instance;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRescuerFirebase();
    });
  }

  Future<void> _initRescuerFirebase() async {
    if (mounted) {
      ref.read(manageRescuersProvider.notifier).setLoading(true);
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

      await _fetchRescuerRequests();

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);

        pageMessage(
          'Failed to initialize rescuer database, Please try again later',
          context,
          AppColors.error,
        );

        pageNavigation(const NgoDashboard(), context);
      }
    }
  }

  Future<void> _fetchRescuerRequests() async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;

      if (ngoDocId == null) {
        if (mounted) {
          pageMessage(
            'Unable to fetch rescuer requests, Please try again.',
            context,
            AppColors.error,
          );
        }
        return;
      }

      final snapshot = await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .get();

      if (!mounted) return;

      final requests = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Only include requests with status == 'pending'
        if (data['status'] == 'pending') {
          requests.add({
            'id': doc.id,
            'firstName': data['firstName'] ?? 'N/A',
            'lastName': data['lastName'] ?? 'N/A',
            'phone': data['phone'] ?? 'N/A',
            'ngoName': data['ngoName'] ?? 'N/A',
            'branchName': data['branchName'] ?? 'N/A',
            'status': data['status'] ?? 'pending',
          });
        }
      }

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setRescuerRequests(requests);
      }
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Unable to fetch rescuer requests, Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> refreshRequests() async {
    if (mounted) {
      ref.read(manageRescuersProvider.notifier).setLoading(true);
    }
    try {
      await _fetchRescuerRequests();
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Error refreshing rescuer requests',
          context,
          AppColors.error,
        );
      }
    } finally {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _handleApprove(String requestId) async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (!mounted) return;
      ref.read(manageRescuersProvider.notifier).setLoading(true);
      if (ngoDocId == null || _rescuerFirestore == null) {
        if (mounted) {
          ref.read(manageRescuersProvider.notifier).setLoading(false);
          pageMessage(
            'Unable to approve rescuer request, Please try again.',
            context,
            AppColors.error,
          );
        }
        return;
      }

      // Update status in ngo-info-database
      await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .doc(requestId)
          .update({'status': 'approved'});

      // Update status in life-line-rescuer database
      await _rescuerFirestore!.collection('users').doc(requestId).update({
        'status': 'approved',
      });

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        pageMessage(
          'Rescuer request approved successfully',
          context,
          AppColors.success,
        );
        _fetchRescuerRequests();
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        pageMessage(
          'Failed to approve request, Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _handleReject(String requestId) async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (!mounted) return;
      ref.read(manageRescuersProvider.notifier).setLoading(true);
      if (ngoDocId == null || _rescuerFirestore == null) {
        if (mounted) {
          ref.read(manageRescuersProvider.notifier).setLoading(false);
        }
        return;
      }

      // Update status in ngo-info-database
      await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      // Update status in life-line-rescuer database
      await _rescuerFirestore!.collection('users').doc(requestId).update({
        'status': 'rejected',
      });

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        pageMessage('Rescuer request rejected', context, AppColors.error);
        _fetchRescuerRequests();
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        pageMessage(
          'Failed to reject request, Please try again.',
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
                    // Navigation Bar
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isMobile),
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
                  ],
                );
              },
            ),

            // Loading overlay
            Consumer(
              builder: (context, ref, child) {
                if (!mounted) return const SizedBox.shrink();
                final isLoading = ref.watch(
                  manageRescuersProvider.select((v) => v.isLoading),
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
          // Back button
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
                  'Manage Rescuers',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and approve pending rescuer requests',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentRose.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: refreshRequests,
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.accentRose,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet, WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final rescuerRequests = ref.watch(
      manageRescuersProvider.select((v) => v.rescuerRequests),
    );

    if (rescuerRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No pending rescuer requests',
                style: AppText.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: refreshRequests,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return isMobile || isTablet ? _buildMobileList(ref) : _buildWebTable(ref);
  }

  Widget _buildWebTable(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final rescuerRequests = ref.watch(
      manageRescuersProvider.select((v) => v.rescuerRequests),
    );

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
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(1.5),
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon.withValues(alpha: 0.03),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                children: [
                  _tableHeaderCell('Name'),
                  _tableHeaderCell('Phone'),
                  _tableHeaderCell('NGO Name'),
                  _tableHeaderCell('Branch'),
                  _tableHeaderCell('Actions', centered: true),
                ],
              ),
              // Data Rows
              ...rescuerRequests.asMap().entries.map((entry) {
                final request = entry.value;
                final requestId = request['id'];
                final firstName = request['firstName'];
                final lastName = request['lastName'];
                final phone = request['phone'];
                final ngoName = request['ngoName'];
                final branchName = request['branchName'];

                return TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.softBackground.withValues(alpha: 0.3),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  children: [
                    // Name + status badge
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName',
                              style: AppText.fieldLabel.copyWith(
                                fontSize: 13,
                                color: AppColors.darkCharcoal,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pending',
                                style: AppText.small.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Phone
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          phone,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // NGO Name
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
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Branch
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          branchName,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Actions
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Center(
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            alignment: WrapAlignment.center,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                                tooltip: 'Approve',
                                onPressed: () => _handleApprove(requestId),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.cancel,
                                  color: AppColors.accentRose,
                                  size: 22,
                                ),
                                tooltip: 'Reject',
                                onPressed: () => _handleReject(requestId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final rescuerRequests = ref.watch(
      manageRescuersProvider.select((v) => v.rescuerRequests),
    );
    return Column(
      children: rescuerRequests
          .map((request) => _buildMobileCard(request))
          .toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> request) {
    final requestId = request['id'];
    final firstName = request['firstName'];
    final lastName = request['lastName'];
    final phone = request['phone'];
    final ngoName = request['ngoName'];
    final branchName = request['branchName'];

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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryMaroon,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pending',
                          style: AppText.small.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                _MobileInfoRow(label: 'Phone', value: phone),
                const SizedBox(height: AppSpacing.md),
                _MobileInfoRow(label: 'NGO', value: ngoName),
                const SizedBox(height: AppSpacing.md),
                _MobileInfoRow(label: 'Branch', value: branchName),
                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _MobileActionButton(
                        label: 'Approve',
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        onPressed: () => _handleApprove(requestId),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: _MobileActionButton(
                        label: 'Reject',
                        icon: Icons.cancel,
                        color: AppColors.error,
                        onPressed: () => _handleReject(requestId),
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

  Widget _tableHeaderCell(String text, {bool centered = false}) {
    final cell = Text(
      text,
      style: AppText.formDescription.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: centered ? Center(child: cell) : cell,
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _MobileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
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
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
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
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MobileActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
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
    );
  }
}
