import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

/// ChatService handles all Firestore operations for chat functionality
/// Provides methods for sending messages, retrieving messages, and managing chats
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Generate consistent chat ID for two users
  /// Always returns the same ID regardless of parameter order
  /// Example: generateChatId("user1", "user2") == generateChatId("user2", "user1")
  String generateChatId(String uid1, String uid2) {
    // Sort UIDs alphabetically to ensure consistency
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  /// Send a text message
  /// Creates chat document if it doesn't exist
  /// Updates lastMessage and lastMessageTime in chat document
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Create message document
      final messageData = {
        'senderId': currentUserId,
        'type': 'text',
        'text': text.trim(),
        'audioUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update or create chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[ChatService] Message sent successfully');
    } catch (e) {
      debugPrint('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  /// Send an audio message
  /// Similar to sendMessage but for audio type
  Future<void> sendAudioMessage({
    required String chatId,
    required String receiverId,
    required String audioUrl,
  }) async {
    try {
      if (audioUrl.trim().isEmpty) {
        throw Exception('Audio URL cannot be empty');
      }

      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Create audio message document
      final messageData = {
        'senderId': currentUserId,
        'type': 'audio',
        'text': null,
        'audioUrl': audioUrl.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': '🎤 Audio message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[ChatService] Audio message sent successfully');
    } catch (e) {
      debugPrint('[ChatService] Error sending audio message: $e');
      rethrow;
    }
  }

  /// Get real-time stream of messages for a chat
  /// Returns messages ordered by createdAt in descending order (newest first)
  /// Use with StreamBuilder for real-time updates
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Check if chat exists
  Future<bool> chatExists(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[ChatService] Error checking chat existence: $e');
      return false;
    }
  }

  /// Get chat document
  Future<DocumentSnapshot?> getChat(String chatId) async {
    try {
      return await _firestore.collection('chats').doc(chatId).get();
    } catch (e) {
      debugPrint('[ChatService] Error getting chat: $e');
      return null;
    }
  }

  /// Create initial chat document
  /// Useful for creating chat before first message
  Future<void> createChat({
    required String chatId,
    required String otherUserId,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      debugPrint('[ChatService] Chat created successfully');
    } catch (e) {
      debugPrint('[ChatService] Error creating chat: $e');
      rethrow;
    }
  }

  /// Get all chats for current user
  /// Returns stream of chats where user is a participant
  Stream<QuerySnapshot> getUserChats() {
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      debugPrint('[ChatService] Message deleted successfully');
    } catch (e) {
      debugPrint('[ChatService] Error deleting message: $e');
      rethrow;
    }
  }
}
