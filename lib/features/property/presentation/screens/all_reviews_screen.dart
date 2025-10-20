import 'package:flutter/material.dart';

/// Screen showing all reviews for a property
class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({
    required this.propertyId,
    required this.propertyName,
    required this.rating,
    required this.reviewCount,
    super.key,
  });

  final String propertyId;
  final String propertyName;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recenzije'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Property info header
          _PropertyHeader(
            propertyName: propertyName,
            rating: rating,
            reviewCount: reviewCount,
          ),

          const SizedBox(height: 24),

          // Rating breakdown
          const Text(
            'Ocjene po kategorijama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const _RatingBar(label: 'Čistoća', value: 4.8),
          const SizedBox(height: 12),
          const _RatingBar(label: 'Komunikacija', value: 4.9),
          const SizedBox(height: 12),
          const _RatingBar(label: 'Check-in', value: 4.7),
          const SizedBox(height: 12),
          const _RatingBar(label: 'Točnost opisa', value: 4.8),
          const SizedBox(height: 12),
          const _RatingBar(label: 'Lokacija', value: 4.9),
          const SizedBox(height: 12),
          const _RatingBar(label: 'Vrijednost za novac', value: 4.6),

          const SizedBox(height: 32),

          // All reviews list
          Text(
            'Sve recenzije ($reviewCount)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Placeholder reviews - in production, fetch from database
          ..._buildPlaceholderReviews(),
        ],
      ),
    );
  }

  List<Widget> _buildPlaceholderReviews() {
    // In production, this would fetch reviews from the database
    // For now, showing placeholder data
    final reviews = [
      {
        'name': 'Marko P.',
        'date': 'Kolovoz 2024',
        'rating': 5.0,
        'comment':
            'Predivan smještaj! Lokacija je odlična, blizu plaže. Vlasnik je vrlo ljubazan i susretljiv. Sve je bilo kako je opisano. Definitivno preporučujem!'
      },
      {
        'name': 'Ana K.',
        'date': 'Srpanj 2024',
        'rating': 4.5,
        'comment':
            'Vrlo lijepo uređen apartman, čisto i uredno. Pogled s balkona je prekrasan. Jedino što bi bilo dobro je više parking prostora. Sve preporuke!'
      },
      {
        'name': 'Ivan D.',
        'date': 'Lipanj 2024',
        'rating': 5.0,
        'comment':
            'Odličan smještaj za obitelj. Blizina mora i privatnost su nam se jako svidjeli. Vlasnik je vrlo fleksibilan oko check-in vremena.'
      },
      {
        'name': 'Petra S.',
        'date': 'Svibanj 2024',
        'rating': 4.8,
        'comment':
            'Sve pohvale za čistoću i urednost! Apartman ima sve što je potrebno za ugodan odmor. Lokacija je mirna i tiha.'
      },
      {
        'name': 'Luka M.',
        'date': 'Rujan 2023',
        'rating': 4.7,
        'comment':
            'Odličan omjer cijene i kvalitete. Sve je funkcionalno i uredno. Internet radi odlično što nam je bilo važno.'
      },
      {
        'name': 'Maja V.',
        'date': 'Kolovoz 2023',
        'rating': 5.0,
        'comment':
            'Prekrasan odmor! Apartman je još ljepši uživo nego na fotografijama. Preporučujemo!'
      },
    ];

    return reviews
        .map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ReviewCard(
                name: review['name'] as String,
                date: review['date'] as String,
                rating: review['rating'] as double,
                comment: review['comment'] as String,
              ),
            ))
        .toList();
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({
    required this.propertyName,
    required this.rating,
    required this.reviewCount,
  });

  final String propertyName;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            propertyName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, size: 32, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '($reviewCount recenzija)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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
