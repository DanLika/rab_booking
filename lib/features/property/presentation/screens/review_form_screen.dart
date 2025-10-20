import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/repositories/reviews_repository.dart';

/// Review Form Screen - Create or Edit Review
class ReviewFormScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String bookingId;
  final String propertyName;
  final PropertyReview? existingReview; // For editing

  const ReviewFormScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
    required this.propertyName,
    this.existingReview,
  });

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _overallRating = 0;
  int? _cleanlinessRating;
  int? _communicationRating;
  int? _checkinRating;
  int? _accuracyRating;
  int? _locationRating;
  int? _valueRating;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing
    if (widget.existingReview != null) {
      final review = widget.existingReview!;
      _overallRating = review.rating;
      _commentController.text = review.comment;
      _cleanlinessRating = review.cleanlinessRating;
      _communicationRating = review.communicationRating;
      _checkinRating = review.checkinRating;
      _accuracyRating = review.accuracyRating;
      _locationRating = review.locationRating;
      _valueRating = review.valueRating;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_overallRating == 0) {
      _showSnackBar('Molimo ocenite boravak', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(reviewsRepositoryProvider);

      if (widget.existingReview != null) {
        // Update existing review
        await repository.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _overallRating,
          comment: _commentController.text,
          cleanlinessRating: _cleanlinessRating,
          communicationRating: _communicationRating,
          checkinRating: _checkinRating,
          accuracyRating: _accuracyRating,
          locationRating: _locationRating,
          valueRating: _valueRating,
        );

        if (mounted) {
          _showSnackBar('Recenzija uspešno ažurirana!', isError: false);
        }
      } else {
        // Create new review
        await repository.createReview(
          propertyId: widget.propertyId,
          bookingId: widget.bookingId,
          rating: _overallRating,
          comment: _commentController.text,
          cleanlinessRating: _cleanlinessRating,
          communicationRating: _communicationRating,
          checkinRating: _checkinRating,
          accuracyRating: _accuracyRating,
          locationRating: _locationRating,
          valueRating: _valueRating,
        );

        if (mounted) {
          _showSnackBar('Recenzija uspešno objavljena!', isError: false);
        }
      }

      if (mounted) {
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Greška: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Izmeni Recenziju' : 'Napiši Recenziju'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property Name
              Text(
                widget.propertyName,
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Kako je bio vaš boravak?',
                style: AppTypography.bodyLarge.copyWith(
                  color: context.textColorSecondary,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Overall Rating
              Text(
                'Ukupna Ocena',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              _buildStarRating(
                rating: _overallRating,
                onRatingChanged: (rating) {
                  setState(() => _overallRating = rating);
                },
                large: true,
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Comment
              Text(
                'Vaša Recenzija',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              TextFormField(
                controller: _commentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'Opišite vaše iskustvo... (minimum 50 karaktera)',
                  filled: true,
                  fillColor: context.surfaceVariantColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Molimo unesite recenziju';
                  }
                  if (value.length < 50) {
                    return 'Recenzija mora imati najmanje 50 karaktera';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Detailed Ratings (Optional)
              Text(
                'Detaljne Ocene (Opciono)',
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),

              _buildDetailedRating(
                label: 'Čistoća',
                icon: Icons.cleaning_services,
                rating: _cleanlinessRating,
                onRatingChanged: (rating) {
                  setState(() => _cleanlinessRating = rating);
                },
              ),

              _buildDetailedRating(
                label: 'Komunikacija',
                icon: Icons.chat_bubble_outline,
                rating: _communicationRating,
                onRatingChanged: (rating) {
                  setState(() => _communicationRating = rating);
                },
              ),

              _buildDetailedRating(
                label: 'Check-in',
                icon: Icons.key,
                rating: _checkinRating,
                onRatingChanged: (rating) {
                  setState(() => _checkinRating = rating);
                },
              ),

              _buildDetailedRating(
                label: 'Tačnost Opisa',
                icon: Icons.verified,
                rating: _accuracyRating,
                onRatingChanged: (rating) {
                  setState(() => _accuracyRating = rating);
                },
              ),

              _buildDetailedRating(
                label: 'Lokacija',
                icon: Icons.location_on,
                rating: _locationRating,
                onRatingChanged: (rating) {
                  setState(() => _locationRating = rating);
                },
              ),

              _buildDetailedRating(
                label: 'Vrednost za Novac',
                icon: Icons.attach_money,
                rating: _valueRating,
                onRatingChanged: (rating) {
                  setState(() => _valueRating = rating);
                },
              ),

              const SizedBox(height: AppDimensions.spaceXL * 2),

              // Submit Button
              PremiumButton.primary(
                label: _isSubmitting
                    ? 'Šaljem...'
                    : (isEditing ? 'Ažuriraj Recenziju' : 'Objavi Recenziju'),
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting ? null : Icons.send,
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Cancel Button
              PremiumButton.text(
                label: 'Otkaži',
                onPressed: _isSubmitting ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating({
    required int rating,
    required Function(int) onRatingChanged,
    bool large = false,
  }) {
    final size = large ? 48.0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= rating ? Icons.star : Icons.star_border,
            color: starIndex <= rating ? AppColors.warning : Colors.grey,
            size: size,
          ),
          onPressed: () => onRatingChanged(starIndex),
        );
      }),
    );
  }

  Widget _buildDetailedRating({
    required String label,
    required IconData icon,
    required int? rating,
    required Function(int?) onRatingChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.textColorSecondary),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Row(
            children: [
              ...List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= (rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: starIndex <= (rating ?? 0)
                        ? AppColors.warning
                        : Colors.grey,
                  ),
                  onPressed: () => onRatingChanged(starIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              }),
              const SizedBox(width: AppDimensions.spaceS),
              if (rating != null)
                TextButton(
                  onPressed: () => onRatingChanged(null),
                  child: Text(
                    'Obriši',
                    style: AppTypography.small.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
