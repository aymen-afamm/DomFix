class BookingEstimate {
  final int durationMinutes;
  final int minPrice;
  final int maxPrice;
  final int technicianFee;
  final int platformFee;

  const BookingEstimate({
    required this.durationMinutes,
    required this.minPrice,
    required this.maxPrice,
    required this.technicianFee,
    required this.platformFee,
  });

  Map<String, dynamic> toMap() {
    return {
      'durationMinutes': durationMinutes,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'technicianFee': technicianFee,
      'platformFee': platformFee,
    };
  }
}

class BookingDraft {
  final String? bookingId;
  final String technicianId;
  final String technicianName;
  final String service;
  final DateTime scheduledAt;
  final String timeSlot;
  final String description;
  final String urgency;
  final List<String> imageUrls;
  final BookingEstimate estimate;

  const BookingDraft({
    this.bookingId,
    required this.technicianId,
    required this.technicianName,
    required this.service,
    required this.scheduledAt,
    required this.timeSlot,
    required this.description,
    required this.urgency,
    required this.imageUrls,
    required this.estimate,
  });
}
