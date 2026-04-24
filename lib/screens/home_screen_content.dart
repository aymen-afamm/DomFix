import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import 'main_layout.dart';
import 'chat_screen.dart';
import 'ai_chat_screen.dart';
import 'technician_profile_screen.dart';

/// HomeScreenContent — Clean, minimal redesign.
/// Sections: Hero → Primary CTA → Quick Actions → Nearby Techs → Recent Messages
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});
  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userName = '';
  String? _userPhotoUrl;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initLocation();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = await _userService.getUserData(user.uid);
    if (!mounted) return;
    setState(() {
      _userName = data?['name'] ?? user.displayName ?? user.email?.split('@').first ?? 'User';
      _userPhotoUrl = data?['profileImage'] ?? user.photoURL;
    });
  }

  Future<void> _initLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('cachedLat');
      final cachedLng = prefs.getDouble('cachedLng');
      if (cachedLat != null && cachedLng != null && mounted) {
        setState(() { _userLat = cachedLat; _userLng = cachedLng; });
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await prefs.setDouble('cachedLat', position.latitude);
      await prefs.setDouble('cachedLng', position.longitude);
      if (mounted) {
        setState(() { _userLat = position.latitude; _userLng = position.longitude; });
      }
    } catch (e) {
      print("Location error: $e");
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
        (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.neonAccent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await _loadUserData();
          await _initLocation();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildPrimaryAction(),
                  const SizedBox(height: 24),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 32),
                  _buildNearbyTechniciansSection(),
                  const SizedBox(height: 32),
                  _buildRecentMessagesSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ───────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
      color: AppColors.background,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipOval(
              child: _userPhotoUrl != null
                  ? Image.network(_userPhotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant))
                  : Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DomFix',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }

  // ─── HERO SECTION ──────────────────────────────────────
  Widget _buildHeroSection() {
    return Text.rich(
      TextSpan(
        text: 'What do you need\nhelp with',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 28, fontWeight: FontWeight.w700, height: 1.2,
          color: AppColors.onSurface, letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: _userName.isNotEmpty ? ', $_userName?' : '?',
            style: TextStyle(color: AppColors.neonAccent),
          ),
        ],
      ),
    );
  }

  // ─── PRIMARY CTA ───────────────────────────────────────
  Widget _buildPrimaryAction() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.neonAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bolt_rounded, color: AppColors.onPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Describe your issue',
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
                  const SizedBox(height: 2),
                  Text('AI will diagnose it instantly',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onPrimary.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: AppColors.onPrimary, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ─────────────────────────────────────
  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        Expanded(child: _QuickActionCard(
          icon: Icons.home_rounded, title: 'Smart Home',
          subtitle: 'Control devices',
          onTap: () => MainLayoutScope.maybeOf(context)?.selectTab(3),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(
          icon: Icons.psychology_rounded, title: 'Ask AI',
          subtitle: 'Get instant help',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
        )),
      ],
    );
  }

  // ─── NEARBY TECHNICIANS ────────────────────────────────
  Widget _buildNearbyTechniciansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nearby Technicians',
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            GestureDetector(
              onTap: () => MainLayoutScope.maybeOf(context)?.selectTab(2),
              child: Text('See all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neonAccent)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _userLat == null || _userLng == null
            ? _buildSkeletonCards()
            : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .where('role', isEqualTo: 'technician')
                  .where('isOnline', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonCards();
                if (snapshot.hasError) return _buildEmptyState('Error loading technicians', Icons.error_outline);
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No technicians nearby', Icons.engineering_outlined);

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> nearbyTechs = [];
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dynamic techLatRaw = data['lat'] ?? data['location']?['lat'];
                  final dynamic techLngRaw = data['lng'] ?? data['location']?['lng'];
                  if (techLatRaw == null || techLngRaw == null) continue;
                  final techLat = (techLatRaw as num).toDouble();
                  final techLng = (techLngRaw as num).toDouble();
                  final distance = _calculateDistance(_userLat!, _userLng!, techLat, techLng);
                  if (distance <= 10) {
                    data['calculated_distance'] = distance;
                    data['doc_id'] = doc.id;
                    nearbyTechs.add(data);
                  }
                }
                nearbyTechs.sort((a, b) {
                  final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
                  final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
                  return ratingB.compareTo(ratingA);
                });
                final finalList = nearbyTechs.take(4).toList();

                if (finalList.isEmpty) return _buildEmptyState('No technicians nearby', Icons.engineering_outlined);

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: finalList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final data = finalList[index];
                    final techId = data['doc_id'] as String;
                    final fullName = data['fullName'] ?? data['name'] ?? 'Technician';
                    return _TechnicianCard(
                      techId: techId, name: fullName,
                      job: data['speciality'] ?? _extractJob(data),
                      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
                      distance: data['calculated_distance'] as double,
                      photoUrl: data['profileImage'],
                      isAvailable: data['isOnline'] == true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TechnicianProfileScreen(technicianId: techId, initialName: fullName),
                      )),
                    );
                  },
                );
              },
            ),
        ),
      ],
    );
  }

  String _extractJob(Map<String, dynamic> data) {
    if (data['job'] != null) return data['job'];
    if (data['specialties'] != null && data['specialties'] is List) {
      final list = data['specialties'] as List;
      if (list.isNotEmpty) return list.first.toString();
    }
    return 'Technician';
  }

  // ─── RECENT MESSAGES ───────────────────────────────────
  Widget _buildRecentMessagesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Messages',
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            GestureDetector(
              onTap: () => MainLayoutScope.maybeOf(context)?.selectTab(1),
              child: Text('View all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neonAccent)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _chatService.getUserChats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildMessageSkeletons();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyMessages();
            }
            final chats = snapshot.data!.docs.take(3).toList();
            return Column(
              children: chats.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _RecentMessageTile(
                  chatData: data,
                  currentUserId: _auth.currentUser?.uid ?? '',
                  onTap: (otherId, otherName) => _navigateToChat(otherId, otherName),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageSkeletons() {
    return Column(
      children: List.generate(2, (_) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildEmptyMessages() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 32, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('No messages yet',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCards() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => _ShimmerBox(
        child: Container(
          width: 200, decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _navigateToChat(String otherUserId, String otherUserName) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(otherUserId: otherUserId, otherUserName: otherUserName, otherUserRole: 'technician'),
    ));
  }
}

// ═════════════════════════════════════════════════════════
//  EXTRACTED WIDGETS
// ═════════════════════════════════════════════════════════

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.neonAccent, size: 24),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final String techId, name, job;
  final double rating, distance;
  final String? photoUrl;
  final bool isAvailable;
  final VoidCallback onTap;

  const _TechnicianCard({
    required this.techId, required this.name, required this.job,
    required this.rating, required this.distance, this.photoUrl,
    required this.isAvailable, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceContainerHigh),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoUrl != null
                        ? Image.network(photoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatar())
                        : _defaultAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(job, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Rating + Distance
            Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: AppColors.neonAccent),
                const SizedBox(width: 3),
                Text(rating.toStringAsFixed(1),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const Spacer(),
                Icon(Icons.location_on_outlined, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 2),
                Text('${distance.toStringAsFixed(1)} km',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neonAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('View Profile',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(child: Icon(Icons.engineering_rounded, color: AppColors.onSurfaceVariant, size: 22)),
    );
  }
}

class _RecentMessageTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final void Function(String otherId, String otherName) onTap;

  const _RecentMessageTile({required this.chatData, required this.currentUserId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnap) {
        final name = userSnap.data?.exists == true
            ? ((userSnap.data!.data() as Map<String, dynamic>)['name'] ?? 'User') : 'User';
        final photoUrl = userSnap.data?.exists == true
            ? (userSnap.data!.data() as Map<String, dynamic>)['profileImage'] : null;
        final lastMessage = chatData['lastMessage'] ?? '';
        final timestamp = chatData['lastMessageTime'] as Timestamp?;
        final timeStr = _formatTime(timestamp);

        return GestureDetector(
          onTap: () => onTap(otherUserId, name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerHigh),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatar(name))
                        : _avatar(name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(name,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(timeStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(lastMessage,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avatar(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neonAccent)),
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      final h = d.hour > 12 ? d.hour - 12 : d.hour;
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '${h == 0 ? 12 : h}:${d.minute.toString().padLeft(2, '0')} $p';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _ShimmerBox extends StatefulWidget {
  final Widget child;
  const _ShimmerBox({required this.child});
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: 0.4 + _anim.value * 0.3, child: child),
      child: widget.child,
    );
  }
}
