import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/slug_utils.dart';

/// Dialog that generates and displays embed code for widget
class EmbedCodeGeneratorDialog extends StatefulWidget {
  const EmbedCodeGeneratorDialog({
    required this.unitId,
    this.unitSlug,
    this.unitName,
    super.key,
  });

  final String unitId;
  final String? unitSlug;
  final String? unitName;

  @override
  State<EmbedCodeGeneratorDialog> createState() => _EmbedCodeGeneratorDialogState();
}

class _EmbedCodeGeneratorDialogState extends State<EmbedCodeGeneratorDialog> {
  String _selectedLanguage = 'hr';
  String _widgetHeight = '900';

  static const String _widgetBaseUrl = 'https://rab-booking-widget.web.app';

  /// Generate hybrid slug URL or fallback to legacy query param
  String get _widgetUrl {
    // Try to use hybrid slug URL (preferred)
    if (widget.unitSlug != null && widget.unitSlug!.isNotEmpty) {
      final hybridSlug = generateHybridSlug(widget.unitSlug!, widget.unitId);
      return '$_widgetBaseUrl/booking/$hybridSlug?language=$_selectedLanguage';
    }

    // Fallback to legacy query param URL
    final queryParams = <String, String>{
      'unit': widget.unitId,
      'language': _selectedLanguage,
    };

    return Uri.parse(_widgetBaseUrl).replace(
      queryParameters: queryParams,
    ).toString();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiran u clipboard!'),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Embed Kod za Widget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Unit name (if available)
                  if (widget.unitName != null) ...[
                    _buildInfoCard(
                      icon: Icons.apartment,
                      title: 'Jedinica',
                      content: widget.unitName!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Hybrid Slug (if available)
                  if (widget.unitSlug != null && widget.unitSlug!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.label,
                      title: 'URL Slug',
                      content: generateHybridSlug(widget.unitSlug!, widget.unitId),
                      onCopy: () => _copyToClipboard(
                        generateHybridSlug(widget.unitSlug!, widget.unitId),
                        'Slug',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Unit ID Display (technical reference)
                  _buildInfoCard(
                    icon: Icons.fingerprint,
                    title: 'Unit ID (technical)',
                    content: widget.unitId,
                    onCopy: () => _copyToClipboard(widget.unitId, 'Unit ID'),
                  ),

                  const SizedBox(height: 16),

                  // Widget URL
                  _buildInfoCard(
                    icon: Icons.link,
                    title: 'Widget URL',
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
                          const Text(
                            'Opcije',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Language
                          DropdownButtonFormField<String>(
                            initialValue: _selectedLanguage,
                            decoration: const InputDecoration(
                              labelText: 'Jezik',
                              border: OutlineInputBorder(),
                              isDense: true,
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

                          const SizedBox(height: 12),

                          // Height
                          TextFormField(
                            initialValue: _widgetHeight,
                            decoration: const InputDecoration(
                              labelText: 'Visina (px)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() => _widgetHeight = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fixed Height Embed Code
                  _buildCodeCard(
                    title: 'Fiksna Visina',
                    description: 'Iframe sa fiksnom visinom (${_widgetHeight}px)',
                    code: _embedCode,
                    onCopy: () => _copyToClipboard(_embedCode, 'Embed kod'),
                  ),

                  const SizedBox(height: 16),

                  // Responsive Embed Code
                  _buildCodeCard(
                    title: 'Responsive',
                    description: 'Automatski prilagođava se širini (aspect ratio 4:3)',
                    code: _responsiveEmbedCode,
                    onCopy: () => _copyToClipboard(_responsiveEmbedCode, 'Responsive embed kod'),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Uputstvo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Kopirajte embed kod (kliknite na "Kopiraj" dugme)\n'
                            '2. Otvorite stranicu vašeg web sajta u editoru\n'
                            '3. Zalijepite kod na željeno mjesto\n'
                            '4. Sačuvajte i objavite stranicu',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: onCopy,
                    tooltip: 'Kopiraj',
                  ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Kopiraj'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
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
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
