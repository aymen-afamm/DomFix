import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Full-screen OSM map: user GPS + simulated nearby technicians (no Firebase).
class NearbyTechniciansMapScreen extends StatefulWidget {
  const NearbyTechniciansMapScreen({super.key});

  @override
  State<NearbyTechniciansMapScreen> createState() =>
      _NearbyTechniciansMapScreenState();
}

class _NearbyTechniciansMapScreenState extends State<NearbyTechniciansMapScreen> {
  final _mapController = MapController();

  static const _fallback = LatLng(40.758, -73.9855);

  LatLng? _userPoint;
  bool _loading = true;
  _SimulatedTech? _selected;

  late List<_SimulatedTech> _technicians;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    setState(() => _loading = true);

    LatLng center = _fallback;
    String? message;

    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        message = 'Location services are off. Showing a default area.';
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          message = 'Location denied. Showing a default area.';
        } else if (permission == LocationPermission.deniedForever) {
          message = 'Location blocked. Enable it in settings to see your position.';
        } else {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          center = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (e) {
      message = 'Could not get location. Showing a default area.';
    }

    if (!mounted) return;

    _technicians = _buildSimulatedTechnicians(center);

    setState(() {
      _userPoint = center;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userPoint == null) return;
      _mapController.move(_userPoint!, 14);
    });

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<_SimulatedTech> _buildSimulatedTechnicians(LatLng user) {
    return [
      _SimulatedTech(
        id: '1',
        name: 'David L.',
        specialty: 'Plumbing Specialist',
        point: LatLng(user.latitude + 0.004, user.longitude + 0.003),
        icon: Icons.plumbing_rounded,
        rating: 4.9,
        reviews: 128,
        rateLabel: r'$85/hr',
        distanceLabel: '1.2 mi',
      ),
      _SimulatedTech(
        id: '2',
        name: 'Marcus Chen',
        specialty: 'Master Electrician',
        point: LatLng(user.latitude - 0.003, user.longitude + 0.005),
        icon: Icons.electric_bolt_rounded,
        rating: 5.0,
        reviews: 89,
        rateLabel: r'$72/hr',
        distanceLabel: '0.8 mi',
      ),
      _SimulatedTech(
        id: '3',
        name: 'Sarah K.',
        specialty: 'HVAC Expert',
        point: LatLng(user.latitude + 0.002, user.longitude - 0.004),
        icon: Icons.construction_rounded,
        rating: 4.8,
        reviews: 56,
        rateLabel: r'$68/hr',
        distanceLabel: '1.5 mi',
      ),
      _SimulatedTech(
        id: '4',
        name: 'James R.',
        specialty: 'Smart Home',
        point: LatLng(user.latitude - 0.005, user.longitude - 0.002),
        icon: Icons.home_repair_service_rounded,
        rating: 4.7,
        reviews: 34,
        rateLabel: r'$90/hr',
        distanceLabel: '2.1 mi',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_loading || _userPoint == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.neonAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Getting location…',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPoint!,
                initialZoom: 14,
                // ignore: unnecessary_underscores
                onTap: (_, __) => setState(() => _selected = null),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.domfix',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPoint!,
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      child: _UserLocationMarker(),
                    ),
                    ..._technicians.map(
                      (t) => Marker(
                        point: t.point,
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selected = t),
                          child: _TechPin(
                            icon: t.icon,
                            emphasized: _selected?.id == t.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap © CARTO',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.neonAccent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Nearby technicians',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _initLocation,
                    icon: Icon(
                      Icons.my_location_rounded,
                      color: AppColors.neonAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_loading && _userPoint != null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181C21).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.neonAccent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.neonAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search service or pro…',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color:
                                  AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262A30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_selected != null && !_loading)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: _TechnicianPreviewCard(
                tech: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimulatedTech {
  const _SimulatedTech({
    required this.id,
    required this.name,
    required this.specialty,
    required this.point,
    required this.icon,
    required this.rating,
    required this.reviews,
    required this.rateLabel,
    required this.distanceLabel,
  });

  final String id;
  final String name;
  final String specialty;
  final LatLng point;
  final IconData icon;
  final double rating;
  final int reviews;
  final String rateLabel;
  final String distanceLabel;
}

class _UserLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF262A30).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonAccent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonAccent.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            'YOU',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.neonAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonAccent,
            boxShadow: [
              BoxShadow(
                color: AppColors.neonAccent.withValues(alpha: 0.45),
                blurRadius: 16,
              ),
            ],
            border: Border.all(
              color: AppColors.background,
              width: 3,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            color: const Color(0xFF181E00),
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _TechPin extends StatelessWidget {
  const _TechPin({required this.icon, required this.emphasized});

  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: emphasized ? 1.08 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerHighest,
          border: Border.all(
            color: AppColors.neonAccent.withValues(alpha: emphasized ? 0.8 : 0.4),
            width: 2,
          ),
          boxShadow: emphasized
              ? [
                  BoxShadow(
                    color: AppColors.neonAccent.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: AppColors.neonAccent, size: 20),
      ),
    );
  }
}

class _TechnicianPreviewCard extends StatelessWidget {
  const _TechnicianPreviewCard({
    required this.tech,
    required this.onClose,
  });

  final _SimulatedTech tech;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF181C21).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF454932).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tech.icon,
                        color: AppColors.neonAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tech.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tech.specialty.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.neonAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: AppColors.neonAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${tech.rating}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${tech.reviews} reviews)',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DISTANCE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        tech.distanceLabel.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.neonAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262A30).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RATE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            tech.rateLabel,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262A30).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVAILABILITY',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Available now',
                            style: GoogleFonts.inter(
                              color: AppColors.neonAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonAccent,
                        side: BorderSide(
                          color: AppColors.surfaceContainerHighest,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'VIEW PROFILE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.chat_rounded,
                          size: 18, color: const Color(0xFF181E00)),
                      label: Text(
                        'CHAT NOW',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: const Color(0xFF181E00),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.neonAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
}
