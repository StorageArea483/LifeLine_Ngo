import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Real-time location provider for individual victims by request ID
final victimLocationProvider = StreamProvider.family<LatLng?, String>((
  ref,
  requestId,
) {
  final firestore = FirebaseFirestore.instance;

  return firestore.collection('requests').doc(requestId).snapshots().map((doc) {
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;

    if (latitude == null || longitude == null) return null;

    return LatLng(latitude, longitude);
  });
});

// Provider for storing victims list
final victimRequestsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// Track the currently focused location (null means show all)
final focusedLocationProvider = StateProvider<String?>((ref) => null);

// Provider for storing approved rescuers list
final approvedRescuersProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// Loading state provider for critical alerts page
final criticalAlertsLoadingProvider = StateProvider<bool>((ref) => true);

// provider used to hold the assigned rescuers data
final assignedRescuersProvider = StateProvider<Map<String, String>>((ref) {
  return {};
});
