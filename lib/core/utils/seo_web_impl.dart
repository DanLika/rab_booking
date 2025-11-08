// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:convert';

/// Web-specific implementation for SEO utilities
/// This file should only be imported on web platform
class SeoWebImpl {
  /// Update document title
  static void updateTitle(String title) {
    web.document.title = title;
  }

  /// Update or create meta tag
  static void updateMetaTag(String name, String content, {bool isProperty = false}) {
    final selector = isProperty ? 'meta[property="$name"]' : 'meta[name="$name"]';
    var meta = web.document.querySelector(selector) as web.HTMLMetaElement?;

    if (meta == null) {
      meta = web.document.createElement('meta') as web.HTMLMetaElement;
      if (isProperty) {
        meta.setAttribute('property', name);
      } else {
        meta.name = name;
      }
      web.document.head?.append(meta);
    }

    meta.content = content;
  }

  /// Update canonical link
  static void updateCanonical(String url) {
    var link = web.document.querySelector('link[rel="canonical"]') as web.HTMLLinkElement?;

    if (link == null) {
      link = web.document.createElement('link') as web.HTMLLinkElement;
      link.rel = 'canonical';
      web.document.head?.append(link);
    }

    link.href = url;
  }

  /// Add or update structured data (JSON-LD)
  static void updateStructuredData(Map<String, dynamic> data, {String? id}) {
    final scriptId = id ?? 'structured-data';

    // Remove existing script if present
    web.document.getElementById(scriptId)?.remove();

    // Create new script
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.id = scriptId;
    script.type = 'application/ld+json';
    script.text = jsonEncode(data);

    web.document.head?.append(script);
  }

  /// Remove all dynamic structured data scripts
  static void clearStructuredData() {
    final scripts = web.document.querySelectorAll('script[type="application/ld+json"]');
    for (var i = 0; i < scripts.length; i++) {
      final element = scripts.item(i) as web.HTMLScriptElement?;
      if (element != null && element.id.isNotEmpty) {
        element.remove();
      }
    }
  }

  /// Update all Open Graph tags
  static void updateOpenGraphTags({
    required String title,
    required String description,
    String? image,
    String? url,
    String type = 'website',
  }) {
    updateMetaTag('og:title', title, isProperty: true);
    updateMetaTag('og:description', description, isProperty: true);
    updateMetaTag('og:type', type, isProperty: true);

    if (image != null) {
      updateMetaTag('og:image', image, isProperty: true);
    }

    if (url != null) {
      updateMetaTag('og:url', url, isProperty: true);
    }
  }

  /// Update all Twitter Card tags
  static void updateTwitterCardTags({
    required String title,
    required String description,
    String? image,
    String cardType = 'summary_large_image',
  }) {
    updateMetaTag('twitter:card', cardType);
    updateMetaTag('twitter:title', title);
    updateMetaTag('twitter:description', description);

    if (image != null) {
      updateMetaTag('twitter:image', image);
    }
  }
}
