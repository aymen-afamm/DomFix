import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/message_model.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/image_message_widget.dart';
import '../widgets/file_message_widget.dart';

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
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // State
  late String _chatId;
  late Stream<List<MessageModel>> _messagesStream;
  bool _isSending = false;
  bool _isRecording = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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
    
    // CRITICAL: Initialize stream ONCE in initState to prevent recreation on rebuild
    _messagesStream = _chatService.getMessagesStream(_chatId);
    
    debugPrint('═══════════════════════════════════════');
    debugPrint('[ChatScreen] 💬 CHAT INITIALIZED');
    debugPrint('[ChatScreen] Current User: $currentUserId');
    debugPrint('[ChatScreen] Other User: $otherUserId');
    debugPrint('[ChatScreen] Generated Chat ID: $_chatId');
    debugPrint('[ChatScreen] Listening to: chats/$_chatId/messages');
    debugPrint('[ChatScreen] Stream initialized and cached');
    debugPrint('═══════════════════════════════════════');
    
    // Add listener to update UI when text changes
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    
    // ✅ NEW: Mark messages as seen when opening chat
    _markMessagesAsSeenAndResetCount();
    
    // Run diagnostic test after 3 seconds to allow UI to settle
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        debugPrint('[ChatScreen] 🔍 Running diagnostic test...');
        _chatService.diagnosticChatAccess(_chatId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ NEW: Mark messages as seen and reset unread count
  /// Called when user opens ChatScreen
  Future<void> _markMessagesAsSeenAndResetCount() async {
    try {
      // Mark all messages from other user as seen
      await _chatService.markMessagesAsSeen(
        chatId: _chatId,
        otherUserId: widget.otherUserId,
      );
      
      // Reset unread count for current user
      await _chatService.resetUnreadCount(_chatId);
      
      debugPrint('[ChatScreen] ✅ Messages marked as seen and unread count reset');
    } catch (e) {
      debugPrint('[ChatScreen] ❌ Error marking messages as seen: $e');
    }
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
      stream: _messagesStream, // Use cached stream
      builder: (context, snapshot) {
        // Log connection state changes
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          debugPrint('[ChatScreen] 🔄 StreamBuilder: Initial loading');
        } else if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          debugPrint('[ChatScreen] 🔄 StreamBuilder: Active with ${snapshot.data!.length} messages');
        }
        
        if (snapshot.hasError) {
          debugPrint('[ChatScreen] ❌ StreamBuilder Error: ${snapshot.error}');
        }
        
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
          debugPrint('[ChatScreen] ❌ Showing error state');
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
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
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
          // ✅ NEW: Timestamp with WhatsApp-like checkmarks
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.getFormattedTime(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              // ✅ NEW: Show checkmarks for sent messages
              if (isCurrentUser) ...[
                const SizedBox(width: 4),
                _buildSeenIndicator(message.isSeen),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ NEW: WhatsApp-like seen indicator
  /// Shows ✓ (sent) or ✓✓ (seen with blue color)
  Widget _buildSeenIndicator(bool isSeen) {
    return Icon(
      Icons.done_all, // Double checkmark
      size: 14,
      color: isSeen 
          ? const Color(0xFF00A5F4) // WhatsApp blue
          : AppColors.onSurfaceVariant.withValues(alpha: 0.4), // Gray
    );
  }

  /// Message content based on type (text, audio, image, file)
  Widget _buildMessageContent(MessageModel message) {
    switch (message.type) {
      case 'text':
        return Text(
          message.text ?? '',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.onSurface,
          ),
        );
      
      case 'audio':
        return AudioPlayerWidget(
          audioUrl: message.audioUrl ?? message.fileUrl ?? '',
          duration: message.duration,
          isCurrentUser: message.isFromUser(_chatService.currentUserId),
        );
      
      case 'image':
        return ImageMessageWidget(
          imageUrl: message.fileUrl ?? '',
          isCurrentUser: message.isFromUser(_chatService.currentUserId),
        );
      
      case 'file':
        return FileMessageWidget(
          fileUrl: message.fileUrl ?? '',
          fileName: message.fileName ?? 'Unknown file',
          isCurrentUser: message.isFromUser(_chatService.currentUserId),
        );
      
      default:
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
    // Show audio recorder when recording
    if (_isRecording) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AudioRecorderWidget(
          onAudioRecorded: _handleAudioRecorded,
          onCancel: () => setState(() => _isRecording = false),
        ),
      );
    }

    // Show upload progress
    if (_isUploading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: _uploadProgress,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 16),
            Text(
              'Uploading... ${(_uploadProgress * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      );
    }

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
          // Attachment button
          GestureDetector(
            onTap: _showMediaOptions,
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
          // Mic or Send button
          GestureDetector(
            onTap: _messageController.text.trim().isEmpty
                ? () => setState(() => _isRecording = true)
                : (_isSending ? null : _sendMessage),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.surfaceContainerHighest.withValues(alpha: 0.5)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isSending
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
                      _messageController.text.trim().isEmpty
                          ? Icons.mic
                          : Icons.send_rounded,
                      color: AppColors.background,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show media options bottom sheet
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMediaOption(
              icon: Icons.photo_library,
              label: 'Photo',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 12),
            _buildMediaOption(
              icon: Icons.insert_drive_file,
              label: 'File',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle audio recording completion
  Future<void> _handleAudioRecorded(File audioFile, int duration) async {
    setState(() {
      _isRecording = false;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload audio to Firebase Storage
      final audioUrl = await _storageService.uploadAudio(
        chatId: _chatId,
        audioFile: audioFile,
      );

      // Send audio message
      await _chatService.sendAudioMessage(
        receiverId: widget.otherUserId,
        audioUrl: audioUrl,
        duration: duration,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        await _sendImageMessage(File(image.path), image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        await _sendImageMessage(File(photo.path), photo.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  /// Pick file
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        await _sendFileMessage(file, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  /// Send image message
  Future<void> _sendImageMessage(File imageFile, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadImage(
        chatId: _chatId,
        imageFile: imageFile,
        compress: true,
      );

      // Send image message
      await _chatService.sendImageMessage(
        receiverId: widget.otherUserId,
        imageUrl: imageUrl,
        fileName: fileName,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Send file message
  Future<void> _sendFileMessage(File file, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload file to Firebase Storage
      final fileUrl = await _storageService.uploadFile(
        chatId: _chatId,
        file: file,
        fileName: fileName,
      );

      // Send file message
      await _chatService.sendFileMessage(
        receiverId: widget.otherUserId,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
