/// Stub implementation for non-web platforms
/// This is used when compiling for mobile/desktop
class SeoWebImpl {
  static void updateTitle(String title) {}
  static void updateMetaTag(
    String name,
    String content, {
    bool isProperty = false,
  }) {}
  static void updateCanonical(String url) {}
  static void updateStructuredData(Map<String, dynamic> data, {String? id}) {}
  static void updateOpenGraphTags({
    required String title,
    required String description,
    String? image,
    String? url,
    String type = 'website',
  }) {}
  static void updateTwitterCardTags({
    required String title,
    required String description,
    String? image,
    String cardType = 'summary_large_image',
  }) {}
}
