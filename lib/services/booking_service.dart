import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/booking_model.dart';
import 'chat_service.dart';

class BookingService {
  BookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const List<String> _fallbackServices = [
    'Electrical Repair',
    'Smart Home Installation',
    'IoT Setup',
    'Wiring',
    'Maintenance',
  ];

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<List<String>> loadTechnicianServices(String technicianId) async {
    final doc = await _firestore.collection('users').doc(technicianId).get();
    final data = doc.data() ?? {};
    final rawServices = [
      ..._readStringList(data['services']),
      ..._readStringList(data['specialties']),
      ..._readStringList(data['customSkills']),
      if ((data['speciality'] as String?)?.trim().isNotEmpty == true)
        (data['speciality'] as String).trim(),
      if ((data['job'] as String?)?.trim().isNotEmpty == true)
        (data['job'] as String).trim(),
    ];

    final services = <String>[];
    for (final item in rawServices) {
      if (!services.contains(item)) services.add(item);
    }
    return services.isEmpty ? _fallbackServices : services.take(8).toList();
  }

  Stream<Set<String>> watchUnavailableSlots({
    required String technicianId,
    required DateTime date,
  }) {
    return _simulatedAvailabilityStream(date);
  }

  Future<bool> hasBookingBetween(String otherUserId) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) return false;
    final chatId = ChatService.generateChatId(currentUserId, otherUserId);
    final doc = await _firestore.collection('chats').doc(chatId).get();
    final data = doc.data();
    return data?['fullChatUnlocked'] == true ||
        (data?['activeBookingId'] as String?)?.isNotEmpty == true;
  }

  Stream<bool> watchBookingAccess(String otherUserId) {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      return Stream<bool>.value(false);
    }
    final chatId = ChatService.generateChatId(currentUserId, otherUserId);
    return _firestore.collection('chats').doc(chatId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return data?['fullChatUnlocked'] == true ||
          (data?['activeBookingId'] as String?)?.isNotEmpty == true;
    });
  }

  BookingEstimate estimate({required String service, required String urgency}) {
    final lower = service.toLowerCase();
    var duration = 75;
    var base = 70;

    if (lower.contains('smart') || lower.contains('iot')) {
      duration = 120;
      base = 110;
    } else if (lower.contains('wiring') || lower.contains('electrical')) {
      duration = 90;
      base = 95;
    } else if (lower.contains('maintenance')) {
      duration = 60;
      base = 65;
    }

    final urgencyMultiplier = switch (urgency) {
      'Urgent' => 1.25,
      'Emergency' => 1.55,
      _ => 1.0,
    };
    final technicianFee = (base * urgencyMultiplier).round();
    final platformFee = math.max(8, (technicianFee * 0.12).round());
    final minPrice = technicianFee + platformFee;
    final maxPrice = minPrice + (duration / 3).round();

    return BookingEstimate(
      durationMinutes: duration,
      minPrice: minPrice,
      maxPrice: maxPrice,
      technicianFee: technicianFee,
      platformFee: platformFee,
    );
  }

  Future<String> uploadBookingImage({
    required String bookingId,
    required File imageFile,
  }) async {
    final extension = path.extension(imageFile.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final ref = _storage.ref().child('bookings/$bookingId/images/$fileName');
    final task = await ref.putFile(imageFile);
    return task.ref.getDownloadURL();
  }

  Future<String> createBooking(BookingDraft draft) async {
    if (currentUserId.isEmpty) throw Exception('User not authenticated');

    final chatId = ChatService.generateChatId(
      currentUserId,
      draft.technicianId,
    );
    final bookingRef = draft.bookingId == null
        ? _firestore.collection('bookings').doc()
        : _firestore.collection('bookings').doc(draft.bookingId);
    final bookingId = bookingRef.id;
    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);

    final bookingData = {
      'bookingId': bookingId,
      'clientId': currentUserId,
      'technicianId': draft.technicianId,
      'participants': [currentUserId, draft.technicianId],
      'technicianName': draft.technicianName,
      'pairKey': chatId,
      'chatId': chatId,
      'service': draft.service,
      'scheduledAt': Timestamp.fromDate(draft.scheduledAt),
      'scheduledDateKey': dateKeyFor(draft.scheduledAt),
      'timeSlot': draft.timeSlot,
      'description': draft.description,
      'urgency': draft.urgency,
      'status': 'pending',
      'imageUrls': draft.imageUrls,
      'estimate': draft.estimate.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(bookingRef, bookingData);
    batch.set(chatRef, {
      'participants': [currentUserId, draft.technicianId],
      'lastMessage': 'Booking request created for ${draft.service}',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'fullChatUnlocked': true,
      'activeBookingId': bookingId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    await _mirrorBookingToLegacyJob(
      bookingId: bookingId,
      draft: draft,
    );

    debugPrint('[BookingService] Created booking $bookingId');
    return bookingId;
  }

  Future<void> _mirrorBookingToLegacyJob({
    required String bookingId,
    required BookingDraft draft,
  }) async {
    try {
      await _firestore.collection('jobs').doc(bookingId).set({
      'jobId': bookingId,
      'bookingId': bookingId,
      'userId': currentUserId,
      'clientId': currentUserId,
      'technicianId': draft.technicianId,
      'problemDescription': draft.description,
      'service': draft.service,
      'urgency': draft.urgency,
      'status': 'pending',
      'estimatedPrice': '${draft.estimate.minPrice}-${draft.estimate.maxPrice}',
      'scheduledAt': Timestamp.fromDate(draft.scheduledAt),
      'timeSlot': draft.timeSlot,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[BookingService] Legacy jobs mirror skipped: $e');
    }
  }

  static String dateKeyFor(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static List<String> timeSlotsFor(DateTime date) {
    final slots = <String>[];
    for (var hour = 8; hour <= 18; hour += 2) {
      slots.add(_formatHour(hour));
    }
    return slots.where((slot) {
      final slotDate = combineDateAndSlot(date, slot);
      return slotDate.isAfter(DateTime.now().add(const Duration(minutes: 15)));
    }).toList();
  }

  static DateTime combineDateAndSlot(DateTime date, String slot) {
    final isPm = slot.toUpperCase().contains('PM');
    final number = int.tryParse(slot.split(':').first) ?? 8;
    var hour = number;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour);
  }

  static List<String> simulatedUnavailableSlots(DateTime date) {
    final all = timeSlotsFor(date);
    if (all.isEmpty) return const [];
    final seed = date.year + date.month * 17 + date.day * 31;
    return all
        .where((slot) => (slot.hashCode + seed).abs() % 5 == 0)
        .take(2)
        .toList();
  }

  Stream<Set<String>> _simulatedAvailabilityStream(DateTime date) async* {
    var tick = 0;
    while (true) {
      final slots = simulatedUnavailableSlots(
        date.add(Duration(minutes: tick)),
      ).toSet();
      yield slots;
      tick += 1;
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  static String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : hour;
    return '$display:00 $period';
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
