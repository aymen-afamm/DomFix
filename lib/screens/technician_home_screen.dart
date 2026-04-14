import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/technician_location_service.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import 'settings_screen.dart';
import 'messages_screen.dart';
import 'chat_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TechnicianDashboard(),
    MessagesScreen(), // ✅ ADDED: Messages screen for technician
    TechnicianJobsScreen(),
    TechnicianProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      HapticFeedback.lightImpact();
    }
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'DASHBOARD', 0),
          _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'MESSAGES', 1),
          _buildNavItem(Icons.work_outline, Icons.work, 'JOBS', 2),
          _buildNavItem(Icons.person_outline, Icons.person, 'PROFILE', 3),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 'SETTINGS', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> with WidgetsBindingObserver {
  final _locationService = TechnicianLocationService();

  @override
  void initState() {
    super.initState();
    print('\n🟢 ========================================');
    print('🟢 TECHNICIAN DASHBOARD INITIALIZED');
    print('🟢 ========================================');
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    print('✅ Lifecycle observer added');
    
    // Start publishing location
    print('📍 Starting location publishing...');
    _locationService.startPublishing();
    print('🟢 ========================================\n');
  }

  @override
  void dispose() {
    print('\n🔴 ========================================');
    print('🔴 TECHNICIAN DASHBOARD DISPOSING');
    print('🔴 ========================================');
    
    // CRITICAL: Stop publishing when widget is disposed
    print('🛑 Stopping location publishing...');
    _locationService.stopPublishing();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    print('✅ Lifecycle observer removed');
    print('🔴 ========================================\n');
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('\n🔄 ========================================');
    print('🔄 APP LIFECYCLE STATE CHANGED');
    print('🔄 New state: $state');
    print('🔄 ========================================');
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - start publishing
        print('✅ App resumed - starting location publishing');
        _locationService.startPublishing();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or closing - stop publishing
        print('⚠️  App paused/inactive - stopping location publishing');
        _locationService.stopPublishing();
        break;
    }
    print('🔄 ========================================\n');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildStatsCards(),
            const SizedBox(height: 30),
            _buildActiveJobsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TECHNICIAN DASHBOARD',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome Back',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Jobs', '3', Icons.work_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Completed', '47', Icons.check_circle_outline)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE JOBS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _buildJobCard('AC Repair', 'Downtown', '\$120'),
        const SizedBox(height: 12),
        _buildJobCard('Plumbing Fix', 'Uptown', '\$85'),
      ],
    );
  }

  Widget _buildJobCard(String title, String location, String price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.build_outlined, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicianJobsScreen extends StatefulWidget {
  const TechnicianJobsScreen({super.key});

  @override
  State<TechnicianJobsScreen> createState() => _TechnicianJobsScreenState();
}

class _TechnicianJobsScreenState extends State<TechnicianJobsScreen> {
  String _timeAgoInfo(Timestamp? t) {
    if (t == null) return 'JUST NOW';
    final diff = DateTime.now().difference(t.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showJobDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Review Request', style: GoogleFonts.spaceGrotesk(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        content: Text(data['problemDescription'] ?? 'No description.', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('jobs').doc(data['jobId']).update({'status': 'rejected'});
            },
            child: Text('REJECT', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: AppColors.onPrimary),
            onPressed: () async {
              Navigator.pop(ctx);
              final String jobId = data['jobId'];
              
              // 1. Update job
              await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'accepted'});

              // 2. Create message natively leveraging robust Chat Service
              try {
                await ChatService().sendMessage(
                  receiverId: data['userId'],
                  text: data['problemDescription'],
                );
              } catch (_) {}

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(
                    otherUserId: data['userId'],
                    otherUserName: 'Client',
                    otherUserRole: 'client',
                  )),
                );
              }
            },
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nearby Requests', style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Active jobs searching', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildFilterChip('ALL NEARBY', true),
                const SizedBox(width: 8),
                _buildFilterChip('PLUMBING', false),
                const SizedBox(width: 8),
                _buildFilterChip('ELECTRICAL', false),
                const SizedBox(width: 8),
                _buildFilterChip('SMART HOME', false),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('technicianId', isEqualTo: uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
                if (snapshot.hasError) return Center(child: Text("Error fetching requests"));
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No active requests', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final desc = data['problemDescription'] as String? ?? 'Needs repair';
                    final firstWords = desc.split(' ').take(4).join(' ');
                    final dist = data['distance'] as double? ?? 0.0;
                    final price = data['estimatedPrice'] as String?;
                    final urgency = data['urgency'] as String? ?? 'Standard';

                    return GestureDetector(
                      onTap: () => _showJobDialog(data),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(firstWords + '...', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: AppColors.primaryContainer),
                                          const SizedBox(width: 4),
                                          Text('${dist.toStringAsFixed(1)} km away', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(_timeAgoInfo(data['createdAt'] as Timestamp?), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primaryContainer.withValues(alpha: 0.6))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppColors.onSecondaryContainer)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                                      child: Text(urgency.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.onSurface)),
                                    ),
                                    if (price != null && price.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Text('Est. \$$price', style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                                    ],
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                                  child: Text('VIEW', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onPrimary)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.w600, color: active ? AppColors.onPrimaryFixed : AppColors.onSurfaceVariant)),
    );
  }
}

class TechnicianProfileScreen extends StatelessWidget {
  const TechnicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Professional Technician',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
