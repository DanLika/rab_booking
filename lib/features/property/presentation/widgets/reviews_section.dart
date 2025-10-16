import 'package:flutter/material.dart';

/// Reviews section (placeholder for now, will be implemented with real data later)
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    required this.rating,
    required this.reviewCount,
    super.key,
  });

  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, size: 28, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '($reviewCount recenzija)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Rating breakdown (placeholder)
        _RatingBar(label: 'Čistoća', value: 4.8),
        const SizedBox(height: 12),
        _RatingBar(label: 'Komunikacija', value: 4.9),
        const SizedBox(height: 12),
        _RatingBar(label: 'Check-in', value: 4.7),
        const SizedBox(height: 12),
        _RatingBar(label: 'Točnost opisa', value: 4.8),
        const SizedBox(height: 12),
        _RatingBar(label: 'Lokacija', value: 4.9),
        const SizedBox(height: 12),
        _RatingBar(label: 'Vrijednost za novac', value: 4.6),

        const SizedBox(height: 32),

        // Individual reviews (placeholder)
        Text(
          'Recenzije gostiju',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        _ReviewCard(
          name: 'Marko P.',
          date: 'Kolovoz 2024',
          rating: 5.0,
          comment:
              'Predivan smještaj! Lokacija je odlična, blizu plaže. Vlasnik je vrlo ljubazan i susretljiv.',
        ),
        const SizedBox(height: 16),
        _ReviewCard(
          name: 'Ana K.',
          date: 'Srpanj 2024',
          rating: 4.5,
          comment:
              'Vrlo lijepo uređen apartman, čisto i uredno. Sve preporuke!',
        ),

        const SizedBox(height: 24),

        // Show all button
        OutlinedButton(
          onPressed: () {
            // TODO: Navigate to all reviews screen
          },
          child: Text('Prikaži svih $reviewCount recenzija'),
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / 5.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
  });

  final String name;
  final String date;
  final double rating;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
