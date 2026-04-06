import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TechnicianLocation {
  const TechnicianLocation({
    required this.id,
    required this.point,
    required this.updatedAt,
  });

  final String id;
  final LatLng point;
  final DateTime updatedAt;

  factory TechnicianLocation.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TechnicianLocation(
      id: doc.id,
      point: LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble()),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }
}

class TechnicianLocationService {
  static const _collection = 'technician_locations';
  static const _radiusKm = 10.0;
  static const _publishInterval = Duration(seconds: 5);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Timer? _publishTimer;

  // ── Technician side ──────────────────────────────────────────────────────

  Future<void> startPublishing() async {
    await _publishOnce();
    _publishTimer = Timer.periodic(_publishInterval, (_) => _publishOnce());
  }

  void stopPublishing() {
    _publishTimer?.cancel();
    _publishTimer = null;
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _firestore
          .collection(_collection)
          .doc(uid)
          .update({'online': false}).ignore();
    }
  }

  Future<void> _publishOnce() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _firestore.collection(_collection).doc(uid).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'online': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── User side ────────────────────────────────────────────────────────────

  /// Emits only online technicians within [_radiusKm] of [userPoint].
  Stream<List<TechnicianLocation>> nearbyStream(LatLng userPoint) {
    return _firestore
        .collection(_collection)
        .where('online', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(TechnicianLocation.fromDoc)
            .where((t) => _distanceKm(userPoint, t.point) <= _radiusKm)
            .toList());
  }

  static double distanceKmPublic(LatLng a, LatLng b) => _distanceKm(a, b);

  static double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) *
            cos(_rad(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _rad(double deg) => deg * pi / 180;
}
