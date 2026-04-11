import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

/// Professional Messages/Chat List Screen
/// Displays real-time conversations from Firestore
/// Design inspired by WhatsApp/Instagram/Messenger
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('═══════════════════════════════════════');
    debugPrint('[💬 MessagesScreen] INITIALIZED');
    debugPrint('[💬 MessagesScreen] Current User: ${_auth.currentUser?.uid}');
    debugPrint('[💬 MessagesScreen] User Email: ${_auth.currentUser?.email}');
    debugPrint('═══════════════════════════════════════');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildActiveNowSection()),
                  _buildChatList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top App Bar with Menu and Search icons
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.menu,
                  color: AppColors.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                'Messages',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonAccent,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              color: AppColors.onSurface,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Active Now / Stories Section (removed fake users)
  Widget _buildActiveNowSection() {
    return const SizedBox.shrink(); // Remove fake users section
  }

  /// Chat List with real-time Firestore data
  Widget _buildChatList() {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'Please login to view messages',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(),
      builder: (context, snapshot) {
        // Debug logging
        if (snapshot.connectionState == ConnectionState.active) {
          debugPrint('[💬 MessagesScreen] 🔄 Stream active: ${snapshot.hasData ? snapshot.data!.docs.length : 0} chats');
        }
        
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading chats',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                ),
              ),
            ),
          );
        }

        // No chats
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with technicians',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter chats by search query
        final chats = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final lastMessage = (data['lastMessage'] as String? ?? '').toLowerCase();
          return lastMessage.contains(_searchQuery);
        }).toList();

        if (chats.isEmpty && _searchQuery.isNotEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No results found',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chatDoc = chats[index];
                final chatData = chatDoc.data() as Map<String, dynamic>;
                final chatId = chatDoc.id;

                return _ChatListItem(
                  chatId: chatId,
                  chatData: chatData,
                  currentUserId: currentUserId,
                  chatService: _chatService, // ✅ NEW: Pass ChatService
                );
              },
              childCount: chats.length,
            ),
          ),
        );
      },
    );
  }
}

/// Individual Chat List Item
/// Fetches other user's data and displays chat preview
/// ✅ NEW: Shows WhatsApp-like unread count badge
class _ChatListItem extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final ChatService chatService; // ✅ NEW

  const _ChatListItem({
    required this.chatId,
    required this.chatData,
    required this.currentUserId,
    required this.chatService, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        // Loading
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildChatItemSkeleton();
        }

        // Error or no data
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return _buildChatItem(
            context: context,
            name: 'Unknown User',
            photoUrl: null,
            lastMessage: chatData['lastMessage'] ?? '',
            timestamp: chatData['lastMessageTime'],
            isUnread: false,
            unreadCount: 0, // ✅ FIX: Added missing parameter
            otherUserId: otherUserId,
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final name = userData['name'] ?? userData['email'] ?? 'Unknown';
        final photoUrl = userData['profileImage'] ?? userData['photoUrl'];

        // ✅ NEW: Get unread count from ChatService
        final unreadCount = chatService.getUnreadCount(chatData);
        final isUnread = unreadCount > 0;

        return _buildChatItem(
          context: context,
          name: name,
          photoUrl: photoUrl,
          lastMessage: chatData['lastMessage'] ?? '',
          timestamp: chatData['lastMessageTime'],
          isUnread: isUnread,
          unreadCount: unreadCount, // ✅ NEW: Pass unread count
          otherUserId: otherUserId,
        );
      },
    );
  }

  bool _isUnread(Map<String, dynamic> chatData) {
    // ✅ DEPRECATED: Now using unreadCount from Firestore
    return chatData['unread'] == true;
  }

  Widget _buildChatItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required String name,
    String? photoUrl,
    required String lastMessage,
    Timestamp? timestamp,
    required bool isUnread,
    required int unreadCount, // ✅ NEW: Unread count parameter
    required String otherUserId,
  }) {
    final timeString = _formatTimestamp(timestamp);

    return InkWell(
      onTap: () {
        // Debug logging
        debugPrint('═══════════════════════════════════════');
        debugPrint('[💬 MessagesScreen] 👆 Chat tapped');
        debugPrint('[💬 MessagesScreen] Other User ID: $otherUserId');
        debugPrint('[💬 MessagesScreen] Other User Name: $name');
        debugPrint('[💬 MessagesScreen] Navigating to ChatScreen...');
        debugPrint('═══════════════════════════════════════');
        
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: name,
              otherUserRole: 'user', // Can be enhanced
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(name);
                            },
                          )
                        : _buildDefaultAvatar(name),
                  ),
                ),
                // Online indicator (can be enhanced with real online status)
                if (isUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeString,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isUnread
                              ? AppColors.primaryContainer
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                            color: isUnread
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ✅ NEW: WhatsApp-like unread count badge
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonAccent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonAccent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B0F14), // Dark background color
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryContainer,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      // Older - show date
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
