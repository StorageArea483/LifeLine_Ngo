import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/critical_alerts_provider.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
import 'package:life_line_ngo/widgets/global/page_loading.dart';
import 'package:life_line_ngo/widgets/global/page_message.dart';
import 'package:life_line_ngo/widgets/global/page_navigation.dart';
import 'package:life_line_ngo/widgets/nav_bar.dart';

class CriticalAlerts extends ConsumerStatefulWidget {
  const CriticalAlerts({super.key});

  @override
  ConsumerState<CriticalAlerts> createState() => _CriticalAlertsState();
}

class _CriticalAlertsState extends ConsumerState<CriticalAlerts> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _ngoFirestore = FirebaseFirestore.instance;
  StreamSubscription? _rescuerSubscription;
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
      _initializeRescuerFirebase();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _rescuerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeRescuerFirebase() async {
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
    } catch (e) {
      if (mounted) {
        pageMessage(
          'Failed to initialize rescuer database',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _submitAssignments() async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;
      if (!mounted) return;
      ref.read(criticalAlertsLoadingProvider.notifier).state = true;

      if (_rescuerFirestore == null) {
        throw Exception('Rescuer database not initialized');
      }

      if (ngoDocId == null) {
        throw Exception('NGO ID not found');
      }

      if (!mounted) return;

      final assignedRescuers = ref.read(assignedRescuersProvider);

      if (assignedRescuers.isEmpty) {
        throw Exception('No assignments found');
      }

      if (!mounted) return;

      final victimRequests = ref.read(victimRequestsProvider);

      // Group assignments by rescuer with severity
      final rescuerAssignments = <String, Map<String, String>>{};

      for (final assignment in assignedRescuers.entries) {
        final victimId = assignment.key;
        final rescuerId = assignment.value;

        // Get the victim's severity
        final victim = victimRequests.firstWhere(
          (v) => v['id'] == victimId,
          orElse: () => {'severity': 'N/A'},
        );

        final severity = victim['severity'] ?? 'N/A';

        // Create or update the rescuer's assignment map
        if (!rescuerAssignments.containsKey(rescuerId)) {
          rescuerAssignments[rescuerId] = {};
        }

        // Add victim ID as key and severity as value to the map
        rescuerAssignments[rescuerId]![victimId] = severity;
      }

      // Update each rescuer in both databases
      for (final entry in rescuerAssignments.entries) {
        final rescuerId = entry.key;
        final assignmentsMap = entry.value;
        final assignmentCount = assignmentsMap.length;

        await Future.wait([
          // Update NGO database
          _ngoFirestore
              .collection('ngo-info-database')
              .doc(ngoDocId)
              .collection('rescuer-requests')
              .doc(rescuerId)
              .set({
                'assigned': assignmentsMap,
                'requests': assignmentCount,
              }, SetOptions(merge: true)),
          // Update Rescuer database
          _rescuerFirestore!.collection('users').doc(rescuerId).set({
            'assigned': assignmentsMap,
            'requests': assignmentCount,
          }, SetOptions(merge: true)),
        ]);
      }

      // Collect all victim IDs that were just assigned (across all rescuers)
      final assignedVictimIds = assignedRescuers.keys.toSet();
      await Future.wait(
        assignedVictimIds.map(
          (victimId) =>
              _ngoFirestore.collection('requests').doc(victimId).delete(),
        ),
      );

      if (mounted) {
        // Remove the now-assigned victims from the Victim Requests section
        final updatedRequests = victimRequests
            .where((v) => !assignedVictimIds.contains(v['id']))
            .toList();

        ref.read(victimRequestsProvider.notifier).state = updatedRequests;

        ref.read(criticalAlertsLoadingProvider.notifier).state = false;
        ref.read(assignedRescuersProvider.notifier).state = {};

        pageMessage(
          'Assignments submitted successfully.',
          context,
          AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(criticalAlertsLoadingProvider.notifier).state = false;
        pageMessage(
          'Error submitting assignments, please try again',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      if (!mounted) return;
      // Set loading to true
      ref.read(criticalAlertsLoadingProvider.notifier).state = true;

      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;

      if (ngoDocId == null) {
        if (mounted) {
          ref.read(criticalAlertsLoadingProvider.notifier).state = false;
          pageMessage(
            'Unable to fetch requests. Please re-login.',
            context,
            AppColors.error,
          );
        }
        return;
      }

      // Fetch victim requests once
      await _fetchVictimRequests(ngoDocId);

      // Set up stream listener for approved rescuers
      _listenToApprovedRescuers(ngoDocId);

      if (mounted) {
        ref.read(criticalAlertsLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(criticalAlertsLoadingProvider.notifier).state = false;
        pageMessage(
          'Error fetching data, please retry',
          context,
          AppColors.error,
        );
        pageNavigation(const NgoDashboard(), context);
      }
    }
  }

  Future<void> _fetchVictimRequests(String ngoDocId) async {
    try {
      // Fetch all requests for this NGO from Firestore
      final snapshot = await _ngoFirestore
          .collection('requests')
          .where('ngoId', isEqualTo: ngoDocId)
          .get();

      final requests = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Only include requests with valid latitude and longitude
        if (data['latitude'] != null && data['longitude'] != null) {
          requests.add({
            'id': doc.id,
            'address': data['address'] ?? 'N/A',
            'latitude': data['latitude'] as double,
            'longitude': data['longitude'] as double,
            'requestType': data['requestType'] ?? 'N/A',
            'severity': data['severity'] ?? 'N/A',
          });
        }
      }

      if (mounted) {
        ref.read(victimRequestsProvider.notifier).state = requests;
      }
    } catch (e) {
      rethrow;
    }
  }

  void _listenToApprovedRescuers(String ngoDocId) {
    try {
      // Cancel existing subscription before reassigning
      _rescuerSubscription?.cancel();

      // Set up stream listener for rescuer-requests subcollection
      _rescuerSubscription = _ngoFirestore
          .collection('ngo-info-database')
          .doc(ngoDocId)
          .collection('rescuer-requests')
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

            final rescuers = <Map<String, dynamic>>[];

            for (var rescuerDoc in snapshot.docs) {
              final rescuerData = rescuerDoc.data();

              // Check if the rescuer is approved
              if (rescuerData['status'] == 'approved') {
                // Get the first name and last name from rescuer data
                final firstName = rescuerData['firstName'] ?? '';
                final lastName = rescuerData['lastName'] ?? '';
                final fullName = '$firstName $lastName'.trim();

                rescuers.add({
                  'id': rescuerDoc.id,
                  'fullName': fullName.isEmpty ? 'N/A' : fullName,
                  'selectedService': rescuerData['selectedService'] ?? 'N/A',
                  'branchName': rescuerData['branchName'] ?? 'N/A',
                  'requestCount': rescuerData['requests'] ?? 0,
                  'online': rescuerData['online'] ?? false,
                });
              }
            }

            if (mounted) {
              ref.read(approvedRescuersProvider.notifier).state = rescuers;
            }
          });
    } catch (e) {
      pageMessage(
        'Error listening to rescuers, please retry',
        context,
        AppColors.error,
      );
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
                final isTablet =
                    constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
                final mapHeight = constraints.maxHeight * 0.38;

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
                            // Map Card
                            _buildMapCard(mapHeight, isMobile),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            // Approved Rescuers Header
                            _buildApprovedRescuersHeader(isMobile),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            // Approved Rescuers Section
                            Consumer(
                              builder: (context, ref, child) {
                                return _buildApprovedRescuersSection(
                                  isMobile,
                                  isTablet,
                                  ref,
                                );
                              },
                            ),
                            SizedBox(
                              height: isMobile
                                  ? AppSpacing.xxl
                                  : AppSpacing.xxxxl,
                            ),
                            // Victim Requests Section Header
                            _buildVictimRequestsHeader(isMobile),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            // Requests list
                            Consumer(
                              builder: (context, ref, child) {
                                return _buildVictimRequestsTable(
                                  isMobile,
                                  isTablet,
                                  ref,
                                );
                              },
                            ),
                            SizedBox(
                              height: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            // Submit button
                            _buildSubmitAssignmentsButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Loading Overlay
          Consumer(
            builder: (context, ref, child) {
              if (!mounted) return const SizedBox.shrink();
              final isLoading = ref.watch(criticalAlertsLoadingProvider);
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
                  'Critical Alerts',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor and respond to active victim requests',
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

  Widget _buildVictimRequestsHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withValues(alpha: 0.05),
            AppColors.accentRose.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Emergency icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Victim Requests',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active emergency requests requiring immediate attention',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
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

  Widget _buildMapCard(double mapHeight, bool isMobile) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: mapHeight,
          width: double.infinity,
          child: Opacity(
            opacity: 0.9,
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(34.1463, 73.2117), // Default: Abbottabad
                initialZoom: 11,
                minZoom: 1,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.lifeline.ngo.app',
                ),
                Consumer(
                  builder: (context, ref, child) {
                    if (!mounted) return const SizedBox.shrink();
                    final victimRequests = ref.watch(victimRequestsProvider);

                    return MarkerLayer(
                      markers: victimRequests.map((request) {
                        final requestId = request['id'];
                        final locationAsync = ref.watch(
                          victimLocationProvider(requestId),
                        );
                        final location = locationAsync.when(
                          data: (liveLocation) =>
                              liveLocation ??
                              LatLng(request['latitude'], request['longitude']),
                          loading: () =>
                              LatLng(request['latitude'], request['longitude']),
                          error: (_, __) =>
                              LatLng(request['latitude'], request['longitude']),
                        );

                        return Marker(
                          point: location,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                            size: 20,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedRescuersHeader(bool isMobile) {
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
          // Rescuers icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approved Rescuers',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, child) {
                    if (!mounted) return const SizedBox.shrink();
                    final rescuers = ref.watch(approvedRescuersProvider);
                    return Text(
                      '${rescuers.length} active rescuer${rescuers.length != 1 ? 's' : ''} responding to emergencies',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedRescuersSection(
    bool isMobile,
    bool isTablet,
    WidgetRef ref,
  ) {
    if (!mounted) return const SizedBox.shrink();
    final rescuers = ref.watch(approvedRescuersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rescuers List/Table
        if (rescuers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No approved rescuers found',
                    style: AppText.subtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isMobile || isTablet)
          _buildMobileRescuersList(rescuers, ref)
        else
          _buildWebRescuersTable(rescuers, ref),
      ],
    );
  }

  Widget _buildWebRescuersTable(
    List<Map<String, dynamic>> rescuers,
    WidgetRef ref,
  ) {
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
                children: [
                  _tableHeaderCell('Online Status'),
                  _tableHeaderCell('Rescuer Name'),
                  _tableHeaderCell('Service Type'),
                  _tableHeaderCell('Branch'),
                  _tableHeaderCell('Requests', centered: true),
                ],
              ),
              // Data Rows
              ...rescuers.map((rescuer) {
                final fullName = rescuer['fullName'];
                final selectedService = rescuer['selectedService'];
                final branchName = rescuer['branchName'];
                final status = rescuer['online'];

                return TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.softBackground.withValues(alpha: 0.3),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  children: [
                    // Online status cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          status ? 'Rescuer is Online' : 'Rescuer is Offline',
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // Name cell
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
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Service type cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          selectedService,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Branch cell
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
                    // Requests count cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Center(
                          child: Text(
                            '${rescuer['requestCount'] ?? 0}',
                            style: AppText.fieldLabel.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
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

  Widget _buildMobileRescuersList(
    List<Map<String, dynamic>> rescuers,
    WidgetRef ref,
  ) {
    return Column(
      children: rescuers
          .map((rescuer) => _buildMobileRescuerCard(rescuer, ref))
          .toList(),
    );
  }

  Widget _buildMobileRescuerCard(Map<String, dynamic> rescuer, WidgetRef ref) {
    final fullName = rescuer['fullName'];
    final selectedService = rescuer['selectedService'];
    final branchName = rescuer['branchName'];
    final status = rescuer['online'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileInfoRow(
              label: 'Online',
              value: status ? 'Rescuer is Online' : 'Rescuer is Offline',
            ),
            const SizedBox(height: AppSpacing.sm),
            _MobileInfoRow(label: 'Name', value: fullName),
            const SizedBox(height: AppSpacing.sm),
            _MobileInfoRow(
              label: 'Requests',
              value: rescuer['requestCount'].toString(),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Service and Branch info
            _MobileInfoRow(label: 'Service', value: selectedService),
            const SizedBox(height: AppSpacing.sm),
            _MobileInfoRow(label: 'Branch', value: branchName),
          ],
        ),
      ),
    );
  }

  Widget _buildVictimRequestsTable(
    bool isMobile,
    bool isTablet,
    WidgetRef ref,
  ) {
    if (!mounted) return const SizedBox.shrink();
    final victimRequests = ref.watch(victimRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Requests content
        if (victimRequests.isEmpty)
          Center(
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
                    'No victim requests found',
                    style: AppText.subtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isMobile || isTablet)
          _buildMobileRequestList(ref)
        else
          _buildWebRequestTable(ref),
      ],
    );
  }

  Widget _buildWebRequestTable(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victimRequests = ref.watch(victimRequestsProvider);
    if (!mounted) return const SizedBox.shrink();
    final focusedLocation = ref.watch(focusedLocationProvider);

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
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.3),
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
                  _tableHeaderCell('Severity'),
                  _tableHeaderCell('Address'),
                  _tableHeaderCell('Emergency Type'),
                  _tableHeaderCell('Assign Rescuer'),
                  _tableHeaderCell('Focus', centered: true),
                ],
              ),
              // Data Rows
              ...victimRequests.map((victim) {
                final requestId = victim['id'];
                final address = victim['address'];
                final requestType = victim['requestType'];
                final severity = victim['severity'];
                final isFocused = focusedLocation == requestId;

                return TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.softBackground.withValues(alpha: 0.3),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  children: [
                    // Severity cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          severity,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Address cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          address,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                    ),
                    // Emergency type cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          requestType,
                          style: AppText.fieldLabel.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Assign Rescuer dropdown cell
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            if (!mounted) return const SizedBox.shrink();
                            final assignedRescuers = ref.watch(
                              assignedRescuersProvider,
                            );
                            if (!mounted) return const SizedBox.shrink();
                            final approvedRescuers = ref.watch(
                              approvedRescuersProvider,
                            );
                            final availableRescuers = approvedRescuers.toList();

                            return DropdownButton<String>(
                              value: assignedRescuers[requestId],
                              hint: Text(
                                'Select Rescuer',
                                style: AppText.fieldLabel.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: [
                                // Add "None" option to unselect
                                if (assignedRescuers[requestId] != null)
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'None (Clear Assignment)',
                                      style: AppText.fieldLabel.copyWith(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ...availableRescuers.map((rescuer) {
                                  return DropdownMenuItem<String>(
                                    value: rescuer['id'],
                                    child: Text(
                                      rescuer['fullName'],
                                      style: AppText.fieldLabel.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (String? newValue) {
                                if (!mounted) return;
                                ref
                                    .read(assignedRescuersProvider.notifier)
                                    .update((state) {
                                      final newState = {...state};
                                      if (newValue == null) {
                                        // Remove assignment
                                        newState.remove(requestId);
                                      } else {
                                        // Add or update assignment
                                        newState[requestId] = newValue;
                                      }
                                      return newState;
                                    });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    // Focus/zoom cell
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
                            icon: Icon(
                              isFocused
                                  ? Icons.zoom_out_map
                                  : Icons.my_location,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                _handleFocus(requestId, victim, isFocused),
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

  Widget _buildMobileRequestList(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victimRequests = ref.watch(victimRequestsProvider);

    return Column(
      children: victimRequests
          .map((request) => _buildMobileCard(request, ref))
          .toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> request, WidgetRef ref) {
    final requestId = request['id'];
    final address = request['address'];
    final requestType = request['requestType'];
    final severity = request['severity'];
    if (!mounted) return const SizedBox.shrink();
    final focusedLocation = ref.watch(focusedLocationProvider);
    final isFocused = focusedLocation == requestId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileInfoRow(label: 'Severity', value: severity),
            const SizedBox(height: AppSpacing.sm),
            _MobileInfoRow(label: 'Type', value: requestType),
            const SizedBox(height: AppSpacing.sm),
            _MobileInfoRow(label: 'Address', value: address),
            const SizedBox(height: AppSpacing.lg),
            // Assign Rescuer Dropdown
            Consumer(
              builder: (context, ref, child) {
                if (!mounted) return const SizedBox.shrink();
                final assignedRescuers = ref.watch(assignedRescuersProvider);
                if (!mounted) return const SizedBox.shrink();
                final approvedRescuers = ref.watch(approvedRescuersProvider);
                // Get list of all available rescuers (all can be assigned)
                final availableRescuers = approvedRescuers.toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Rescuer',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: assignedRescuers[requestId],
                        hint: const Text(
                          'Select Rescuer',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          // Add "None" option to unselect
                          if (assignedRescuers[requestId] != null)
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'None (Clear Assignment)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.error,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ...availableRescuers.map((rescuer) {
                            return DropdownMenuItem<String>(
                              value: rescuer['id'],
                              child: Text(
                                rescuer['fullName'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkCharcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (String? newValue) {
                          if (!mounted) return;
                          ref.read(assignedRescuersProvider.notifier).update((
                            state,
                          ) {
                            final newState = {...state};
                            if (newValue == null) {
                              // Remove assignment
                              newState.remove(requestId);
                            } else {
                              // Add or update assignment
                              newState[requestId] = newValue;
                            }
                            return newState;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: _MobileActionButton(
                label: isFocused ? 'Zoom Out' : 'Focus',
                icon: isFocused ? Icons.zoom_out_map : Icons.my_location,
                color: AppColors.primaryMaroon,
                onPressed: () => _handleFocus(requestId, request, isFocused),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitAssignmentsButton() {
    return Consumer(
      builder: (context, ref, child) {
        if (!mounted) return const SizedBox.shrink();
        final assignedRescuers = ref.watch(assignedRescuersProvider);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: ElevatedButton.icon(
              onPressed: assignedRescuers.isNotEmpty
                  ? () => _submitAssignments()
                  : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Submit Assignments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: assignedRescuers.isNotEmpty
                    ? AppColors.primaryMaroon
                    : AppColors.borderLight,
                foregroundColor: assignedRescuers.isNotEmpty
                    ? Colors.white
                    : AppColors.textMuted,
                elevation: assignedRescuers.isNotEmpty ? 2 : 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.xl,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
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

  void _handleFocus(
    String requestId,
    Map<String, dynamic> request,
    bool isFocused,
  ) {
    if (isFocused && mounted) {
      ref.read(focusedLocationProvider.notifier).state = null;
      _mapController.move(const LatLng(34.1463, 73.2117), 11);
    } else {
      if (!mounted) return;
      ref.read(focusedLocationProvider.notifier).state = requestId;
      if (!mounted) return;
      final locationAsync = ref.read(victimLocationProvider(requestId));
      final location = locationAsync.when(
        data: (liveLocation) =>
            liveLocation ?? LatLng(request['latitude'], request['longitude']),
        loading: () => LatLng(request['latitude'], request['longitude']),
        error: (_, __) => LatLng(request['latitude'], request['longitude']),
      );
      _mapController.move(location, 16);
    }
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
