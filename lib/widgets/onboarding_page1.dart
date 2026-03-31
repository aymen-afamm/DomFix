import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          right: -80,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.05),
                  AppColors.background.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          left: -80,
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.05),
                  AppColors.background.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeroVisual(),
              const SizedBox(height: 48),
              _buildContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.05),
                  AppColors.background.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonAccent.withValues(alpha: 0.3),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 64,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: 'AI-Powered '),
                TextSpan(
                  text: 'Diagnosis',
                  style: TextStyle(color: AppColors.primaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Describe your home issue and let our intelligence find the fix.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
