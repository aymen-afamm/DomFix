import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for chat messages
/// Supports text, audio, image, and file message types
/// Includes WhatsApp-like read/unread functionality
class MessageModel {
  final String id;
  final String senderId;
  final String type; // "text", "audio", "image", "file"
  final String? text;
  final String? audioUrl;
  final String? fileUrl; // For images and files
  final String? fileName; // Original file name
  final int? duration; // Audio duration in seconds
  final DateTime createdAt;
  final bool isSeen;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.duration,
    required this.createdAt,
    this.isSeen = false,
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
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      duration: data['duration'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSeen: data['isSeen'] ?? false,
    );
  }

  /// Convert MessageModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type,
      'text': text,
      'audioUrl': audioUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
      'isSeen': isSeen,
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

  /// Get formatted duration for audio messages
  String getFormattedDuration() {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get file extension from fileName
  String? getFileExtension() {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : null;
  }
}
