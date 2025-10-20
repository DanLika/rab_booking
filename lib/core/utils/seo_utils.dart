import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// SEO utilities for web platform
/// Provides meta tags, structured data, and SEO optimizations
class SEOUtils {
  SEOUtils._();

  /// Check if SEO features are available (web only)
  static bool get isSupported => PlatformUtils.isWeb;

  /// Set page title
  /// Usage: SEOUtils.setTitle('Property Details | Rab Booking');
  static void setTitle(String title) {
    if (!isSupported) return;
    // In a real implementation, you would use dart:html
    // html.document.title = title;
    debugPrint('[SEO] Setting title: $title');
  }

  /// Set meta description
  static void setDescription(String description) {
    if (!isSupported) return;
    // In a real implementation, you would update meta tags
    debugPrint('[SEO] Setting description: $description');
  }

  /// Set meta keywords
  static void setKeywords(List<String> keywords) {
    if (!isSupported) return;
    final keywordsString = keywords.join(', ');
    debugPrint('[SEO] Setting keywords: $keywordsString');
  }

  /// Set Open Graph meta tags for social sharing
  static void setOpenGraph({
    required String title,
    required String description,
    String? image,
    String? url,
    String? type,
  }) {
    if (!isSupported) return;
    debugPrint('[SEO] Setting Open Graph:');
    debugPrint('  - title: $title');
    debugPrint('  - description: $description');
    debugPrint('  - image: $image');
    debugPrint('  - url: $url');
    debugPrint('  - type: ${type ?? "website"}');
  }

  /// Set Twitter Card meta tags
  static void setTwitterCard({
    required String title,
    required String description,
    String? image,
    String? site,
    String cardType = 'summary_large_image',
  }) {
    if (!isSupported) return;
    debugPrint('[SEO] Setting Twitter Card:');
    debugPrint('  - card: $cardType');
    debugPrint('  - title: $title');
    debugPrint('  - description: $description');
    debugPrint('  - image: $image');
    debugPrint('  - site: $site');
  }

  /// Add structured data (JSON-LD) for rich snippets
  static void addStructuredData(Map<String, dynamic> data) {
    if (!isSupported) return;
    debugPrint('[SEO] Adding structured data: $data');
  }

  /// Set canonical URL
  static void setCanonical(String url) {
    if (!isSupported) return;
    debugPrint('[SEO] Setting canonical URL: $url');
  }

  /// Add breadcrumb structured data
  static void addBreadcrumbs(List<BreadcrumbItem> items) {
    if (!isSupported) return;

    final breadcrumbList = {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': items.asMap().entries.map((entry) {
        return {
          '@type': 'ListItem',
          'position': entry.key + 1,
          'name': entry.value.name,
          'item': entry.value.url,
        };
      }).toList(),
    };

    addStructuredData(breadcrumbList);
  }

  /// Add Product structured data for property listing
  static void addProductData({
    required String name,
    required String description,
    required String image,
    required double price,
    required String currency,
    required String url,
    double? rating,
    int? reviewCount,
  }) {
    if (!isSupported) return;

    final productData = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': name,
      'description': description,
      'image': image,
      'url': url,
      'offers': {
        '@type': 'Offer',
        'price': price.toString(),
        'priceCurrency': currency,
        'availability': 'https://schema.org/InStock',
      },
      if (rating != null && reviewCount != null)
        'aggregateRating': {
          '@type': 'AggregateRating',
          'ratingValue': rating.toString(),
          'reviewCount': reviewCount.toString(),
        },
    };

    addStructuredData(productData);
  }

  /// Add LocalBusiness structured data
  static void addLocalBusinessData({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String url,
    String? image,
    double? latitude,
    double? longitude,
  }) {
    if (!isSupported) return;

    final businessData = {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': name,
      'description': description,
      'address': address,
      'telephone': phone,
      'url': url,
      if (image != null) 'image': image,
      if (latitude != null && longitude != null)
        'geo': {
          '@type': 'GeoCoordinates',
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
    };

    addStructuredData(businessData);
  }

  /// Add Organization structured data
  static void addOrganizationData({
    required String name,
    required String url,
    String? logo,
    String? description,
  }) {
    if (!isSupported) return;

    final orgData = {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      'name': name,
      'url': url,
      if (logo != null) 'logo': logo,
      if (description != null) 'description': description,
    };

    addStructuredData(orgData);
  }
}

/// Breadcrumb item for SEO
class BreadcrumbItem {
  final String name;
  final String url;

  const BreadcrumbItem({
    required this.name,
    required this.url,
  });
}

/// Widget that sets SEO metadata for a page
class SEOPage extends StatefulWidget {
  /// Page title
  final String title;

  /// Meta description
  final String? description;

  /// Meta keywords
  final List<String>? keywords;

  /// Open Graph image
  final String? image;

  /// Canonical URL
  final String? canonicalUrl;

  /// Breadcrumbs
  final List<BreadcrumbItem>? breadcrumbs;

  /// Structured data
  final Map<String, dynamic>? structuredData;

  /// Child widget
  final Widget child;

  const SEOPage({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.keywords,
    this.image,
    this.canonicalUrl,
    this.breadcrumbs,
    this.structuredData,
  });

  @override
  State<SEOPage> createState() => _SEOPageState();
}

class _SEOPageState extends State<SEOPage> {
  @override
  void initState() {
    super.initState();
    _updateSEO();
  }

  @override
  void didUpdateWidget(SEOPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.description != widget.description) {
      _updateSEO();
    }
  }

  void _updateSEO() {
    if (!SEOUtils.isSupported) return;

    // Set title
    SEOUtils.setTitle(widget.title);

    // Set description
    if (widget.description != null) {
      SEOUtils.setDescription(widget.description!);
    }

    // Set keywords
    if (widget.keywords != null) {
      SEOUtils.setKeywords(widget.keywords!);
    }

    // Set canonical URL
    if (widget.canonicalUrl != null) {
      SEOUtils.setCanonical(widget.canonicalUrl!);
    }

    // Set Open Graph
    if (widget.description != null) {
      SEOUtils.setOpenGraph(
        title: widget.title,
        description: widget.description!,
        image: widget.image,
        url: widget.canonicalUrl,
      );
    }

    // Set Twitter Card
    if (widget.description != null) {
      SEOUtils.setTwitterCard(
        title: widget.title,
        description: widget.description!,
        image: widget.image,
      );
    }

    // Add breadcrumbs
    if (widget.breadcrumbs != null) {
      SEOUtils.addBreadcrumbs(widget.breadcrumbs!);
    }

    // Add structured data
    if (widget.structuredData != null) {
      SEOUtils.addStructuredData(widget.structuredData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Example usage:
///
/// ```dart
/// SEOPage(
///   title: 'Luxury Villa in Rab | Rab Booking',
///   description: 'Beautiful 4-bedroom villa with sea view, pool, and modern amenities in Rab, Croatia.',
///   keywords: ['villa', 'rab', 'croatia', 'vacation rental', 'sea view'],
///   image: 'https://example.com/images/villa.jpg',
///   canonicalUrl: 'https://rabbooking.com/property/123',
///   breadcrumbs: [
///     BreadcrumbItem(name: 'Home', url: 'https://rabbooking.com'),
///     BreadcrumbItem(name: 'Search', url: 'https://rabbooking.com/search'),
///     BreadcrumbItem(name: 'Villa', url: 'https://rabbooking.com/property/123'),
///   ],
///   child: PropertyDetailsScreen(),
/// )
/// ```
