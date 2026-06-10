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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to fetch requests. Please re-login.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error fetching victim locations, please retry'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NgoDashboard()),
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
            final mapHeight = constraints.maxHeight * 0.4;
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

                // Map Card
                Padding(
                  padding: EdgeInsets.all(
                    isMobile ? AppSpacing.lg : AppSpacing.xxl,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: mapHeight,
                        width: double.infinity,
                        child: Opacity(
                          opacity: 0.9,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: const MapOptions(
                              initialCenter: LatLng(
                                34.1463,
                                73.2117,
                              ), // Default: Abbottabad
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
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.lifeline.ngo.app',
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  if (!mounted) {
                                    return const SizedBox.shrink();
                                  }
                                  final victimRequests = ref.watch(
                                    victimRequestsProvider,
                                  );
                                  return MarkerLayer(
                                    markers: victimRequests.map((request) {
                                      final requestId = request['id'];

                                      // Watch real-time location for this victim
                                      final locationAsync = ref.watch(
                                        victimLocationProvider(requestId),
                                      );

                                      // Use real-time location if available, fallback to initial location
                                      final location = locationAsync.when(
                                        data: (liveLocation) =>
                                            liveLocation ??
                                            LatLng(
                                              request['latitude'],
                                              request['longitude'],
                                            ),
                                        loading: () => LatLng(
                                          request['latitude'],
                                          request['longitude'],
                                        ),
                                        error: (_, __) => LatLng(
                                          request['latitude'],
                                          request['longitude'],
                                        ),
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
                  ),
                ),

                // Victim Requests List
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        if (!mounted) {
                          return const SizedBox.shrink();
                        }
                        final victimRequests = ref.watch(
                          victimRequestsProvider,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Victim Requests (${victimRequests.length})',
                              style: AppText.appHeader.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: victimRequests.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.search_off_outlined,
                                            size: 48,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(height: 15),
                                          Text(
                                            'No victim requests found',
                                            style: AppText.formDescription
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: victimRequests.length,
                                      itemBuilder: (context, index) {
                                        final request = victimRequests[index];
                                        final requestId = request['id'];

                                        return Consumer(
                                          builder: (context, ref, child) {
                                            if (!mounted) {
                                              return const SizedBox.shrink();
                                            }
                                            final expandedItems = ref.watch(
                                              expandedItemsProvider,
                                            );
                                            final isExpanded = expandedItems
                                                .contains(requestId);
                                            if (!mounted) {
                                              return const SizedBox.shrink();
                                            }
                                            final focusedLocation = ref.watch(
                                              focusedLocationProvider,
                                            );

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: AppSpacing.lg,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  // Main Card Header (Always Visible)
                                                  MouseRegion(
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        if (mounted) {
                                                          final currentExpanded =
                                                              ref.read(
                                                                expandedItemsProvider,
                                                              );
                                                          final newExpanded =
                                                              Set<String>.from(
                                                                currentExpanded,
                                                              );

                                                          if (isExpanded) {
                                                            newExpanded.remove(
                                                              requestId,
                                                            );
                                                          } else {
                                                            newExpanded.add(
                                                              requestId,
                                                            );
                                                          }

                                                          ref
                                                                  .read(
                                                                    expandedItemsProvider
                                                                        .notifier,
                                                                  )
                                                                  .state =
                                                              newExpanded;
                                                        }
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              AppSpacing.xl,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // Title
                                                            Expanded(
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .warning_amber_rounded,
                                                                    size: 18,
                                                                    color:
                                                                        request['severity'] ==
                                                                            'High Risk'
                                                                        ? AppColors
                                                                              .error
                                                                        : Colors
                                                                              .orange,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Flexible(
                                                                    child: Text(
                                                                      '${request['severity']} Alert',
                                                                      style: AppText.fieldLabel.copyWith(
                                                                        color:
                                                                            request['severity'] ==
                                                                                'High Risk'
                                                                            ? AppColors.error
                                                                            : Colors.orange,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // Location Button
                                                            IconButton(
                                                              icon: Icon(
                                                                focusedLocation ==
                                                                        requestId
                                                                    ? Icons
                                                                          .zoom_out_map
                                                                    : Icons
                                                                          .my_location,
                                                                color: AppColors
                                                                    .primaryMaroon,
                                                              ),
                                                              onPressed: () {
                                                                if (focusedLocation ==
                                                                    requestId) {
                                                                  // Zoom out to default view
                                                                  ref
                                                                          .read(
                                                                            focusedLocationProvider.notifier,
                                                                          )
                                                                          .state =
                                                                      null;
                                                                  _mapController.move(
                                                                    const LatLng(
                                                                      34.1463,
                                                                      73.2117,
                                                                    ), // Default: Abbottabad
                                                                    11,
                                                                  );
                                                                } else {
                                                                  // Zoom to this specific victim's location
                                                                  ref
                                                                          .read(
                                                                            focusedLocationProvider.notifier,
                                                                          )
                                                                          .state =
                                                                      requestId;

                                                                  // Get real-time location for this victim
                                                                  final locationAsync =
                                                                      ref.read(
                                                                        victimLocationProvider(
                                                                          requestId,
                                                                        ),
                                                                      );

                                                                  final location = locationAsync.when(
                                                                    data:
                                                                        (
                                                                          liveLocation,
                                                                        ) =>
                                                                            liveLocation ??
                                                                            LatLng(
                                                                              request['latitude'],
                                                                              request['longitude'],
                                                                            ),
                                                                    loading: () => LatLng(
                                                                      request['latitude'],
                                                                      request['longitude'],
                                                                    ),
                                                                    error:
                                                                        (
                                                                          _,
                                                                          __,
                                                                        ) => LatLng(
                                                                          request['latitude'],
                                                                          request['longitude'],
                                                                        ),
                                                                  );

                                                                  _mapController
                                                                      .move(
                                                                        location,
                                                                        16,
                                                                      );
                                                                }
                                                              },
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            // Expand/Collapse Arrow
                                                            AnimatedRotation(
                                                              turns: isExpanded
                                                                  ? 0.5
                                                                  : 0,
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              child: const Icon(
                                                                Icons
                                                                    .keyboard_arrow_down,
                                                                color: AppColors
                                                                    .textSecondary,
                                                                size: 24,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Expandable Details
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    height: isExpanded
                                                        ? null
                                                        : 0,
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      opacity: isExpanded
                                                          ? 1.0
                                                          : 0.0,
                                                      child: isExpanded
                                                          ? Container(
                                                              padding:
                                                                  const EdgeInsets.fromLTRB(
                                                                    AppSpacing
                                                                        .xl,
                                                                    0,
                                                                    AppSpacing
                                                                        .xl,
                                                                    AppSpacing
                                                                        .xl,
                                                                  ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .pin_drop_outlined,
                                                                        size:
                                                                            16,
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          request['address'],
                                                                          style: AppText.small.copyWith(
                                                                            color:
                                                                                Colors.black87,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            height:
                                                                                1.4,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .category_outlined,
                                                                        size:
                                                                            16,
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          'Emergency Type: ${request['requestType']}',
                                                                          style: AppText.small.copyWith(
                                                                            color:
                                                                                Colors.black87,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : const SizedBox.shrink(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
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
}
