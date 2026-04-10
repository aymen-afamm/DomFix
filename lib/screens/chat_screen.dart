import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

/// Chat screen for one-on-one communication between client and technician
/// Integrates with Firebase Firestore for real-time messaging
class ChatScreen extends StatefulWidget {
  final String otherUserId; // The other user's UID (client or technician)
  final String otherUserName; // Display name of other user
  final String? otherUserRole; // "client" or "technician"

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Services
  final ChatService _chatService = ChatService();
  
  // State
  late String _chatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Generate consistent chat ID using static method
    final currentUserId = _chatService.currentUserId;
    final otherUserId = widget.otherUserId;
    
    if (currentUserId.isEmpty) {
      debugPrint('[ChatScreen] ERROR: Current user not authenticated');
      return;
    }
    
    if (otherUserId.isEmpty) {
      debugPrint('[ChatScreen] ERROR: Other user ID is empty');
      return;
    }
    
    // CRITICAL: Use static method to ensure consistency
    _chatId = ChatService.generateChatId(currentUserId, otherUserId);
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('[ChatScreen] 💬 CHAT INITIALIZED');
    debugPrint('[ChatScreen] Current User: $currentUserId');
    debugPrint('[ChatScreen] Other User: $otherUserId');
    debugPrint('[ChatScreen] Generated Chat ID: $_chatId');
    debugPrint('[ChatScreen] Listening to: chats/$_chatId/messages');
    debugPrint('═══════════════════════════════════════');
    
    // Add listener to update UI when text changes
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Send text message to Firestore
  Future<void> _sendMessage() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('[ChatScreen] 🚀 SEND BUTTON CLICKED');
    debugPrint('═══════════════════════════════════════');
    
    // Validate input
    if (_messageController.text.trim().isEmpty) {
      debugPrint('[ChatScreen] ❌ Message is empty, not sending');
      return;
    }
    
    if (_isSending) {
      debugPrint('[ChatScreen] ⏳ Already sending, skipping');
      return;
    }

    final messageText = _messageController.text.trim();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    debugPrint('[ChatScreen] 📝 Message text: "$messageText"');
    debugPrint('[ChatScreen] 👤 Current user: $currentUserId');
    debugPrint('[ChatScreen] 👥 Receiver: ${widget.otherUserId}');
    debugPrint('[ChatScreen] 💬 Chat ID: $_chatId');
    
    // Clear input immediately for better UX
    _messageController.clear();
    
    setState(() => _isSending = true);

    try {
      debugPrint('[ChatScreen] 📤 Calling ChatService.sendMessage()...');
      
      // CRITICAL: sendMessage now generates chatId internally
      await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        text: messageText,
      );

      debugPrint('[ChatScreen] ✅ Message sent successfully!');
      debugPrint('═══════════════════════════════════════');
      
      // Auto-scroll to bottom after sending
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('[ChatScreen] ❌ ERROR SENDING MESSAGE');
      debugPrint('[ChatScreen] Error: $e');
      debugPrint('[ChatScreen] StackTrace: $stackTrace');
      debugPrint('═══════════════════════════════════════');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Restore message text on error
      _messageController.text = messageText;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Auto-scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildChatArea(),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  /// Header with back button and user info
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
            ),
            child: Icon(
              widget.otherUserRole == 'technician' 
                  ? Icons.engineering 
                  : Icons.person,
              color: AppColors.primaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // User name and role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (widget.otherUserRole != null)
                  Text(
                    widget.otherUserRole!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          // More options button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_vert,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Chat area with real-time messages using StreamBuilder
  Widget _buildChatArea() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessagesStream(_chatId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryContainer,
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // No messages yet
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        // Display messages
        final messages = snapshot.data!;
        
        return ListView.builder(
          controller: _scrollController,
          reverse: false, // Normal order since messages are ASC
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = message.isFromUser(_chatService.currentUserId);
            
            return _buildMessageBubble(message, isCurrentUser);
          },
        );
      },
    );
  }

  /// Message bubble widget
  Widget _buildMessageBubble(MessageModel message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.primaryContainer.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isCurrentUser 
                    ? const Radius.circular(16) 
                    : const Radius.circular(4),
                bottomRight: isCurrentUser 
                    ? const Radius.circular(4) 
                    : const Radius.circular(16),
              ),
              border: isCurrentUser
                  ? Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: _buildMessageContent(message),
          ),
          const SizedBox(height: 4),
          // Timestamp
          Text(
            message.getFormattedTime(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Message content based on type (text or audio)
  Widget _buildMessageContent(MessageModel message) {
    if (message.type == 'text' && message.text != null) {
      // Text message
      return Text(
        message.text!,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: AppColors.onSurface,
        ),
      );
    } else if (message.type == 'audio' && message.audioUrl != null) {
      // Audio message placeholder
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: AppColors.primaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Message',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '0:00',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Fallback for unknown message type
      return Text(
        'Unsupported message type',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    }
  }

  /// Input section with text field and send button
  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button (optional)
          GestureDetector(
            onTap: () {
              // TODO: Implement attachment functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachment feature coming soon'),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text input field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty || _isSending
                    ? AppColors.surfaceContainerHighest.withValues(alpha: 0.5)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _messageController.text.trim().isEmpty || _isSending
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.background,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _messageController.text.trim().isEmpty
                          ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
                          : AppColors.background,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
