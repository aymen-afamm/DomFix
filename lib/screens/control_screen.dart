import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.settings_remote_rounded, size: 36, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 20),
              Text('Smart Control', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 8),
              Text('Device control coming soon', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
