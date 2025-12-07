import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/theme/app_colors.dart';

/// Dialog that generates and displays embed code for widget
class EmbedCodeGeneratorDialog extends StatefulWidget {
  const EmbedCodeGeneratorDialog({
    required this.unitId,
    this.unitName,
    this.propertySubdomain,
    super.key,
  });

  final String unitId;
  final String? unitName;
  final String? propertySubdomain;

  @override
  State<EmbedCodeGeneratorDialog> createState() => _EmbedCodeGeneratorDialogState();
}

class _EmbedCodeGeneratorDialogState extends State<EmbedCodeGeneratorDialog> {
  String _selectedLanguage = 'hr';
  String _widgetHeight = '900';

  static const String _defaultWidgetBaseUrl = 'https://rab-booking-widget.web.app';
  static const String _subdomainBaseDomain = 'bookbed.io';

  /// Get the base URL - use subdomain if available, otherwise default
  String get _widgetBaseUrl {
    if (widget.propertySubdomain != null && widget.propertySubdomain!.isNotEmpty) {
      return 'https://${widget.propertySubdomain}.$_subdomainBaseDomain';
    }
    return _defaultWidgetBaseUrl;
  }

  /// Generate widget URL with query params (stable, uses immutable unit ID)
  String get _widgetUrl {
    final baseUrl = _widgetBaseUrl;
    final queryParams = <String, String>{
      'unit': widget.unitId,
      'language': _selectedLanguage,
    };
    return Uri.parse(baseUrl).replace(queryParameters: queryParams).toString();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.embedCodeCopied(label)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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

                      // Widget URL
                      _buildInfoCard(
                        icon: Icons.link,
                        title: l10n.embedCodeWidgetUrl,
                        content: _widgetUrl,
                        onCopy: () => _copyToClipboard(_widgetUrl, 'URL'),
                      ),

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

                              // Language
                              Builder(
                                builder: (ctx) => DropdownButtonFormField<String>(
                                  initialValue: _selectedLanguage,
                                  decoration: InputDecorationHelper.buildDecoration(
                                    labelText: l10n.embedCodeLanguage,
                                    context: ctx,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'hr', child: Text('Hrvatski')),
                                    DropdownMenuItem(value: 'en', child: Text('English')),
                                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                                    DropdownMenuItem(value: 'it', child: Text('Italiano')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedLanguage = value);
                                    }
                                  },
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
