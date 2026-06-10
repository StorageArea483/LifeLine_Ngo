import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Real-time location provider for individual victims by request ID
final victimLocationProvider = StreamProvider.family
    .autoDispose<LatLng?, String>((ref, requestId) {
      final firestore = FirebaseFirestore.instance;

      return firestore.collection('requests').doc(requestId).snapshots().map((
        doc,
      ) {
        if (!doc.exists) return null;

        final data = doc.data();
        if (data == null) return null;

        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;

        if (latitude == null || longitude == null) return null;

        return LatLng(latitude, longitude);
      });
    });

final victimRequestsProvider =
    StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);

// Track which items are expanded
final expandedItemsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);

// Track the currently focused location (null means show all)
final focusedLocationProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
