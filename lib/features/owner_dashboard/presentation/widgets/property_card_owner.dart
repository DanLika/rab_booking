import 'package:flutter/material.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Property card for owner dashboard
class PropertyCardOwner extends StatefulWidget {
  const PropertyCardOwner({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
    super.key,
  });

  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onTogglePublished;

  @override
  State<PropertyCardOwner> createState() => _PropertyCardOwnerState();
}

class _PropertyCardOwnerState extends State<PropertyCardOwner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())
                : theme.dividerColor,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? theme.colorScheme.primary.withAlpha((0.12 * 255).toInt())
                  : theme.colorScheme.shadow.withAlpha((0.06 * 255).toInt()),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 3),
            ),
          ],
        ),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  _buildImage(),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Title and type
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.property.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.property.propertyType.displayNameHR,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              theme.dividerColor,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStat(
                              context,
                              icon: Icons.apartment,
                              label: '${widget.property.unitsCount} ${widget.property.unitsCount == 1 ? 'jedinica' : 'jedinice'}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStat(
                              context,
                              icon: Icons.star,
                              label: widget.property.formattedRating,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStat(
                              context,
                              icon: Icons.reviews,
                              label: '${widget.property.reviewCount}',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Actions row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Use wrap for very narrow screens to prevent overflow
                          if (constraints.maxWidth < 400) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.property.isActive ? 'Objavljeno' : 'Skriveno',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: widget.property.isActive
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFF59E0B),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Switch(
                                      value: widget.property.isActive,
                                      onChanged: widget.onTogglePublished,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: widget.onEdit,
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Uredi',
                                    ),
                                    IconButton(
                                      onPressed: widget.onDelete,
                                      icon: const Icon(Icons.delete_outline),
                                      color: context.errorColor,
                                      tooltip: 'Obriši',
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              // Published toggle
                              Flexible(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.property.isActive ? 'Objavljeno' : 'Skriveno',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: widget.property.isActive
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFF59E0B),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Switch(
                                      value: widget.property.isActive,
                                      onChanged: widget.onTogglePublished,
                                    ),
                                  ],
                                ),
                              ),

                              // Edit button
                              IconButton(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Uredi',
                              ),

                              // Delete button
                              IconButton(
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete_outline),
                                color: context.errorColor,
                                tooltip: 'Obriši',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: widget.property.primaryImage != null
          ? Image.network(
              widget.property.primaryImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Builder(
      builder: (context) => Container(
        color: context.surfaceVariantColor,
        child: Center(
          child: Icon(
            Icons.villa,
            size: 64,
            color: context.iconColorSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
