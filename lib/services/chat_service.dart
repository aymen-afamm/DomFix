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
  /// CRITICAL: Always returns the same ID regardless of parameter order
  /// This is the SINGLE SOURCE OF TRUTH for chatId generation
  /// Example: generateChatId("user1", "user2") == generateChatId("user2", "user1")
  static String generateChatId(String uid1, String uid2) {
    if (uid1.isEmpty || uid2.isEmpty) {
      throw Exception('Cannot generate chatId with empty UIDs');
    }
    if (uid1 == uid2) {
      throw Exception('Cannot create chat with same user');
    }
    // Sort UIDs alphabetically to ensure consistency
    final sortedUids = [uid1, uid2]..sort();
    final chatId = '${sortedUids[0]}_${sortedUids[1]}';
    debugPrint('[ChatService] Generated chatId: $chatId from [$uid1, $uid2]');
    return chatId;
  }

  /// Send a text message
  /// CRITICAL: Uses static generateChatId to ensure consistency
  /// Creates chat document BEFORE sending message to avoid permission errors
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[ChatService] 🚀 sendMessage() CALLED');
      
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint('[ChatService] ❌ Validation failed: Message is empty');
        throw Exception('Message cannot be empty');
      }

      if (currentUserId.isEmpty) {
        debugPrint('[ChatService] ❌ Validation failed: User not authenticated');
        throw Exception('User not authenticated');
      }

      if (receiverId.isEmpty) {
        debugPrint('[ChatService] ❌ Validation failed: Receiver ID is empty');
        throw Exception('Receiver ID is empty');
      }

      debugPrint('[ChatService] ✅ Validation passed');

      // CRITICAL: Use static method to generate consistent chatId
      final chatId = ChatService.generateChatId(currentUserId, receiverId);

      // Debug logs
      debugPrint('[ChatService] 💬 Chat Details:');
      debugPrint('[ChatService]   Current User: $currentUserId');
      debugPrint('[ChatService]   Receiver: $receiverId');
      debugPrint('[ChatService]   Chat ID: $chatId');
      debugPrint('[ChatService]   Message: "${text.trim()}"');
      debugPrint('[ChatService]   Firestore Path: chats/$chatId');
      debugPrint('[ChatService]   Messages Path: chats/$chatId/messages');

      // STEP 1: Create/update chat document FIRST
      debugPrint('[ChatService] 💾 STEP 1: Creating/updating chat document...');
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      final chatData = {
        'participants': [currentUserId, receiverId],
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('[ChatService] Chat data: $chatData');
      
      await chatRef.set(chatData, SetOptions(merge: true));

      debugPrint('[ChatService] ✅ Chat document created/updated successfully');

      // STEP 2: Add message to subcollection
      debugPrint('[ChatService] 💾 STEP 2: Adding message to subcollection...');
      
      final messageData = {
        'senderId': currentUserId,
        'type': 'text',
        'text': text.trim(),
        'audioUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('[ChatService] Message data: $messageData');

      final messageRef = await chatRef.collection('messages').add(messageData);
      
      debugPrint('[ChatService] ✅ Message added successfully!');
      debugPrint('[ChatService] Message ID: ${messageRef.id}');
      debugPrint('[ChatService] Full path: chats/$chatId/messages/${messageRef.id}');
      debugPrint('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[ChatService] ❌ ERROR IN sendMessage()');
      debugPrint('[ChatService] Error: $e');
      debugPrint('[ChatService] StackTrace: $stackTrace');
      debugPrint('═══════════════════════════════════════');
      rethrow;
    }
  }

  /// Send an audio message
  /// CRITICAL: Uses static generateChatId to ensure consistency
  Future<void> sendAudioMessage({
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

      // CRITICAL: Use static method to generate consistent chatId
      final chatId = ChatService.generateChatId(currentUserId, receiverId);

      // Debug logs
      debugPrint('[ChatService] Sending audio message');
      debugPrint('[ChatService] Chat ID: $chatId');

      // CRITICAL: Create/update chat document FIRST
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      await chatRef.set({
        'participants': [currentUserId, receiverId],
        'lastMessage': '🎤 Audio message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[ChatService] Chat document created/updated');

      // Create audio message document
      final messageData = {
        'senderId': currentUserId,
        'type': 'audio',
        'text': null,
        'audioUrl': audioUrl.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await chatRef.collection('messages').add(messageData);

      debugPrint('[ChatService] Audio message sent successfully');
    } catch (e) {
      debugPrint('[ChatService] Error sending audio message: $e');
      rethrow;
    }
  }

  /// Get real-time stream of messages for a chat
  /// Returns messages ordered by createdAt in ascending order (oldest first)
  /// Use with StreamBuilder for real-time updates
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    debugPrint('[ChatService] 👂 Listening to messages for chatId: $chatId');
    debugPrint('[ChatService] Path: chats/$chatId/messages');
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('[ChatService] 📬 Received ${snapshot.docs.length} messages');
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
    required String otherUserId,
  }) async {
    try {
      // CRITICAL: Use static method to generate consistent chatId
      final chatId = ChatService.generateChatId(currentUserId, otherUserId);
      
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[ChatService] Chat created successfully: $chatId');
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
