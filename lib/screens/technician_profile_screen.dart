import 'dart:ui';
import 'dart:math' show cos, sqrt, asin;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class TechnicianProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String job;
  final String bio;
  final double rating;
  final int reviewCount;
  final int jobsCompleted;
  final int experienceYears;
  final String replyTime;
  final double? distanceKm;
  final bool isAvailable;
  final List<PortfolioItem> portfolio;
  final List<ReviewItem> reviews;

  const TechnicianProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.job,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.jobsCompleted,
    required this.experienceYears,
    required this.replyTime,
    this.distanceKm,
    required this.isAvailable,
    required this.portfolio,
    required this.reviews,
  });

  factory TechnicianProfile.fromFirestore(
      String id, Map<String, dynamic> data) {
    // Parse portfolio
    final rawPortfolio = data['portfolio'] as List<dynamic>? ?? [];
    final portfolio = rawPortfolio
        .map((e) => PortfolioItem(
              imageUrl: e['imageUrl'] ?? '',
              title: e['title'] ?? '',
            ))
        .toList();

    // Parse reviews
    final rawReviews = data['reviews'] as List<dynamic>? ?? [];
    final reviews = rawReviews
        .map((e) => ReviewItem(
              reviewerName: e['reviewerName'] ?? 'Anonymous',
              reviewerPhoto: e['reviewerPhoto'],
              rating: (e['rating'] as num?)?.toInt() ?? 5,
              comment: e['comment'] ?? '',
              timeAgo: e['timeAgo'] ?? '',
            ))
        .toList();

    String job = data['speciality'] ?? data['job'] ?? '';
    if (job.isEmpty) {
      final specs = data['specialties'] as List<dynamic>?;
      if (specs != null && specs.isNotEmpty) job = specs.first.toString();
    }
    if (job.isEmpty) job = 'Technician';

    return TechnicianProfile(
      id: id,
      name: data['fullName'] ?? data['name'] ?? 'Unknown',
      photoUrl: data['profileImage'] ?? data['photoUrl'],
      job: job,
      bio: data['bio'] ??
          'Professional technician with expertise in home services.',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      jobsCompleted: (data['jobsCompleted'] as num?)?.toInt() ?? 0,
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 1,
      replyTime: data['replyTime'] ?? '< 30m',
      distanceKm: (data['distance'] as num?)?.toDouble(),
      isAvailable: data['isAvailable'] ?? false,
      portfolio: portfolio,
      reviews: reviews,
    );
  }
}

class PortfolioItem {
  final String imageUrl;
  final String title;
  const PortfolioItem({required this.imageUrl, required this.title});
}

class ReviewItem {
  final String reviewerName;
  final String? reviewerPhoto;
  final int rating;
  final String comment;
  final String timeAgo;
  const ReviewItem({
    required this.reviewerName,
    this.reviewerPhoto,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TechnicianProfileScreen extends StatefulWidget {
  /// Firestore UID of the technician to display.
  final String technicianId;

  /// Optional pre-loaded display name (shown while loading).
  final String? initialName;

  const TechnicianProfileScreen({
    super.key,
    required this.technicianId,
    this.initialName,
  });

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen>
    with SingleTickerProviderStateMixin {
  TechnicianProfile? _profile;
  bool _loading = true;
  String? _error;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeAnim);

    _fetchProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Firestore fetch ───────────────────────────────────────────────────────
  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.technicianId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _error = 'Technician not found.';
            _loading = false;
          });
        }
        return;
      }

      final profile = TechnicianProfile.fromFirestore(
        doc.id,
        doc.data()!,
      );

      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0C10),
        body: Stack(
          children: [
            _loading
                ? _buildSkeleton()
                : _error != null
                    ? _buildError()
                    : _buildContent(),
            if (!_loading && _error == null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildActionBar(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header overlay (always visible) ──────────────────────────────────────
  Widget _buildGlassHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.of(context).padding.top + 4,
              8,
              8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0C10).withValues(alpha: 0.70),
              border: const Border(
                bottom: BorderSide(color: Color(0x0DFFFFFF)),
              ),
            ),
            child: Row(
              children: [
                _HeaderIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  'DOMFIX',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.neonAccent,
                  ),
                ),
                const Spacer(),
                _HeaderIconButton(
                  icon: Icons.more_vert,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    final p = _profile!;
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Space for header
                      SizedBox(
                        height: MediaQuery.of(context).padding.top + 72,
                      ),
                      // Hero
                      _buildHero(p),
                      const SizedBox(height: 36),
                      // Stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildStats(p),
                      ),
                      const SizedBox(height: 36),
                      // Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildBio(p),
                      ),
                      const SizedBox(height: 36),
                      // Portfolio
                      _buildPortfolio(p),
                      const SizedBox(height: 36),
                      // Reviews
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildReviews(p),
                      ),
                      // Bottom padding for action bar
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildGlassHeader(),
      ],
    );
  }

  // ── Hero section ──────────────────────────────────────────────────────────
  Widget _buildHero(TechnicianProfile p) {
    return Column(
      children: [
        // Avatar with glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonAccent.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Photo
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonAccent.withValues(alpha: 0.20),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: p.photoUrl != null
                    ? Image.network(
                        p.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar(p.name),
                      )
                    : _defaultAvatar(p.name),
              ),
            ),
            // Online dot
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.neonAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0A0C10),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Name
        Text(
          p.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        // Job title
        Text(
          p.job.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: AppColors.neonAccent,
          ),
        ),
        const SizedBox(height: 16),
        // Rating + Distance row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PillChip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 16, color: AppColors.neonAccent),
                  const SizedBox(width: 4),
                  Text(
                    p.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${p.reviewCount})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (p.distanceKm != null) ...[
              const SizedBox(width: 12),
              _PillChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${p.distanceKm!.toStringAsFixed(1)} km away',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStats(TechnicianProfile p) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${p.jobsCompleted > 0 ? '${p.jobsCompleted}+' : '—'}',
            label: 'Jobs',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value:
                '${p.experienceYears > 0 ? '${p.experienceYears} Yrs' : '—'}',
            label: 'Exp.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: p.replyTime,
            label: 'Reply',
          ),
        ),
      ],
    );
  }

  // ── Bio ───────────────────────────────────────────────────────────────────
  Widget _buildBio(TechnicianProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'About'),
        const SizedBox(height: 12),
        Text(
          p.bio,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.65,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Portfolio ─────────────────────────────────────────────────────────────
  Widget _buildPortfolio(TechnicianProfile p) {
    if (p.portfolio.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Recent Work'),
              Text(
                'VIEW ALL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.neonAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 192, // aspect 4:3 of width=256
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: p.portfolio.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final item = p.portfolio[i];
              return _PortfolioCard(item: item);
            },
          ),
        ),
      ],
    );
  }

  // ── Reviews ───────────────────────────────────────────────────────────────
  Widget _buildReviews(TechnicianProfile p) {
    if (p.reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Client Feedback'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Client Feedback'),
        const SizedBox(height: 20),
        ...p.reviews
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ReviewCard(review: r),
                ))
            .toList(),
      ],
    );
  }

  // ── Action bar ────────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    if (_loading || _error != null) return const SizedBox.shrink();
    final p = _profile!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0C10).withValues(alpha: 0.75),
            border: const Border(
              top: BorderSide(color: Color(0x0DFFFFFF)),
            ),
          ),
          child: Row(
            children: [
              // Message
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: p.id,
                          otherUserName: p.name,
                          otherUserRole: 'technician',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21262D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'MESSAGE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Book Now
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _BookingBottomSheet(technician: p),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.neonAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonAccent.withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'BOOK NOW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 140,
          ),
          child: Column(
            children: [
              // Avatar skeleton
              _Shimmer(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF21262D),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Shimmer(
                child: Container(
                  width: 160,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Shimmer(
                child: Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: i > 0 ? 12 : 0),
                        child: _Shimmer(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Shimmer(
                        child: Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildGlassHeader(),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 72,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  'Technician Not Found',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _error ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _fetchProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.neonAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildGlassHeader(),
      ],
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: AppColors.neonAccent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE CHILD WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.neonAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.neonAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final Widget child;
  const _PillChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  const _PortfolioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 256,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(color: const Color(0xFF21262D)),
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF21262D),
                      child: Icon(Icons.image_outlined,
                          color: AppColors.onSurfaceVariant, size: 40),
                    ),
                  )
                : Container(
                    color: const Color(0xFF21262D),
                    child: Icon(Icons.image_outlined,
                        color: AppColors.onSurfaceVariant, size: 40),
                  ),
            // Gradient + label
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
                child: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewItem review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10)),
                  color: AppColors.surfaceContainerHigh,
                ),
                child: ClipOval(
                  child: review.reviewerPhoto != null
                      ? Image.network(
                          review.reviewerPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _reviewerInitial(review.reviewerName),
                        )
                      : _reviewerInitial(review.reviewerName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 13,
                          color: AppColors.neonAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                review.timeAgo.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Comment with left border
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.neonAccent.withValues(alpha: 0.20),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              '"${review.comment}"',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewerInitial(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.neonAccent,
          ),
        ),
      ),
    );
  }
}

/// Simple shimmer container (no external package required)
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

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

/// Small rounded icon button for the header
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(icon, color: AppColors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final TechnicianProfile technician;
  const _BookingBottomSheet({required this.technician});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  final _problemController = TextEditingController();
  final _priceController = TextEditingController();
  String _urgency = 'Standard';
  bool _submitting = false;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
        c(lat1 * p) * c(lat2 * p) * 
        (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // KM
  }

  Future<void> _submitRequest() async {
    if (_problemController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final prefs = await SharedPreferences.getInstance();
      final userLat = prefs.getDouble('cachedLat') ?? 0.0;
      final userLng = prefs.getDouble('cachedLng') ?? 0.0;
      
      final techDoc = await FirebaseFirestore.instance.collection('users').doc(widget.technician.id).get();
      final techData = techDoc.data() ?? {};
      final dynamic latRaw = techData['lat'] ?? techData['location']?['lat'];
      final dynamic lngRaw = techData['lng'] ?? techData['location']?['lng'];
      final techLat = (latRaw as num?)?.toDouble() ?? 0.0;
      final techLng = (lngRaw as num?)?.toDouble() ?? 0.0;

      final distance = _calculateDistance(userLat, userLng, techLat, techLng);

      final jobRef = FirebaseFirestore.instance.collection('jobs').doc();
      
      await jobRef.set({
        'jobId': jobRef.id,
        'userId': user.uid,
        'technicianId': widget.technician.id,
        'problemDescription': _problemController.text.trim(),
        'urgency': _urgency,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userLat': userLat,
        'userLng': userLng,
        'technicianLat': techLat,
        'technicianLng': techLng,
        'distance': distance,
        if (_priceController.text.trim().isNotEmpty) 'estimatedPrice': _priceController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent exclusively to ${widget.technician.name}!'),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Book ${widget.technician.name}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Problem Description', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _problemController,
            maxLines: 4,
            style: GoogleFonts.inter(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Describe what needs fixing...',
              hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Urgency', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _urgency,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      style: GoogleFonts.inter(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Standard', 'Urgent', 'Emergency'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _urgency = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Est. Price (Opt)', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      style: GoogleFonts.inter(color: AppColors.onSurface),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '\$0.00',
                        hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonAccent,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                : Text('CONFIRM BOOKING', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
