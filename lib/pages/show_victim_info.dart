import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/pages/ngo_auth.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class ShowVictimInfo extends ConsumerStatefulWidget {
  const ShowVictimInfo({super.key});

  @override
  ConsumerState<ShowVictimInfo> createState() => _ShowVictimInfoState();
}

class _ShowVictimInfoState extends ConsumerState<ShowVictimInfo> {
  final TextEditingController _searchController = TextEditingController();
  FirebaseFirestore? _victimFirestore;
  StreamSubscription? _victimSubscription;

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
    _searchController.dispose();
    _victimSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initVictimFirebase() async {
    if (mounted) ref.read(ngoDasboardProvider.notifier).setLoading(true);
    try {
      final secondaryApp = await Firebase.initializeApp(
        name: 'life-line-victim',
        options: _victimFirebaseOptions,
      );
      _victimFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);
      _listenToVictims();
      if (mounted) ref.read(ngoDasboardProvider.notifier).setLoading(false);
    } catch (e) {
      if (mounted) {
        ref.read(ngoDasboardProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching victims, please try again'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NgoAuth()),
        );
      }
    }
  }

  void _listenToVictims() {
    if (_victimFirestore == null) return;

    try {
      // Cancel existing subscription before reassigning
      _victimSubscription?.cancel();
      _victimSubscription = _victimFirestore!
          .collection('users')
          .snapshots()
          .listen(
            (snapshot) {
              if (!mounted) return;
              final allVictims = snapshot.docs
                  .map((doc) => doc.data())
                  .toList();
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
                ref.read(ngoDasboardProvider.notifier).setVictims(finalList);
              }
            },
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error loading victims, please try again'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          );
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const NgoDashboard(),
                      ),
                    );
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
                  'Victim Management',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and monitor registered victims',
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
      child: isMobile
          ? Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.softBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter victim name to search...',
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
                    onPressed: _listenToVictims,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Search Victims',
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
                        hintText: 'Enter victim name to search...',
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
                    onPressed: _listenToVictims,
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
                      'Search Victims',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet, WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victims = ref.watch(ngoDasboardProvider.select((v) => v.victims));

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
                'No victims data found',
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
      child: Consumer(
        builder: (context, ref, child) {
          if (!mounted) return const SizedBox.shrink();
          final victims = ref.watch(
            ngoDasboardProvider.select((v) => v.victims),
          );

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
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
                children: ['Name', 'Location', 'Contact Information', 'Status']
                    .map((label) {
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            label,
                            style: AppText.formDescription.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              // Data Rows
              ...victims.map((victim) {
                final name = victim['name'] ?? '';
                final location = victim['location'] ?? '';
                final email = victim['email'] ?? '';
                final severity = victim['severity'] ?? '';

                Color statusColor;
                switch (severity.toLowerCase()) {
                  case 'high risk':
                    statusColor = AppColors.error;
                    break;
                  case 'medium risk':
                    statusColor = AppColors.warning;
                    break;
                  case 'low risk':
                    statusColor = AppColors.success;
                    break;
                  default:
                    statusColor = AppColors.info;
                }

                return TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.softBackground.withValues(alpha: 0.3),
                    border: Border.all(color: AppColors.borderLight, width: 1),
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
                          name.isEmpty ? 'N/A' : name,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                          horizontal: AppSpacing.xxxl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          location.isEmpty ? 'N/A' : location,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                          email.isEmpty ? 'N/A' : email,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Status Cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          severity.isEmpty ? 'Unknown' : severity,
                          style: AppText.small.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMobileVictimList(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victims = ref.watch(ngoDasboardProvider.select((v) => v.victims));

    return Column(
      children: victims.map((victim) => _buildMobileCard(victim)).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> victim) {
    final name = victim['name'] ?? 'N/A';
    final email = victim['email'] ?? 'N/A';
    final location = victim['location'] ?? 'N/A';
    final severity = victim['severity'] ?? 'Unknown';

    Color statusColor;
    switch (severity.toLowerCase()) {
      case 'critical':
        statusColor = AppColors.error;
        break;
      case 'injured':
        statusColor = AppColors.warning;
        break;
      case 'safe':
        statusColor = AppColors.success;
        break;
      case 'displaced':
        statusColor = AppColors.textSecondary;
        break;
      default:
        statusColor = AppColors.info;
    }

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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    severity,
                    style: AppText.small.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _MobileInfoRow(label: 'Email', value: email, icon: Icons.email),
                const SizedBox(height: AppSpacing.md),
                _MobileInfoRow(
                  label: 'Location',
                  value: location,
                  icon: Icons.location_on,
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
  final IconData icon;

  const _MobileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accentRose),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkCharcoal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
