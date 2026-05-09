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
import '../widgets/home_widgets.dart';
import 'main_layout.dart';
import 'chat_screen.dart';
import 'ai_chat_screen.dart';
import 'technician_profile_screen.dart';


/// HomeScreenContent — Premium UI matching HTML/Tailwind reference design.
/// Sections: TopBar → Hero → Primary CTA → Quick Actions → Suggestions → Technicians → Environment → Messages
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});
  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> with AutomaticKeepAliveClientMixin {
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
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await prefs.setDouble('cachedLat', position.latitude);
      await prefs.setDouble('cachedLng', position.longitude);
      if (mounted) setState(() { _userLat = position.latitude; _userLng = position.longitude; });
    } catch (e) { debugPrint("Location error: $e"); }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  String _extractJob(Map<String, dynamic> data) {
    if (data['speciality'] != null) return data['speciality'];
    if (data['job'] != null) return data['job'];
    if (data['specialties'] != null && data['specialties'] is List) {
      final list = data['specialties'] as List;
      if (list.isNotEmpty) return list.first.toString();
    }
    return 'Technician';
  }

  String get _firstName {
    if (_userName.isEmpty) return 'User';
    return _userName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.neonAccent,
        backgroundColor: AppColors.surface,
        onRefresh: () async { await _loadUserData(); await _initLocation(); },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _buildHeroSection(),
                const SizedBox(height: 32),
                _buildPrimaryAction(),
                const SizedBox(height: 28),
                _buildQuickActionsGrid(),
                const SizedBox(height: 36),
                _buildSuggestionsSection(),
                const SizedBox(height: 36),
                _buildNearbyTechniciansSection(),
                const SizedBox(height: 36),
                _buildActiveEnvironment(),
                const SizedBox(height: 36),
                _buildRecentMessagesSection(),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR (HTML: fixed header) ─────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101419).withValues(alpha: 0.60),
      ),
      child: Row(children: [
        // Profile avatar
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.20), width: 1),
          ),
          child: ClipOval(
            child: _userPhotoUrl != null
                ? Image.network(_userPhotoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant))
                : Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        // DOMFIX brand
        Text('DOMFIX', style: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.neonAccent,
        )),
        const Spacer(),
        // Notification bell
        Stack(children: [
          Icon(Icons.notifications_outlined, color: AppColors.onSurface, size: 24),
          Positioned(top: 2, right: 2, child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppColors.neonAccent, shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
          )),
        ]),
      ]),
    );
  }

  // ─── HERO (HTML: h1 "How can we help you today, Aymen?") ───
  Widget _buildHeroSection() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.onSurface, letterSpacing: -0.5),
        children: [
          const TextSpan(text: 'How can we\nhelp you today, '),
          TextSpan(text: '$_firstName?', style: TextStyle(color: AppColors.neonAccent)),
        ],
      ),
    );
  }

  // ─── PRIMARY CTA (HTML: AI-Powered diagnosis button) ───
  Widget _buildPrimaryAction() {
    return Stack(clipBehavior: Clip.none, children: [
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.neonAccent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.neonAccent.withValues(alpha: 0.25), blurRadius: 24)],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.onPrimaryFixed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.bolt_rounded, color: AppColors.onPrimaryFixed, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Describe your issue', style: GoogleFonts.spaceGrotesk(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.onPrimaryFixed, height: 1.2)),
              const SizedBox(height: 4),
              Text('AI will diagnose it instantly →', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onPrimaryFixed.withValues(alpha: 0.80))),
            ])),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.onPrimaryFixed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward, color: AppColors.onPrimaryFixed, size: 22),
            ),
          ]),
        ),
      ),
      // AI-POWERED badge
      Positioned(top: -12, right: 16, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.40)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: 12, color: AppColors.neonAccent),
          const SizedBox(width: 5),
          Text('AI-POWERED', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.neonAccent, letterSpacing: 1)),
        ]),
      )),
    ]);
  }

  // ─── QUICK ACTIONS (HTML: 2-col grid) ─────────────────
  Widget _buildQuickActionsGrid() {
    return Row(children: [
      Expanded(child: _quickActionCard(
        icon: Icons.home_outlined, title: 'Control Home', subtitle: 'Lights 40% • AC ON',
        onTap: () => MainLayoutScope.maybeOf(context)?.selectTab(3),
      )),
      const SizedBox(width: 16),
      Expanded(child: _quickActionCard(
        icon: Icons.psychology_outlined, title: 'Ask AI for Help', subtitle: 'Describe your problem',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
      )),
    ]);
  }

  Widget _quickActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.neonAccent, size: 24),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }

  // ─── SUGGESTIONS (HTML: horizontal scroll cards) ──────
  Widget _buildSuggestionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Suggestions for you', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.3)),
        Text('VIEW ALL', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.neonAccent, letterSpacing: 1.2)),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        height: 190,
        child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
          SuggestionCard(
            icon: Icons.ac_unit, title: 'AC not cooling properly?', subtitle: 'Diagnostic AI ready',
            ctaText: 'Fix this now', ctaIcon: Icons.auto_fix_high,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
          ),
          const SizedBox(width: 16),
          SuggestionCard(
            icon: Icons.wifi, title: 'WiFi is slow?', subtitle: 'Optimize connection',
            ctaText: 'Diagnose issue', ctaIcon: Icons.query_stats,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
          ),
          const SizedBox(width: 16),
        ]),
      ),
    ]);
  }

  // ─── NEARBY TECHNICIANS ───────────────────────────────
  Widget _buildNearbyTechniciansSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nearby Technicians', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.3)),
      const SizedBox(height: 16),
      SizedBox(
        height: 220,
        child: _userLat == null || _userLng == null
            ? _buildSkeletonCards()
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users')
                    .where('role', isEqualTo: 'technician').where('isOnline', isEqualTo: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonCards();
                  if (snapshot.hasError) return _emptyState('Error loading', Icons.error_outline);
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _emptyState('No technicians nearby', Icons.engineering_outlined);

                  final List<Map<String, dynamic>> nearbyTechs = [];
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final techLat = (data['lat'] ?? data['location']?['lat']) as num?;
                    final techLng = (data['lng'] ?? data['location']?['lng']) as num?;
                    if (techLat == null || techLng == null) continue;
                    final dist = _calculateDistance(_userLat!, _userLng!, techLat.toDouble(), techLng.toDouble());
                    if (dist <= 10) { data['calculated_distance'] = dist; data['doc_id'] = doc.id; nearbyTechs.add(data); }
                  }
                  nearbyTechs.sort((a, b) => ((b['rating'] as num?)?.toDouble() ?? 0).compareTo((a['rating'] as num?)?.toDouble() ?? 0));
                  final finalList = nearbyTechs.take(4).toList();
                  if (finalList.isEmpty) return _emptyState('No technicians nearby', Icons.engineering_outlined);

                  return ListView.separated(
                    scrollDirection: Axis.horizontal, clipBehavior: Clip.none,
                    itemCount: finalList.length, separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final d = finalList[index];
                      final techId = d['doc_id'] as String;
                      final fullName = d['fullName'] ?? d['name'] ?? 'Technician';
                      return PremiumTechnicianCard(
                        techId: techId, name: fullName, job: _extractJob(d),
                        rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
                        distance: d['calculated_distance'] as double,
                        photoUrl: d['profileImage'], isAvailable: d['isOnline'] == true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TechnicianProfileScreen(technicianId: techId, initialName: fullName))),
                        onMessage: () => _navigateToChat(techId, fullName),
                      );
                    },
                  );
                },
              ),
      ),
    ]);
  }

  // ─── ACTIVE ENVIRONMENT (HTML: compact 2-col grid) ────
  Widget _buildActiveEnvironment() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ACTIVE ENVIRONMENT', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.onSurfaceVariant.withValues(alpha: 0.80))),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _envCard(Icons.ac_unit, 'Living Room', 'AC:', 'ON', true)),
        const SizedBox(width: 12),
        Expanded(child: _envCard(Icons.shield_outlined, 'Security', '', 'ARMED', false)),
      ]),
    ]);
  }

  Widget _envCard(IconData icon, String label, String prefix, String value, bool active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? AppColors.neonAccent.withValues(alpha: 0.10) : AppColors.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: active ? AppColors.neonAccent : AppColors.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, height: 1)),
          const SizedBox(height: 6),
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: active ? AppColors.neonAccent : Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            RichText(text: TextSpan(style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface), children: [
              if (prefix.isNotEmpty) TextSpan(text: '$prefix '),
              TextSpan(text: value, style: TextStyle(color: active ? AppColors.neonAccent : AppColors.onSurfaceVariant)),
            ])),
          ]),
        ])),
      ]),
    );
  }

  // ─── RECENT MESSAGES ──────────────────────────────────
  Widget _buildRecentMessagesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Recent Messages', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.3)),
        GestureDetector(
          onTap: () => MainLayoutScope.maybeOf(context)?.selectTab(1),
          child: Row(children: [
            Text('INBOX', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.neonAccent, letterSpacing: 1.2)),
            const SizedBox(width: 6),
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: AppColors.neonAccent, shape: BoxShape.circle),
              child: Center(child: Text('2', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onPrimaryFixed))),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildMessageSkeletons();
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyMessages();
          final chats = snapshot.data!.docs.take(3).toList();
          return Column(children: chats.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return PremiumMessageTile(chatData: data, currentUserId: _auth.currentUser?.uid ?? '',
                onTap: (otherId, otherName) => _navigateToChat(otherId, otherName));
          }).toList());
        },
      ),
    ]);
  }

  // ─── HELPERS ──────────────────────────────────────────
  Widget _buildMessageSkeletons() {
    return Column(children: List.generate(2, (_) => Container(
      margin: const EdgeInsets.only(bottom: 12), height: 72,
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
    )));
  }

  Widget _buildEmptyMessages() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(child: Column(children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 32, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text('No messages yet', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
      ])),
    );
  }

  Widget _buildSkeletonCards() {
    return ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, __) => ShimmerBox(child: Container(
        width: 256, decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
      )),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
      const SizedBox(height: 8),
      Text(message, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
    ]));
  }

  void _navigateToChat(String otherUserId, String otherUserName) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(otherUserId: otherUserId, otherUserName: otherUserName, otherUserRole: 'technician'),
    ));
  }
}
