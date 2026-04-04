import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/technician_onboarding_data.dart';
import '../../theme/app_colors.dart';
import 'professional_identity_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Technician Onboarding Flow
//
// Central controller that manages navigation between all 6 onboarding steps.
// Each step receives the shared [TechnicianOnboardingData] and mutates it.
// ─────────────────────────────────────────────────────────────────────────────

class TechnicianOnboardingFlow extends StatefulWidget {
  /// Callback fired when the entire flow is complete.
  final void Function(TechnicianOnboardingData data)? onComplete;

  const TechnicianOnboardingFlow({super.key, this.onComplete});

  @override
  State<TechnicianOnboardingFlow> createState() =>
      _TechnicianOnboardingFlowState();
}

class _TechnicianOnboardingFlowState extends State<TechnicianOnboardingFlow> {
  final _pageController = PageController();
  final _data = TechnicianOnboardingData();
  int _currentStep = 0;

  static const int _totalSteps = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Flow complete
      HapticFeedback.mediumImpact();
      widget.onComplete?.call(_data);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // controlled programmatically
      children: [
        // ── Step 1 ────────────────────────────────────────────────────────────
        ProfessionalIdentityScreen(
          onboardingData: _data,
          onNext: _goNext,
          onBack: _goBack,
        ),

        // ── Steps 2–6 (placeholder screens until they are designed) ──────────
        for (int i = 2; i <= _totalSteps; i++)
          _PlaceholderStepScreen(
            step: i,
            totalSteps: _totalSteps,
            onNext: _goNext,
            onBack: _goBack,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder for steps 2–6
// Replace with real screens as designs arrive.
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderStepScreen extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PlaceholderStepScreen({
    required this.step,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primaryContainer,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'STEP $step OF $totalSteps',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Coming soon…',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        'BACK',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: const Color(0xFF2B3400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      child: Text(
                        step == 6 ? 'SUBMIT' : 'NEXT',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
