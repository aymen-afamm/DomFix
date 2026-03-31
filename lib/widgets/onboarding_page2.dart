import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
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
          bottom: 0,
          left: 0,
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
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMapVisual(),
              const SizedBox(height: 48),
              _buildContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapVisual() {
    return SizedBox(
      width: 320,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 60,
            left: 40,
            child: _buildTechnicianCard(
              name: 'Marcus V.',
              role: 'Master Electrician',
              rating: '4.9',
              alignment: Alignment.centerLeft,
            ),
          ),
          Positioned(
            bottom: 80,
            right: 40,
            child: _buildTechnicianCard(
              name: 'Elena S.',
              role: 'HVAC Specialist',
              rating: '4.9',
              alignment: Alignment.centerRight,
            ),
          ),
          Center(
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.engineering,
                    size: 48,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard({
    required String name,
    required String role,
    required String rating,
    required Alignment alignment,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: alignment == Alignment.centerLeft
              ? BorderSide(color: AppColors.primaryContainer, width: 2)
              : BorderSide.none,
          right: alignment == Alignment.centerRight
              ? BorderSide(color: AppColors.primaryContainer, width: 2)
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            _buildAvatar(),
            const SizedBox(width: 12),
            _buildInfo(role, name),
            const SizedBox(width: 12),
            _buildRating(rating),
          ] else ...[
            _buildInfo(role, name),
            const SizedBox(width: 12),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHighest,
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.person,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              border: Border.all(color: AppColors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonAccent.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String role, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          role.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRating(String rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: AppColors.primaryContainer,
        ),
        const SizedBox(width: 4),
        Text(
          rating,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryContainer,
          ),
        ),
      ],
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
                const TextSpan(text: 'ELITE '),
                TextSpan(
                  text: 'TECHNICIANS',
                  style: TextStyle(color: AppColors.primaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with certified pros in minutes. Simple, fast, reliable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
