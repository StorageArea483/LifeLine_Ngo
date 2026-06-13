import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_ngo/pages/ngo_dashboard.dart';
import 'package:life_line_ngo/providers/critical_alerts_provider.dart';
import 'package:life_line_ngo/providers/ngo_dasboard_provider.dart';
import 'package:life_line_ngo/styles/styles.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVictimRequests();
    });
  }

  Future<void> _fetchVictimRequests() async {
    try {
      if (!mounted) return;
      final ngoDocId = ref.read(ngoDasboardProvider).ngoDocId;

      if (ngoDocId == null) {
        pageMessage(
          'Unable to fetch requests. Please re-login.',
          context,
          AppColors.error,
        );
        return;
      }

      // Fetch all requests for this NGO from Firestore
      final snapshot = await _ngoFirestore
          .collection('requests')
          .where('ngoId', isEqualTo: ngoDocId)
          .get();

      if (!mounted) return;

      final requests = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Only include requests with valid latitude and longitude
        if (data['latitude'] != null && data['longitude'] != null) {
          requests.add({
            'id': doc.id,
            'address': data['address'] ?? 'Address not available',
            'latitude': data['latitude'] as double,
            'longitude': data['longitude'] as double,
            'requestType': data['requestType'] ?? 'Unknown',
            'severity': data['severity'] ?? 'Unknown',
          });
        }
      }

      if (mounted) {
        ref.read(victimRequestsProvider.notifier).state = requests;
      }
    } catch (e) {
      pageMessage(
        'Error fetching victim locations, please retry',
        context,
        AppColors.error,
      );
      pageNavigation(const NgoDashboard(), context);
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
            final mapHeight = constraints.maxHeight * 0.38;

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

                        // Requests list
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

  Widget _buildContent(bool isMobile, bool isTablet, WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final victimRequests = ref.watch(victimRequestsProvider);

    if (victimRequests.isEmpty) {
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
                'No victim requests found',
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
        ? _buildMobileRequestList(ref)
        : _buildWebRequestTable(ref);
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
              0: FlexColumnWidth(2),
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
                children: [
                  _tableHeaderCell('Severity'),
                  _tableHeaderCell('Address'),
                  _tableHeaderCell('Emergency Type'),
                  _tableHeaderCell('Focus', centered: true),
                ],
              ),
              // Data Rows
              ...victimRequests.asMap().entries.map((entry) {
                final request = entry.value;
                final requestId = request['id'];
                final address = request['address'];
                final requestType = request['requestType'];
                final severity = request['severity'];
                final isFocused = focusedLocation == requestId;
                final isHighRisk = severity == 'High Risk';

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
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: isHighRisk
                                  ? AppColors.error
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                severity,
                                style: AppText.fieldLabel.copyWith(
                                  fontSize: 12,
                                  color: isHighRisk
                                      ? AppColors.error
                                      : Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                              color: AppColors.primaryMaroon,
                              size: 20,
                            ),
                            onPressed: () =>
                                _handleFocus(requestId, request, isFocused),
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
    final isHighRisk = severity == 'High Risk';
    if (!mounted) return const SizedBox.shrink();
    final focusedLocation = ref.watch(focusedLocationProvider);
    final isFocused = focusedLocation == requestId;

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
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: isHighRisk ? AppColors.error : Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$severity Alert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isHighRisk ? AppColors.error : Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Card content rows
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _MobileInfoRow(label: 'Address', value: address),
                const SizedBox(height: AppSpacing.md),
                _MobileInfoRow(label: 'Type', value: requestType),
                const SizedBox(height: AppSpacing.lg),

                // Action row
                Row(
                  children: [
                    Expanded(
                      child: _MobileActionButton(
                        label: isFocused ? 'Zoom Out' : 'Focus',
                        icon: isFocused
                            ? Icons.zoom_out_map
                            : Icons.my_location,
                        color: AppColors.primaryMaroon,
                        onPressed: () =>
                            _handleFocus(requestId, request, isFocused),
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
