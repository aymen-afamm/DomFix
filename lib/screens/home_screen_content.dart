import 'dart:ui';
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

/// ──────────────────────────────────────────────────────────────────────────────
/// HomeScreenContent — pixel-faithful conversion of the HTML/Tailwind design.
///
/// Every section maps 1:1 to the provided HTML:
///   1. Hero greeting (dynamic user name from Firestore)
///   2. Primary "Describe your issue" CTA with pulse-glow
///   3. Quick Actions grid  (Control Home · Ask AI)
///   4. Suggestions carousel
///   5. Nearby Technicians  (Firestore-powered)
///   6. Active Environment compact grid
///   7. Recent Messages     (Firestore stream)
/// ──────────────────────────────────────────────────────────────────────────────
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userName = '';
  String? _userPhotoUrl;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initLocation();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
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
      
      // Load cached location instantly if available
      final cachedLat = prefs.getDouble('cachedLat');
      final cachedLng = prefs.getDouble('cachedLng');
      
      if (cachedLat != null && cachedLng != null && mounted) {
        setState(() {
          _userLat = cachedLat;
          _userLng = cachedLng;
        });
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        print("Permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache the new precise location
      await prefs.setDouble('cachedLat', position.latitude);
      await prefs.setDouble('cachedLng', position.longitude);

      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
        });
        print("HOME LOCATION: $_userLat, $_userLng");
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
    return 12742 * asin(sqrt(a)); // KM
  }

  // ──────────────────────────────────────────── BUILD ─────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Fixed Header ──
          SliverToBoxAdapter(child: _buildTopBar()),
          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  1 · TOP APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.60),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // User avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryFixed.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ClipOval(
                      child: _userPhotoUrl != null
                          ? Image.network(
                              _userPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DOMFIX',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: AppColors.neonAccent,
                    ),
                  ),
                ],
              ),
              // Notifications
              Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onSurface,
                    size: 24,
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  2 · HERO SECTION  —  "How can we help you today, Aymen?"
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection() {
    return Text.rich(
      TextSpan(
        text: 'How can we help\nyou today, ',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: _userName.isNotEmpty ? '$_userName?' : 'there?',
            style: TextStyle(color: AppColors.primaryFixed),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  3 · PRIMARY ACTION — "Describe your issue" with pulse-glow
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPrimaryAction() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // AI-Powered badge
        Positioned(
          top: -12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: AppColors.primaryFixed),
                const SizedBox(width: 6),
                Text(
                  'AI-POWERED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primaryFixed,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Main button with animated glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final glowValue = 20 + (_glowAnimation.value * 15);
            final glowAlpha = 0.15 + (_glowAnimation.value * 0.30);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIChatScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonAccent.withValues(alpha: glowAlpha),
                      blurRadius: glowValue,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimaryFixed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.bolt,
                        color: AppColors.onPrimaryFixed,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Describe your issue',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI will diagnose it instantly →',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onPrimaryFixed.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimaryFixed.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.onPrimaryFixed,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  4 · QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.home_outlined,
            title: 'Control Home',
            subtitle: 'Lights 40% • AC ON',
            onTap: () {
              MainLayoutScope.maybeOf(context)?.selectTab(3);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.psychology_outlined,
            title: 'Ask AI for Help',
            subtitle: 'Describe your problem',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIChatScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  5 · SUGGESTIONS SECTION (horizontal scroll)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSuggestionsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Suggestions for you',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'VIEW ALL',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.primaryFixed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _SuggestionCard(
                icon: Icons.ac_unit,
                title: 'AC not cooling properly?',
                subtitle: 'Diagnostic AI ready',
                buttonLabel: 'Fix this now',
                buttonIcon: Icons.auto_fix_high,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen()));
                },
              ),
              const SizedBox(width: 16),
              _SuggestionCard(
                icon: Icons.wifi,
                title: 'WiFi is slow?',
                subtitle: 'Optimize connection',
                buttonLabel: 'Diagnose issue',
                buttonIcon: Icons.query_stats,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen()));
                },
              ),
              const SizedBox(width: 16),
              _SuggestionCard(
                icon: Icons.water_drop_outlined,
                title: 'Leaking faucet?',
                subtitle: 'Find a plumber nearby',
                buttonLabel: 'Get help',
                buttonIcon: Icons.plumbing,
                onTap: () {
                  MainLayoutScope.maybeOf(context)?.selectTab(2);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  6 · NEARBY TECHNICIANS  (Firestore-powered)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNearbyTechniciansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Technicians',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: _userLat == null || _userLng == null 
            ? Center(
                child: CircularProgressIndicator(color: AppColors.neonAccent),
              )
            : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'technician')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.neonAccent));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading technicians',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print("DEBUG: Zero users found with role=='technician'!");
                return Center(
                  child: Text(
                    'No technicians available',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              
              print("USER LOCATION: $_userLat, $_userLng");
              print("TOTAL TECHS: ${docs.length}");

              final List<Map<String, dynamic>> nearbyTechs = [];
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                print("DEBUG EXAMINING DOC: ${doc.id} | data: $data");
                
                final dynamic techLatRaw = data['lat'] ?? data['location']?['lat'];
                final dynamic techLngRaw = data['lng'] ?? data['location']?['lng'];
                
                if (techLatRaw == null || techLngRaw == null) {
                  print("DEBUG SKIPPED: ${doc.id} due to NULL lat/lng (found lat=$techLatRaw, lng=$techLngRaw)");
                  continue;
                }

                final techLat = (techLatRaw as num).toDouble();
                final techLng = (techLngRaw as num).toDouble();

                final distance = _calculateDistance(_userLat!, _userLng!, techLat, techLng);

                print("TECH: ${data['fullName'] ?? data['name']}");
                print("Distance: $distance km");

                if (distance <= 10) {
                  data['calculated_distance'] = distance;
                  data['doc_id'] = doc.id;
                  nearbyTechs.add(data);
                } else {
                  print("DEBUG SKIPPED: ${doc.id} due to distance $distance > 10km");
                }
              }

              print("NEARBY TECHS: ${nearbyTechs.length}");

              if (nearbyTechs.isEmpty) {
                return Center(
                  child: Text(
                    'No technicians nearby',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                );
              }

              nearbyTechs.sort((a, b) {
                 final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
                 final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
                 return ratingB.compareTo(ratingA);
              });
              
              final finalList = nearbyTechs.take(4).toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: finalList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final data = finalList[index];
                  final techId = data['doc_id'] as String;
                  
                  final fullName = data['fullName'] ?? data['name'] ?? 'Technician';

                  return _TechnicianCard(
                    techId: techId,
                    name: fullName,
                    job: data['speciality'] ?? _extractJob(data),
                    rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
                    distance: data['calculated_distance'] as double,
                    photoUrl: data['profileImage'],
                    isAvailable: data['isOnline'] == true,
                    onMessage: () => _navigateToChat(techId, fullName),
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TechnicianProfileScreen(
                            technicianId: techId,
                            initialName: fullName,
                          ),
                        ),
                      );
                    },
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

  Widget _buildTechnicianSkeletons() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, __) => _Shimmer(
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.whiteBorder5),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  7 · ACTIVE ENVIRONMENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActiveEnvironment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE ENVIRONMENT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EnvironmentTile(
                icon: Icons.ac_unit,
                iconColor: AppColors.primaryFixed,
                bgColor: AppColors.primaryFixed.withValues(alpha: 0.10),
                label: 'Living Room',
                value: 'AC: ',
                valueHighlight: 'ON',
                isActive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EnvironmentTile(
                icon: Icons.shield_outlined,
                iconColor: AppColors.onSurfaceVariant,
                bgColor: AppColors.onSurface.withValues(alpha: 0.05),
                label: 'Security',
                value: '',
                valueHighlight: 'ARMED',
                isActive: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  8 · RECENT MESSAGES (Firestore-powered)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentMessagesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Messages',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                MainLayoutScope.maybeOf(context)?.selectTab(1);
              },
              child: Row(
                children: [
                  Text(
                    'INBOX',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.primaryFixed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  StreamBuilder<QuerySnapshot>(
                    stream: _chatService.getUserChats(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _chatService.getUserChats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildMessageSkeleton();
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

  Widget _buildMessageSkeleton() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteBorder5),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Navigate to chat
  void _navigateToChat(String otherUserId, String otherUserName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserRole: 'technician',
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EXTRACTED WIDGETS — keep the main class clean
// ═════════════════════════════════════════════════════════════════════════════

/// Quick Action Card (Control Home / Ask AI)
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.whiteBorder5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primaryFixed, size: 24),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suggestion Card (horizontal scroll)
class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteBorder3),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -8,
            child: Icon(
              icon,
              size: 60,
              color: AppColors.onSurface.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(buttonIcon, size: 16, color: AppColors.onPrimaryFixed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Technician Card (horizontal scroll)
class _TechnicianCard extends StatelessWidget {
  final String techId;
  final String name;
  final String job;
  final double rating;
  final double? distance;
  final String? photoUrl;
  final bool isAvailable;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;

  const _TechnicianCard({
    required this.techId,
    required this.name,
    required this.job,
    required this.rating,
    this.distance,
    this.photoUrl,
    required this.isAvailable,
    required this.onMessage,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final distText = distance != null ? '${distance!.toStringAsFixed(1)} km' : '';

    return Container(
      width: 256,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteBorder5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Info
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surfaceContainerHigh,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.primaryFixed),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (distText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            distText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
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
          const SizedBox(height: 12),
          // ── Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isAvailable)
                _Badge(
                  label: 'Available now',
                  color: const Color(0xFF4ADE80),
                ),
              _Badge(
                label: rating >= 4.8 ? 'Top Rated' : 'Responds fast',
                color: AppColors.primaryFixed,
              ),
            ],
          ),
          const Spacer(),
          // ── Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onViewProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'View Profile',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Message',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryFixed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.engineering, color: AppColors.primaryFixed, size: 28),
      ),
    );
  }
}

/// Small badge chip
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Environment status tile (Active Environment section)
class _EnvironmentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final String valueHighlight;
  final bool isActive;

  const _EnvironmentTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.valueHighlight,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.whiteBorder5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.primaryFixed
                            : AppColors.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        text: value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: valueHighlight,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primaryFixed
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent message tile (Firestore-powered)
class _RecentMessageTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final void Function(String otherId, String otherName) onTap;

  const _RecentMessageTile({
    required this.chatData,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnap) {
        final name = userSnap.data?.exists == true
            ? ((userSnap.data!.data() as Map<String, dynamic>)['name'] ?? 'User')
            : 'User';
        final photoUrl = userSnap.data?.exists == true
            ? (userSnap.data!.data() as Map<String, dynamic>)['profileImage']
            : null;
        final lastMessage = chatData['lastMessage'] ?? '';
        final timestamp = chatData['lastMessageTime'] as Timestamp?;
        final timeStr = _formatTime(timestamp);

        return GestureDetector(
          onTap: () => onTap(otherUserId, name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.whiteBorder5),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryFixed.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatar(name))
                        : _avatar(name),
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryFixed,
          ),
        ),
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

/// Simple shimmer container animation
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({super.key, required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: 0.4 + _anim.value * 0.35,
        child: child,
      ),
      child: widget.child,
    );
  }
}
