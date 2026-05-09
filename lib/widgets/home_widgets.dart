import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
//  TECHNICIAN CARD — Matches HTML "Nearby Technicians" section
// ═══════════════════════════════════════════════════════════
class PremiumTechnicianCard extends StatelessWidget {
  final String techId, name, job;
  final double rating, distance;
  final String? photoUrl;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback? onMessage;

  const PremiumTechnicianCard({
    super.key, required this.techId, required this.name, required this.job,
    required this.rating, required this.distance, this.photoUrl,
    required this.isAvailable, required this.onTap, this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 256,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + Info row
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.surfaceContainerHigh),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: photoUrl != null
                        ? Image.network(photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
                        : _defaultAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(job.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1.5),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.star_rounded, size: 14, color: AppColors.neonAccent),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      const SizedBox(width: 8),
                      Text('${distance.toStringAsFixed(1)} km', style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    ]),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badges
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (isAvailable) _badge('Available now', const Color(0xFF4ADE80), const Color(0xFF4ADE80)),
              _badge('Responds fast', AppColors.neonAccent, AppColors.neonAccent),
            ]),
            const SizedBox(height: 12),
            // CTA Buttons
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('View Profile', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurface))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.neonAccent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('Message', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onPrimaryFixed))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.20)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: textColor)),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(child: Icon(Icons.engineering_rounded, color: AppColors.onSurfaceVariant, size: 24)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RECENT MESSAGE TILE — Matches HTML "Recent Messages"
// ═══════════════════════════════════════════════════════════
class PremiumMessageTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final void Function(String otherId, String otherName) onTap;

  const PremiumMessageTile({super.key, required this.chatData, required this.currentUserId, required this.onTap});

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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(children: [
              // Avatar with online indicator
              Stack(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.20), width: 2),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatar(name))
                        : _avatar(name),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(name,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(timeStr, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 4),
                  Text(lastMessage,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _avatar(String name) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neonAccent))),
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

// ═══════════════════════════════════════════════════════════
//  SUGGESTION CARD — Matches HTML "Suggestions for you"
// ═══════════════════════════════════════════════════════════
class SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, ctaText;
  final IconData ctaIcon;
  final VoidCallback? onTap;

  const SuggestionCard({
    super.key, required this.icon, required this.title, required this.subtitle,
    required this.ctaText, required this.ctaIcon, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Stack(children: [
          // Background icon
          Positioned(top: -8, right: -8, child: Opacity(opacity: 0.08,
            child: Icon(icon, size: 72, color: AppColors.onSurface))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.neonAccent, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(ctaText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onPrimaryFixed)),
                const SizedBox(width: 6),
                Icon(ctaIcon, size: 16, color: AppColors.onPrimaryFixed),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHIMMER BOX — Loading skeleton animation
// ═══════════════════════════════════════════════════════════
class ShimmerBox extends StatefulWidget {
  final Widget child;
  const ShimmerBox({super.key, required this.child});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
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
