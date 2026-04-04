/// Holds all data collected during the Technician onboarding flow.
///
/// This model is passed forward through all 6 steps and submitted
/// to the backend at the final step.
class TechnicianOnboardingData {
  // ── Step 1 – Professional Identity ────────────────────────────────────────
  String? profilePhotoUrl; // Cloudinary secure_url
  String? fullName;
  int? age;
  String? city;
  String? bio;

  // ── Step 2 – (future screens will add fields here) ────────────────────────
  List<String> portfolioUrls = [];        // Cloudinary secure_urls
  List<String> certificationUrls = [];   // Cloudinary secure_urls

  TechnicianOnboardingData();

  /// Returns true when the mandatory Step-1 fields are complete.
  bool get isStep1Complete =>
      profilePhotoUrl != null &&
      profilePhotoUrl!.isNotEmpty &&
      fullName != null &&
      fullName!.trim().isNotEmpty &&
      city != null &&
      city!.trim().isNotEmpty;

  @override
  String toString() => 'TechnicianOnboardingData('
      'fullName: $fullName, '
      'city: $city, '
      'profilePhotoUrl: $profilePhotoUrl, '
      'portfolioUrls: $portfolioUrls, '
      'certificationUrls: $certificationUrls)';
}
