import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for chat messages
/// Supports text and audio message types
/// Includes WhatsApp-like read/unread functionality
class MessageModel {
  final String id;
  final String senderId;
  final String type; // "text" or "audio"
  final String? text;
  final String? audioUrl;
  final DateTime createdAt;
  final bool isSeen; // ✅ NEW: WhatsApp-like seen status

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.audioUrl,
    required this.createdAt,
    this.isSeen = false, // Default to false (unread)
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? 'text',
      text: data['text'],
      audioUrl: data['audioUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSeen: data['isSeen'] ?? false, // ✅ NEW: Read seen status from Firestore
    );
  }

  /// Convert MessageModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type,
      'text': text,
      'audioUrl': audioUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isSeen': isSeen, // ✅ NEW: Include seen status
    };
  }

  /// Check if message is from current user
  bool isFromUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Get formatted time (e.g., "09:41 AM")
  String getFormattedTime() {
    final hour = createdAt.hour > 12 ? createdAt.hour - 12 : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
