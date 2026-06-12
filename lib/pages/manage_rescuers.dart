import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/manage_rescuers_provider.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class ManageRescuers extends ConsumerStatefulWidget {
  const ManageRescuers({super.key});

  @override
  ConsumerState<ManageRescuers> createState() => _ManageRescuersState();
}

class _ManageRescuersState extends ConsumerState<ManageRescuers> {
  final FirebaseFirestore _ngoFirestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRescuerRequests();
    });
  }

  Future<void> _fetchRescuerRequests() async {
    if (mounted) {
      ref.read(manageRescuersProvider.notifier).setLoading(true);
    }
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;

      if (ngoDocId == null) {
        if (mounted) {
          ref.read(manageRescuersProvider.notifier).setLoading(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to fetch rescuer requests, Please try again.',
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            'status': data['status'] ?? 'pending',
          });
        }
      }

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setRescuerRequests(requests);
        ref.read(manageRescuersProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to fetch rescuer requests, Please try again.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleApprove(String requestId) async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (!mounted) return;
      ref.read(manageRescuersProvider.notifier).setLoading(true);
      if (ngoDocId == null) return;

      await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .doc(requestId)
          .update({'status': 'approved'});

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rescuer request approved successfully',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Refresh the list
        _fetchRescuerRequests();
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to approve request, Please try again.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
      if (ngoDocId == null) return;

      await _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rescuer request rejected',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Refresh the list
        _fetchRescuerRequests();
      }
    } catch (e) {
      if (mounted) {
        ref.read(manageRescuersProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to reject request, Please try again.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Column(
              children: [
                // Navigation Bar
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

                // Page Header
                Padding(
                  padding: EdgeInsets.all(
                    isMobile ? AppSpacing.lg : AppSpacing.xxl,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const NgoDashboard(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Rescuers',
                              style: AppText.appHeader.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Review and approve pending rescuer requests',
                              style: AppText.formDescription.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rescuer Requests List
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isLoading = ref.watch(
                        manageRescuersProvider.select((v) => v.isLoading),
                      );
                      final rescuerRequests = ref.watch(
                        manageRescuersProvider.select((v) => v.rescuerRequests),
                      );

                      return Stack(
                        children: [
                          // Main Content
                          rescuerRequests.isEmpty && !isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      Text(
                                        'No pending rescuer requests',
                                        style: AppText.fieldLabel.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? AppSpacing.lg
                                        : AppSpacing.xxl,
                                  ),
                                  itemCount: rescuerRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = rescuerRequests[index];
                                    return _RescuerRequestCard(
                                      firstName: request['firstName'],
                                      lastName: request['lastName'],
                                      phone: request['phone'],
                                      onApprove: () =>
                                          _handleApprove(request['id']),
                                      onReject: () =>
                                          _handleReject(request['id']),
                                    );
                                  },
                                ),

                          // Loading Overlay
                          if (isLoading)
                            const IgnorePointer(
                              child: Center(
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
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RescuerRequestCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String phone;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RescuerRequestCard({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Buttons Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryMaroon,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: AppText.fieldLabel.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
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
                const SizedBox(width: AppSpacing.md),
                // Compact action buttons
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Contact Information
            _InfoRow(icon: Icons.phone, label: 'Phone Number', value: phone),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppText.small.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppText.small.copyWith(
              color: AppColors.darkCharcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
