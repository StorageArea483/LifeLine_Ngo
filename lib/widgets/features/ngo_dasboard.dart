import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/utils/styles.dart';
import 'package:life_line_ngo/widgets/constants/constants.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  // List to store victims data
  List<Map<String, dynamic>> victims = [];
  bool isLoading = true;

  // Second Firebase app for victim database
  FirebaseApp? victimApp;
  FirebaseFirestore? victimFirestore;

  @override
  void initState() {
    super.initState();
    _initVictimDatabase();
  }

  Future<void> _initVictimDatabase() async {
    try {
      // Initialize second Firebase app for victim database
      victimApp = await Firebase.initializeApp(
        name: 'victimApp',
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCgdeU_737w9twNR2zt5dzyG5EXK5uKxR0',
          authDomain: 'life-line-victim-27aaa.firebaseapp.com',
          projectId: 'life-line-victim-27aaa',
          storageBucket: 'life-line-victim-27aaa.firebasestorage.app',
          messagingSenderId: '909144850972',
          appId: '1:909144850972:web:a9eb7a5cfcec7e437c55d9',
        ),
      );

      victimFirestore = FirebaseFirestore.instanceFor(app: victimApp!);
      await _fetchVictims();
    } catch (e) {
      // If app already exists, use it
      if (e.toString().contains('already exists')) {
        victimApp = Firebase.app('victimApp');
        victimFirestore = FirebaseFirestore.instanceFor(app: victimApp!);
        await _fetchVictims();
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _fetchVictims() async {
    try {
      final snapshot = await victimFirestore!
          .collection('victim-info-database')
          .get();

      final List<Map<String, dynamic>> fetchedVictims = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Only add victims with severity status
        if (data['severity'] != null &&
            data['severity'].toString().isNotEmpty) {
          fetchedVictims.add({
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'location': data['Location'] ?? '',
            'phoneNumber': data['phoneNumber'] ?? '',
            'severity': data['severity'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          victims = fetchedVictims;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xxxl),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCards(),
                        const SizedBox(height: AppSpacing.xxxxl),
                        _buildQuickActions(),
                        const SizedBox(height: AppSpacing.xxxxl),
                        _buildVictimsTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder, color: primaryMaroon, size: 32),
            const SizedBox(width: AppSpacing.sm),
            Text('LifeLine', style: AppText.appHeader),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('NGO Command Center', style: AppText.welcomeTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Welcome back. Here is the current status of relief operations.',
          style: AppText.formDescription,
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Column(
            children: [
              _buildStatCard(
                'Total Victims',
                '${victims.length}',
                'Registered',
                Colors.blue,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildStatCard('Active Ops', '8', '2 New', Colors.orange),
              const SizedBox(height: AppSpacing.lg),
              _buildStatCard('Volunteers', '150', '+12 On-site', Colors.purple),
              const SizedBox(height: AppSpacing.lg),
              _buildStatCard(
                'Critical Alerts',
                '3',
                'Needs Attention',
                Colors.red,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Victims',
                '${victims.length}',
                'Registered',
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildStatCard('Active Ops', '8', '2 New', Colors.orange),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildStatCard(
                'Volunteers',
                '150',
                '+12 On-site',
                Colors.purple,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildStatCard(
                'Critical Alerts',
                '3',
                'Needs Attention',
                Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: iconColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppText.fieldLabel.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppText.welcomeTitle.copyWith(fontSize: 32)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppText.small.copyWith(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppText.formTitle),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return Column(
                children: [
                  _buildActionCard(
                    'Relief Operations',
                    'View active zones',
                    Icons.location_on,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActionCard(
                    'Manage Volunteers',
                    'Assign tasks & shifts',
                    Icons.group,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActionCard(
                    'Submit Reports',
                    'Daily status updates',
                    Icons.description,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Relief Operations',
                    'View active zones',
                    Icons.location_on,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _buildActionCard(
                    'Manage Volunteers',
                    'Assign tasks & shifts',
                    Icons.group,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _buildActionCard(
                    'Submit Reports',
                    'Daily status updates',
                    Icons.description,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryMaroon, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppText.fieldLabel),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppText.small),
        ],
      ),
    );
  }

  Widget _buildVictimsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registered Victims', style: AppText.formTitle),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          decoration: AppContainers.cardContainer,
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryMaroon),
                  ),
                )
              : victims.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No victims found', style: AppText.small),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth:
                          MediaQuery.of(context).size.width -
                          (AppSpacing.xxl * 2),
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        softBackground.withValues(alpha: 0.3),
                      ),
                      columnSpacing: 40,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: double.infinity,
                      columns: [
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Name',
                              style: AppText.fieldLabel.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Location',
                              style: AppText.fieldLabel.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Contact Information',
                              style: AppText.fieldLabel.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text(
                              'Status',
                              style: AppText.fieldLabel.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(victims.length, (index) {
                        final victim = victims[index];
                        final fullName =
                            '${victim['firstName']} ${victim['lastName']}'
                                .trim();
                        final location = victim['location'] ?? '';
                        final phone = victim['phoneNumber'] ?? '';
                        final severity = victim['severity'] ?? '';

                        return DataRow(
                          cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  fullName,
                                  style: AppText.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: accentRose,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: AppText.small,
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                child: Text(
                                  phone,
                                  style: AppText.small,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ),
                            DataCell(_buildStatusBadge(severity)),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String severity) {
    Color statusColor;

    switch (severity.toLowerCase()) {
      case 'critical':
        statusColor = Colors.red;
        break;
      case 'injured':
        statusColor = Colors.orange;
        break;
      case 'safe':
        statusColor = Colors.green;
        break;
      case 'displaced':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        severity,
        style: AppText.small.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
