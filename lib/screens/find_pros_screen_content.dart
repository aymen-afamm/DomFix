import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class FindProsScreenContent extends StatefulWidget {
  const FindProsScreenContent({super.key});

  @override
  State<FindProsScreenContent> createState() => _FindProsScreenContentState();
}

class _FindProsScreenContentState extends State<FindProsScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedChip = 0;
  final _searchFocus = FocusNode();

  static const _filters = [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Smart Home',
  ];

  static const _featured = [
    _FeaturedTech(
      name: 'Marcus Chen',
      role: 'Master Electrician',
      rating: 5.0,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBYHStyv6hCK3LR_QvLh4fxlzuqK-K6KoV1SS8Fx28ExWPyi-nqCkWh1QH_joy8VBZa3-lY6vVCDAmqapjM9azgmzrX-N_NP9nE39ZxBfhT-4qSxbLaj-jxxFXAwsrt3JqS7uT0lvN0ttEa_4A5VTg3TR1DPXaDnuJE17eUO7RxvR3aZFTNiNwxJ6ETmb2xFc0OfOLcLiUTqT7qIBP9rpH_9MtF5kPc33-_6s4CoKqNuKeaWTfhXCtJPF9DyuvFKiPXEleRXxwUSK0',
    ),
    _FeaturedTech(
      name: 'David Miller',
      role: 'HVAC Expert',
      rating: 4.9,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA5aOohgty6RQbgYza0SPtrM9IU9-e2znYHALsQ-yYjgZhYTh6bGVSinlcRMVvQsA-2gmhax04UChRX26rgGrHPEhzgsyWQYKnYd-WyNsCIUjClz2cVgzw8Wv469q4K14Io7QrhpUd1uL__WFmEZz7_6OHePaJmtefR9m3YY9LgiDuCz_0lEyEOb3wRZUND0BeEFXr4QbAsySMu229jxXI9uSyHI3fHwzsRRp54gq0ceLjGS71vducNwGAY8odR96NmFxpK4MJpfsY',
    ),
  ];

  static const _nearby = [
    _ListTech(
      name: 'Alex Rivera',
      role: 'Senior Electrician',
      rateLabel: r'$45',
      rating: 4.9,
      distanceKm: 2.3,
      tagline: 'Certified specialist in smart circuit integration.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCTolk3hRuZ_BeH7YH5ALokCxt2YBQA1lQZfSY8yvaXQyHqi9TWRA3OZBhAy8L87bNA-f1gUtLRDCMS7kr25jU4qiNBIIWXbDoDW7xYw5moHLMqilJw8HwleTNrgE39w8kDVz7UP_a5_JdJQ5K1dhuwY9wo0IOvWvbQTOP4f28UqyrotwpcPsk_c9YGvjAyRFm2n9ycGOIpHGi8dR394Lfk_X7s-EK0s7kQN2l8EvM4Pr6Xq8dkIs_oCYG-tyX_PSn6oPumL5S1b9c',
    ),
    _ListTech(
      name: 'Sarah Jenkins',
      role: 'Plumbing Expert',
      rateLabel: r'$50',
      rating: 4.8,
      distanceKm: 1.5,
      tagline: 'Emergency repairs and installations specialist.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCZIYXV4_F_1mHFEZEiDbeMUesNjve78Jr0jbg3riONxPU8SyLVucU6sHOoRGOUvVcp-VCN8yRC8N5mqCkSPNtg2XbT3qlmYx2C0GCtnTaSX0CpKclMZoY_amzMnrhzwwFZOkNWHf1_lZdMfFezQDCXZBrzdIi6wQ7xGvtBtBVzph6n7db56k8Zy5xJmI-uXdugO66J3BTX09JizCyZcs7ozBPW36wKKWVZ_DQVp84B7239qQ4DwSKhtWJXOZKMbjL6vitP8EE57FQ',
    ),
    _ListTech(
      name: 'James Wilson',
      role: 'Appliance Repair',
      rateLabel: r'$38',
      rating: 4.7,
      distanceKm: 3.1,
      tagline: 'Expert in all major household appliance brands.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDkI_oKbPnUKA3KG5EyDZtegPnGwfDK4_exMxlV9QkjybaAm9hj1OKdhbYlBBRI_a9m3qwY03X47WmHpLqQPuoCrz0kre11ljSnw6RMkEsjnhP18hhpvSPvhp42pqJIY-WQy0WpsD6LOGkVIjCPoCkv5IjnHxy2tP3S2fyCzHK68ACokJARIU66leJwLeN_2FjEZvGvbH_ocaZl4T-P9ZOEqbCz-SQshI0Annlf6fB0QsGi8XIerYgszO-viAXb6plI0I9IzQPviw',
    ),
  ];

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.paddingOf(context).top;
    const headerBody = 64.0;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                topInset + headerBody + 16,
                24,
                bottomPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your Technician',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Expert help for every home emergency, just a tap away.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSearchRow(context),
                  const SizedBox(height: 28),
                  _buildFilterChips(),
                  const SizedBox(height: 36),
                  _buildFeaturedSection(),
                  const SizedBox(height: 36),
                  _buildNearbySection(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FrostedTopBar(topInset: topInset, height: headerBody),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181C21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchFocus.hasFocus
                ? AppColors.neonAccent.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                focusNode: _searchFocus,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search for services...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFF454932).withValues(alpha: 0.2),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {},
              icon: Icon(Icons.tune, color: AppColors.neonAccent, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = _selectedChip == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.neonAccent
                    : const Color(0xFF1C2025),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[i].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 1.4,
                  color: selected
                      ? const Color(0xFF181E00)
                      : AppColors.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Top Rated Technicians',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'VIEW ALL',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.neonAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _featured.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _FeaturedCard(tech: _featured[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Specialists',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        ..._nearby.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _NearbyCard(tech: t),
            )),
      ],
    );
  }
}

class _FrostedTopBar extends StatelessWidget {
  const _FrostedTopBar({required this.topInset, required this.height});

  final double topInset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(top: topInset, left: 24, right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF101419).withValues(alpha: 0.6),
          ),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.neonAccent, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'DOMFIX',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.neonAccent,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: const Color(0xFFE0E2EA),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedTech {
  const _FeaturedTech({
    required this.name,
    required this.role,
    required this.rating,
    required this.imageUrl,
  });

  final String name;
  final String role;
  final double rating;
  final String imageUrl;
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.tech});

  final _FeaturedTech tech;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 186,
      child: Material(
        color: const Color(0xFF181C21),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 152,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    tech.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceContainerHighest,
                      child: Icon(
                        Icons.engineering_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: const Color(0xFF101419).withValues(alpha: 0.8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.neonAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tech.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tech.role.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.6,
                      color: AppColors.onSurfaceVariant,
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

class _ListTech {
  const _ListTech({
    required this.name,
    required this.role,
    required this.rateLabel,
    required this.rating,
    required this.distanceKm,
    required this.tagline,
    required this.imageUrl,
  });

  final String name;
  final String role;
  final String rateLabel;
  final double rating;
  final double distanceKm;
  final String tagline;
  final String imageUrl;
}

class _NearbyCard extends StatefulWidget {
  const _NearbyCard({required this.tech});

  final _ListTech tech;

  @override
  State<_NearbyCard> createState() => _NearbyCardState();
}

class _NearbyCardState extends State<_NearbyCard> {
  @override
  Widget build(BuildContext context) {
    final t = widget.tech;
    return Material(
      color: const Color(0xFF181C21),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.neonAccent.withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1C2025).withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  t.imageUrl,
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 78,
                    height: 78,
                    color: AppColors.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.role.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                  color: AppColors.neonAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: t.rateLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.neonAccent,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/hr',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.neonAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.near_me_outlined,
                          size: 15,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${t.distanceKm} km',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurface,
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
}
