import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServicesHomeScreen extends StatelessWidget {
  const ServicesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0c10),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 112)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildServiceCategories(),
                    const SizedBox(height: 48),
                    _buildCertifiedExperts(),
                    const SizedBox(height: 48),
                    _buildPowerEmergency(),
                    const SizedBox(height: 176),
                  ],
                ),
              ),
            ],
          ),
          // Fixed header
          _buildHeader(),
          // AI Assistant FAB
          _buildAIAssistantButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0a0c10).withOpacity(0.7),
              border: const Border(
                bottom: BorderSide(color: Color(0x0DFFFFFF), width: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                          color: const Color(0xFF181c21),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCePo42411FCFBCJTkXFzJtvUTDhsyiXbeQ41hPxJCwXFX2ybTdz0HtfImW7fIZEruHKfGTUNtn_A2yleUMUDpTUsZV3LeRXl3ICZq_0f5pAmwsphnRxWJ0YKc1QoI7SLslL51mOEbMwHPkAhmkCQUFP6CrY9sxvX7_Iw5hpFcq3mrqiJ-9IAllQq4O1dGyynq5Axrzt3fkazlvAbdL6CM9eSISP-KlbYWfSjTBTb-65FE4n0iDaOMmJpnDX223-Y1QL2E_zbQQLJA',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 18, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aymen B.',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 10, color: Colors.white60),
                              const SizedBox(width: 4),
                              Text(
                                'CASABLANCA',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white60,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFFC5C9AC)),
                        Positioned(
                          top: 11,
                          right: 11,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCDF200),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0a0c10), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIAssistantButton() {
    return Positioned(
      bottom: 128,
      right: 24,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFCDF200),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.precision_manufacturing, size: 26, color: Color(0xFF2b3400)),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'AI',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need expert\nassistance?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Precision smart home & electrical solutions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC5C9AC).withOpacity(0.8),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 40,
            children: [
              _buildServiceItem('Electrical Repair', Icons.bolt, true),
              _buildServiceItem('Smart Lighting', Icons.lightbulb_outline, false),
              _buildServiceItem('CCTV & Security', Icons.videocam_outlined, false),
              _buildServiceItem('Wi-Fi Setup', Icons.router_outlined, false),
              _buildServiceItem('Smart Switches', Icons.toggle_on_outlined, false),
              _buildServiceItem('Solar Systems', Icons.solar_power_outlined, false),
              _buildServiceItem('EV Charger', Icons.ev_station_outlined, false),
              _buildServiceItem('Home Auto', Icons.settings_input_component_outlined, false),
              _buildServiceItem('Power Outage', Icons.power_off_outlined, false),
              _buildServiceItem('Smart Sensors', Icons.sensors_outlined, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(String label, IconData icon, bool isFeatured) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isFeatured ? const Color(0xFFCDF200) : const Color(0xFF262a30).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFeatured ? Colors.transparent : const Color(0x14FFFFFF),
                width: 0.5,
              ),
              boxShadow: isFeatured
                  ? [
                      BoxShadow(
                        color: const Color(0xFFCDF200).withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isFeatured ? const Color(0xFF2b3400) : Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isFeatured ? FontWeight.w700 : FontWeight.w600,
              color: isFeatured ? Colors.white : const Color(0xFFC5C9AC).withOpacity(0.7),
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifiedExperts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCDF200),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCDF200).withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIVE DISPATCH',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFCDF200),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Certified Experts',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top-rated responders nearby',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFC5C9AC).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFCDF200).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'System Map',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCDF200),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildExpertCard(
                'Marcus Chen',
                'Certified Electrician',
                'High-Voltage Systems Expert',
                '4.9',
                '12 min',
                'Licensed',
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCT-C0VUZA1U7r9KTy-zpHjjK0xqRsT5C7DIb7WjlywrjSKb5ydDv5uGEL08g1XDjX-MPW27KThQHFgQrkJuAdguqk5SFhQKA_9N5hIU6tfA7ToZbasBigWEGRCK_Y6OcFwDzTUdZ9b4_fsG4GhtSqdwi0qM8e3GuNm9DEQHA3MCcRMBTPEwJcrpfD5rJ-Zzk6IfGgWwa5ZoaHtedk__IJjSq9jYD-ExK_3VG4B5tfcDYVRiEGNjtjkWLIWrtoWxGB5hzAqq2MvsFQ',
              ),
              const SizedBox(width: 20),
              _buildExpertCard(
                'Sarah Miller',
                'IoT Specialist',
                'Smart Mesh & Security',
                '4.8',
                '18 min',
                'Pro',
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDkoTb0IKZ7S5D87BRSm4fYKpTA3qc-EKG3Rr-mvDP9TRf2v6I3T42v5VVAsZM5pqef-iKX7ZzSwVN2tzEMKXe0i8HjDMNOMSBY7R9gzRZ3HKi3yiNJN7x4wpOYrjXRfM1Y0UNyFuWOkuzauX-2FEcsSLooMQXEdi8c2vyle32BjQWhmvdFwipMh1tHe_Nmbsa2uwQiVucYNOedgC5tJnayQwQQUg18CMOopAQwaYd2nwHFpaF6x-LWsqiASKeKZSEA8GyPDnCxAaA',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpertCard(
    String name,
    String title,
    String subtitle,
    String rating,
    String eta,
    String badge,
    String imageUrl,
  ) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFCDF200).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x26FFFFFF), width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141a),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ade80),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 12, color: Color(0xFFCDF200)),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCDF200),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFC5C9AC).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  eta.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                              ),
                              child: Text(
                                badge.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCDF200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'REQUEST',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2b3400),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          'METRICS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerEmergency() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFff4b4b).withOpacity(0.03),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFff4b4b).withOpacity(0.2), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFff4b4b).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFff4b4b).withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff4b4b).withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.offline_bolt, size: 30, color: Color(0xFFff4b4b)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POWER EMERGENCY',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'OUTAGE SUPPORT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFff4b4b).withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '  |  ',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFff4b4b).withOpacity(0.3),
                          ),
                        ),
                        Text(
                          '10 MIN SLA',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFff4b4b).withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
              ),
              child: Icon(Icons.chevron_right, size: 20, color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
