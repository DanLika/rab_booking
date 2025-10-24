// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Web-specific implementation for SEO utilities
/// This file should only be imported on web platform
class SeoWebImpl {
  /// Update document title
  static void updateTitle(String title) {
    html.document.title = title;
  }

  /// Update or create meta tag
  static void updateMetaTag(String name, String content, {bool isProperty = false}) {
    final selector = isProperty ? 'meta[property="$name"]' : 'meta[name="$name"]';
    var meta = html.document.querySelector(selector) as html.MetaElement?;

    if (meta == null) {
      meta = html.MetaElement();
      if (isProperty) {
        meta.setAttribute('property', name);
      } else {
        meta.name = name;
      }
      html.document.head?.append(meta);
    }

    meta.content = content;
  }

  /// Update canonical link
  static void updateCanonical(String url) {
    var link = html.document.querySelector('link[rel="canonical"]') as html.LinkElement?;

    if (link == null) {
      link = html.LinkElement();
      link.rel = 'canonical';
      html.document.head?.append(link);
    }

    link.href = url;
  }

  /// Add or update structured data (JSON-LD)
  static void updateStructuredData(Map<String, dynamic> data, {String? id}) {
    final scriptId = id ?? 'structured-data';

    // Remove existing script if present
    html.document.getElementById(scriptId)?.remove();

    // Create new script
    final script = html.ScriptElement();
    script.id = scriptId;
    script.type = 'application/ld+json';
    script.text = jsonEncode(data);

    html.document.head?.append(script);
  }

  /// Remove all dynamic structured data scripts
  static void clearStructuredData() {
    html.document.querySelectorAll('script[type="application/ld+json"]')
      .where((element) => element.id.isNotEmpty)
      .forEach((element) => element.remove());
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
