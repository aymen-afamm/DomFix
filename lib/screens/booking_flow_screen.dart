import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../theme/app_colors.dart';
import 'booking_confirmation_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final String technicianId;
  final String technicianName;
  final String technicianJob;

  const BookingFlowScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
    required this.technicianJob,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen>
    with TickerProviderStateMixin {
  final _bookingService = BookingService();
  final _pageController = PageController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<String> _services = const [];
  String? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  String _urgency = 'Normal';
  final List<XFile> _images = [];
  bool _loadingServices = true;
  bool _submitting = false;
  int _step = 0;

  BookingEstimate? get _estimate {
    if (_selectedService == null) return null;
    return _bookingService.estimate(
      service: _selectedService!,
      urgency: _urgency,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _bookingService.loadTechnicianServices(
        widget.technicianId,
      );
      if (!mounted) return;
      setState(() {
        _services = services;
        _loadingServices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _services = const [
          'Electrical Repair',
          'Smart Home Installation',
          'IoT Setup',
          'Wiring',
          'Maintenance',
        ];
        _loadingServices = false;
      });
    }
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _selectedService != null,
      1 => _selectedSlot != null,
      2 => _descriptionController.text.trim().length >= 12,
      3 => _estimate != null,
      _ => true,
    };
  }

  void _goNext() {
    if (!_canContinue || _submitting) return;
    HapticFeedback.lightImpact();
    if (_step == 4) {
      _confirmBooking();
      return;
    }
    setState(() => _step += 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 75);
    if (picked.isEmpty) return;
    setState(() {
      final remaining = 4 - _images.length;
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedService == null ||
        _selectedSlot == null ||
        _estimate == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final bookingId = FirebaseFirestore.instance
          .collection('bookings')
          .doc()
          .id;
      final imageUrls = <String>[];
      for (final image in _images) {
        final url = await _bookingService.uploadBookingImage(
          bookingId: bookingId,
          imageFile: File(image.path),
        );
        imageUrls.add(url);
      }

      final createdBookingId = await _bookingService.createBooking(
        BookingDraft(
          bookingId: bookingId,
          technicianId: widget.technicianId,
          technicianName: widget.technicianName,
          service: _selectedService!,
          scheduledAt: BookingService.combineDateAndSlot(
            _selectedDate,
            _selectedSlot!,
          ),
          timeSlot: _selectedSlot!,
          description: _descriptionController.text.trim(),
          urgency: _urgency,
          imageUrls: imageUrls,
          estimate: _estimate!,
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            bookingId: createdBookingId,
            technicianId: widget.technicianId,
            technicianName: widget.technicianName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceStep(),
                  _buildScheduleStep(),
                  _buildDescriptionStep(),
                  _buildEstimateStep(),
                  _buildConfirmStep(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book ${widget.technicianName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  widget.technicianJob,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (index) {
              final active = index <= _step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 3,
                  margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.neonAccent : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'STEP ${_step + 1} OF 5',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: AppColors.neonAccent,
                ),
              ),
              const Spacer(),
              Text(
                _stepTitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    return const [
      'Select service',
      'Date and time',
      'Problem details',
      'Price estimate',
      'Confirm',
    ][_step];
  }

  Widget _buildServiceStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        _StepIntro(
          title: 'Choose the service',
          subtitle:
              'Pick the exact work you want ${widget.technicianName} to handle.',
        ),
        const SizedBox(height: 22),
        if (_loadingServices)
          ...List.generate(4, (_) => const _SkeletonCard())
        else
          ..._services.map((service) {
            final selected = _selectedService == service;
            return _SelectableCard(
              selected: selected,
              icon: _iconForService(service),
              title: service,
              subtitle: selected
                  ? 'Selected for this booking'
                  : 'Available service',
              onTap: () => setState(() => _selectedService = service),
            );
          }),
      ],
    );
  }

  Widget _buildScheduleStep() {
    final slots = BookingService.timeSlotsFor(_selectedDate);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const _StepIntro(
          title: 'Pick a time window',
          subtitle: 'Past dates are blocked and busy slots update live.',
        ),
        const SizedBox(height: 22),
        _buildDateStrip(),
        const SizedBox(height: 20),
        StreamBuilder<Set<String>>(
          stream: _bookingService.watchUnavailableSlots(
            technicianId: widget.technicianId,
            date: _selectedDate,
          ),
          builder: (context, snapshot) {
            final unavailable = snapshot.data ?? const <String>{};
            if (slots.isEmpty) {
              return _InfoCard(
                icon: Icons.event_busy_rounded,
                title: 'No slots left today',
                text: 'Choose another date to continue.',
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots.map((slot) {
                final disabled = unavailable.contains(slot);
                final selected = _selectedSlot == slot && !disabled;
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () => setState(() => _selectedSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.neonAccent
                          : disabled
                          ? AppColors.surface.withValues(alpha: 0.45)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.neonAccent
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      disabled ? '$slot Busy' : slot,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.onPrimary
                            : disabled
                            ? AppColors.onSurfaceVariant.withValues(alpha: 0.35)
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateStrip() {
    final today = DateTime.now();
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = DateTime(today.year, today.month, today.day + index);
          final selected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = date;
              _selectedSlot = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 68,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.neonAccent : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.neonAccent : AppColors.divider,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionStep() {
    final count = _descriptionController.text.characters.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const _StepIntro(
          title: 'Describe the problem',
          subtitle:
              'A clear brief helps the technician prepare before arrival.',
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _descriptionController,
          maxLines: 6,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            counterText: '$count/500',
            hintText:
                'Example: Kitchen smart switch stopped responding after a power cut...',
            hintStyle: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.neonAccent),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Urgency',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['Normal', 'Urgent', 'Emergency'].map((urgency) {
            final selected = _urgency == urgency;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _urgency = urgency),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? _urgencyColor(urgency).withValues(alpha: 0.18)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _urgencyColor(urgency)
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      urgency,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? _urgencyColor(urgency)
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _buildImagePicker(),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              'Optional',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _images.length >= 4 ? null : _pickImages,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.neonAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _images.isEmpty
                        ? 'Add up to 4 photos'
                        : '${_images.length} photo${_images.length == 1 ? '' : 's'} selected',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_images[index].path),
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstimateStep() {
    final estimate = _estimate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const _StepIntro(
          title: 'Transparent estimate',
          subtitle: 'Final pricing can adjust after technician inspection.',
        ),
        const SizedBox(height: 22),
        if (estimate != null) _EstimateCard(estimate: estimate),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.verified_outlined,
          title: 'No surprise fees',
          text:
              'The technician sees this estimate with your request before accepting.',
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final estimate = _estimate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const _StepIntro(
          title: 'Confirm booking',
          subtitle: 'Review the details before we send the request.',
        ),
        const SizedBox(height: 22),
        _SummaryRow(
          icon: Icons.build_rounded,
          label: 'Service',
          value: _selectedService ?? '',
        ),
        _SummaryRow(
          icon: Icons.event_rounded,
          label: 'Date',
          value: _formatDate(_selectedDate),
        ),
        _SummaryRow(
          icon: Icons.schedule_rounded,
          label: 'Time',
          value: _selectedSlot ?? '',
        ),
        _SummaryRow(
          icon: Icons.priority_high_rounded,
          label: 'Urgency',
          value: _urgency,
        ),
        if (estimate != null)
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'Estimate',
            value: '\$${estimate.minPrice}-\$${estimate.maxPrice}',
          ),
        _SummaryRow(
          icon: Icons.image_outlined,
          label: 'Images',
          value: _images.isEmpty ? 'None' : '${_images.length} attached',
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _submitting ? null : _goBack,
            child: Text(
              _step == 0 ? 'Close' : 'Back',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canContinue && !_submitting ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonAccent,
                disabledBackgroundColor: AppColors.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                foregroundColor: AppColors.onPrimary,
                disabledForegroundColor: AppColors.onSurfaceVariant.withValues(
                  alpha: 0.45,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _step == 4 ? 'Confirm Booking' : 'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForService(String service) {
    final lower = service.toLowerCase();
    if (lower.contains('smart') || lower.contains('iot')) {
      return Icons.settings_remote_rounded;
    }
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('wiring') || lower.contains('electric')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('maintenance')) return Icons.handyman_rounded;
    return Icons.home_repair_service_rounded;
  }

  Color _urgencyColor(String urgency) {
    return switch (urgency) {
      'Emergency' => AppColors.emergency,
      'Urgent' => Colors.orange,
      _ => AppColors.neonAccent,
    };
  }

  String _weekday(DateTime date) {
    const values = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return values[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StepIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepIntro({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.neonAccent.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.neonAccent : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.neonAccent.withValues(alpha: 0.16)
                      : AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.neonAccent
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.neonAccent
                            : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.neonAccent
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final BookingEstimate estimate;

  const _EstimateCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonAccent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '\$${estimate.minPrice}-\$${estimate.maxPrice}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonAccent,
                  ),
                ),
              ),
              Text(
                '${estimate.durationMinutes} min',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PriceLine(
            label: 'Technician fee',
            value: '\$${estimate.technicianFee}',
          ),
          _PriceLine(label: 'Platform fee', value: '\$${estimate.platformFee}'),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;

  const _PriceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
