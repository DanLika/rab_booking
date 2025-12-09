import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/app_colors.dart';

/// Dialog that generates and displays embed code for widget
///
/// Supports two URL formats:
/// 1. Query params: `?property=PROPERTY_ID&unit=UNIT_ID` (iframe embeds)
/// 2. Slug URL: `/apartman-6` with subdomain (standalone/shareable pages)
class EmbedCodeGeneratorDialog extends StatefulWidget {
  const EmbedCodeGeneratorDialog({
    required this.unitId,
    required this.propertyId,
    this.unitName,
    this.propertySubdomain,
    this.unitSlug,
    super.key,
  });

  final String unitId;
  final String propertyId;
  final String? unitName;
  final String? propertySubdomain;

  /// Optional unit slug for clean URL generation.
  /// When provided, generates shareable slug-based URLs.
  final String? unitSlug;

  @override
  State<EmbedCodeGeneratorDialog> createState() => _EmbedCodeGeneratorDialogState();
}

class _EmbedCodeGeneratorDialogState extends State<EmbedCodeGeneratorDialog> {
  // Note: Language selector removed - widget has its own language picker in header
  String _widgetHeight = '700'; // Lower default since widget auto-resizes

  static const String _defaultWidgetBaseUrl = 'https://bookbed.io';
  static const String _subdomainBaseDomain = 'bookbed.io';

  /// Get the base URL - use subdomain if available, otherwise default
  String get _widgetBaseUrl {
    if (widget.propertySubdomain != null && widget.propertySubdomain!.isNotEmpty) {
      return 'https://${widget.propertySubdomain}.$_subdomainBaseDomain';
    }
    return _defaultWidgetBaseUrl;
  }

  /// Generate widget URL with query params (for iframe embeds)
  /// Uses immutable IDs - always works, even if slug changes
  /// Note: Language not included - widget has its own language selector
  String get _widgetUrl {
    final baseUrl = _widgetBaseUrl;
    final queryParams = <String, String>{
      'property': widget.propertyId,
      'unit': widget.unitId,
    };
    return Uri.parse(baseUrl).replace(queryParameters: queryParams).toString();
  }

  /// Check if slug URL is available (requires subdomain + slug)
  bool get _hasSlugUrl =>
      widget.propertySubdomain != null &&
      widget.propertySubdomain!.isNotEmpty &&
      widget.unitSlug != null &&
      widget.unitSlug!.isNotEmpty;

  /// Generate clean slug URL (for standalone/shareable pages)
  /// Format: https://subdomain.bookbed.io/slug
  /// Note: Language not included - widget has its own language selector
  String get _slugUrl {
    if (!_hasSlugUrl) return '';
    return 'https://${widget.propertySubdomain}.$_subdomainBaseDomain/${widget.unitSlug}';
  }

  String get _embedCode {
    final url = _widgetUrl;

    return '''
<iframe
  src="$url"
  width="100%"
  height="${_widgetHeight}px"
  frameborder="0"
  allow="payment"
  style="border: none; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
></iframe>''';
  }

  String get _responsiveEmbedCode {
    final url = _widgetUrl;

    return '''
<div style="position: relative; width: 100%; padding-bottom: 75%; overflow: hidden;">
  <iframe
    src="$url"
    style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; border-radius: 8px;"
    frameborder="0"
    allow="payment"
  ></iframe>
</div>''';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final l10n = AppLocalizations.of(context);
    ErrorDisplayUtils.showSuccessSnackBar(context, l10n.embedCodeCopied(label));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Row(
                    children: [
                      const Icon(Icons.code, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.embedCodeTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Content
            Flexible(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Unit name (if available)
                      if (widget.unitName != null) ...[
                        _buildInfoCard(icon: Icons.apartment, title: l10n.embedCodeUnit, content: widget.unitName!),
                        const SizedBox(height: 16),
                      ],

                      // Unit ID Display (technical reference)
                      _buildInfoCard(
                        icon: Icons.fingerprint,
                        title: l10n.embedCodeUnitIdTechnical,
                        content: widget.unitId,
                        onCopy: () => _copyToClipboard(widget.unitId, 'Unit ID'),
                      ),

                      const SizedBox(height: 16),

                      // Widget URL (query params - for iframes)
                      _buildInfoCard(
                        icon: Icons.link,
                        title: l10n.embedCodeWidgetUrl,
                        content: _widgetUrl,
                        onCopy: () => _copyToClipboard(_widgetUrl, 'URL'),
                      ),

                      // Slug URL (clean URL - for standalone/shareable)
                      if (_hasSlugUrl) ...[
                        const SizedBox(height: 16),
                        _buildShareableUrlCard(
                          content: _slugUrl,
                          onCopy: () => _copyToClipboard(_slugUrl, 'Shareable URL'),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Configuration Options
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.embedCodeOptions,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              // Info: Language is handled by widget itself
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withAlpha(50)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Language selection is built into the widget header',
                                        style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Height
                              Builder(
                                builder: (ctx) => TextFormField(
                                  initialValue: _widgetHeight,
                                  decoration: InputDecorationHelper.buildDecoration(
                                    labelText: l10n.embedCodeHeight,
                                    context: ctx,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() => _widgetHeight = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fixed Height Embed Code
                      _buildCodeCard(
                        title: l10n.embedCodeFixedHeight,
                        description: l10n.embedCodeFixedHeightDesc(_widgetHeight),
                        code: _embedCode,
                        onCopy: () => _copyToClipboard(_embedCode, 'Embed kod'),
                      ),

                      const SizedBox(height: 16),

                      // Responsive Embed Code
                      _buildCodeCard(
                        title: l10n.embedCodeResponsive,
                        description: l10n.embedCodeResponsiveDesc,
                        code: _responsiveEmbedCode,
                        onCopy: () => _copyToClipboard(_responsiveEmbedCode, 'Responsive embed kod'),
                      ),

                      const SizedBox(height: 24),

                      // Instructions
                      Card(
                        color: AppColors.authSecondary.withAlpha((0.1 * 255).toInt()),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppColors.authSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.embedCodeInstructions,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.authSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(l10n.embedCodeInstructionsText, style: const TextStyle(fontSize: 14, height: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onCopy,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(content, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                ),
                if (onCopy != null)
                  IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: onCopy, tooltip: 'Kopiraj'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build highlighted card for shareable slug URL
  Widget _buildShareableUrlCard({required String content, VoidCallback? onCopy}) {
    return Card(
      color: AppColors.authSecondary.withAlpha((0.08 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, size: 20, color: AppColors.authSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Shareable URL (Clean Link)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.authSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.authSecondary.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.authSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Perfect for sharing on social media, email, or as a direct link',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(content, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                ),
                if (onCopy != null)
                  IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: onCopy, tooltip: 'Copy'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeCard({
    required String title,
    required String description,
    required String code,
    required VoidCallback onCopy,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Kopiraj'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
