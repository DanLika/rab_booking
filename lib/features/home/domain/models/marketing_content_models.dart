import 'package:flutter/material.dart';

/// Destination data model for popular destinations section
class DestinationData {
  final String name;
  final String location; // Can be country, city, or region
  final String imageUrl;
  final int? propertyCount;

  const DestinationData({
    required this.name,
    required this.location,
    required this.imageUrl,
    this.propertyCount,
  });

  // For backwards compatibility (country → location)
  String get country => location;
}

/// How It Works step data model
class HowItWorksStep {
  final int? stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final String? iconName; // For database storage

  const HowItWorksStep({
    this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    this.iconName,
  });

  /// Create from database with icon name
  factory HowItWorksStep.fromIconName({
    int? stepNumber,
    required String title,
    required String description,
    required String iconName,
  }) {
    return HowItWorksStep(
      stepNumber: stepNumber,
      title: title,
      description: description,
      iconName: iconName,
      icon: _getIconFromName(iconName),
    );
  }

  /// Map icon names to IconData
  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'search':
        return Icons.search;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'beach_access':
        return Icons.beach_access;
      case 'home':
        return Icons.home;
      case 'payment':
        return Icons.payment;
      case 'check_circle':
        return Icons.check_circle;
      case 'hotel':
        return Icons.hotel;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      default:
        return Icons.help_outline; // Fallback icon
    }
  }
}

/// Testimonial data model
class TestimonialData {
  final String name; // Customer name
  final String quote;
  final double rating;
  final String? location; // Customer location
  final String? avatarUrl;
  final String? propertyStayedAt; // Property name

  const TestimonialData({
    required this.name,
    required this.quote,
    required this.rating,
    this.location,
    this.avatarUrl,
    this.propertyStayedAt,
  });

  // For backwards compatibility
  String get customerName => name;
  String? get customerAvatarUrl => avatarUrl;
  String? get customerLocation => location;
}

/// Default data for fallback when database is empty or unavailable

/// Default destinations - ALL from island of Rab, Croatia
const List<DestinationData> defaultDestinations = [
  DestinationData(
    name: 'Rab Town (Rab Grad)',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1588453251771-cd19dc5d75f4?w=800',
    propertyCount: 45,
  ),
  DestinationData(
    name: 'Lopar',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
    propertyCount: 32,
  ),
  DestinationData(
    name: 'Barbat',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
    propertyCount: 18,
  ),
  DestinationData(
    name: 'Kampor',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    propertyCount: 28,
  ),
  DestinationData(
    name: 'Suha Punta',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800',
    propertyCount: 15,
  ),
  DestinationData(
    name: 'Banjol',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
    propertyCount: 22,
  ),
  DestinationData(
    name: 'Mundanije',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=800',
    propertyCount: 12,
  ),
  DestinationData(
    name: 'Palit',
    location: 'Island of Rab, Croatia',
    imageUrl: 'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800',
    propertyCount: 10,
  ),
];

const List<HowItWorksStep> defaultSteps = [
  HowItWorksStep(
    stepNumber: 1,
    title: 'Search & Discover',
    description: 'Browse through our curated selection of premium properties',
    icon: Icons.search,
    iconName: 'search',
  ),
  HowItWorksStep(
    stepNumber: 2,
    title: 'Book Securely',
    description: 'Choose your dates and complete your booking with secure payment',
    icon: Icons.calendar_today,
    iconName: 'calendar_today',
  ),
  HowItWorksStep(
    stepNumber: 3,
    title: 'Enjoy Your Stay',
    description: 'Check in and enjoy your perfect vacation rental experience',
    icon: Icons.beach_access,
    iconName: 'beach_access',
  ),
];

const List<TestimonialData> defaultTestimonials = [
  TestimonialData(
    name: 'Maria Schmidt',
    quote: 'Absolutely stunning property! The view was breathtaking and the host was incredibly accommodating.',
    rating: 5.0,
    location: 'Berlin, Germany',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    propertyStayedAt: 'Villa Sunset',
  ),
  TestimonialData(
    name: 'John Williams',
    quote: 'Perfect family vacation! The apartment was spacious, clean, and perfectly located.',
    rating: 5.0,
    location: 'London, UK',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    propertyStayedAt: 'Apartment Mare Blu',
  ),
];
