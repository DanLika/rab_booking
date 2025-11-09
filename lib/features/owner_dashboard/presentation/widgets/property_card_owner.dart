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
                ? theme.colorScheme.primary.withAlpha((0.5 * 255).toInt())
                : theme.dividerColor,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? theme.colorScheme.primary.withAlpha((0.2 * 255).toInt())
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  final isSmallMobile = constraints.maxWidth < 350;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      _buildImage(isSmallMobile, isMobile),

                      // Content
                      Padding(
                        padding: EdgeInsets.all(
                          isSmallMobile ? 14 : (isMobile ? 16 : 20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildContent(
                            context,
                            theme,
                            isMobile,
                            isSmallMobile,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return [
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
                    fontSize: isSmallMobile ? 18 : (isMobile ? 20 : null),
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallMobile ? 4 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 8 : 10,
                    vertical: isSmallMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withAlpha(
                          (0.15 * 255).toInt(),
                        ),
                        theme.colorScheme.secondary.withAlpha(
                          (0.15 * 255).toInt(),
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.property.propertyType.displayNameHR,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 13),
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
      SizedBox(height: isSmallMobile ? 10 : (isMobile ? 12 : 14)),

      // Location
      Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: isSmallMobile ? 16 : 18,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: isSmallMobile ? 4 : 6),
          Expanded(
            child: Text(
              widget.property.location,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallMobile ? 13 : (isMobile ? 14 : null),
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      SizedBox(height: isSmallMobile ? 10 : (isMobile ? 12 : 16)),
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
      SizedBox(height: isSmallMobile ? 10 : (isMobile ? 12 : 16)),

      // Stats row
      Row(
        children: [
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.apartment,
              label:
                  '${widget.property.unitsCount} ${widget.property.unitsCount == 1 ? 'jedinica' : 'jedinice'}',
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
          SizedBox(width: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.star,
              label: widget.property.formattedRating,
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
          SizedBox(width: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.reviews,
              label: '${widget.property.reviewCount}',
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            ),
          ),
        ],
      ),

      SizedBox(height: isSmallMobile ? 10 : (isMobile ? 12 : 16)),

      // Actions row
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.property.isActive ? 'Objavljeno' : 'Skriveno',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.property.isActive
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error.withAlpha(
                                  (0.8 * 255).toInt(),
                                ),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.property.isActive
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error.withAlpha(
                                  (0.8 * 255).toInt(),
                                ),
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
    ];
  }

  Widget _buildImage(bool isSmallMobile, bool isMobile) {
    // Use smaller aspect ratio on very small screens to save vertical space
    final aspectRatio = isSmallMobile ? 1.8 : (isMobile ? 16 / 9.5 : 16 / 9);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: widget.property.primaryImage != null
          ? Image.network(
              widget.property.primaryImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(isSmallMobile);
              },
            )
          : _buildPlaceholder(isSmallMobile),
    );
  }

  Widget _buildPlaceholder(bool isSmallMobile) {
    return Builder(
      builder: (context) => Container(
        color: context.surfaceVariantColor,
        child: Center(
          child: Icon(
            Icons.villa,
            size: isSmallMobile ? 48 : 64,
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
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 6 : (isMobile ? 8 : 12),
        vertical: isSmallMobile ? 4 : (isMobile ? 6 : 8),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(
          (0.5 * 255).toInt(),
        ),
        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallMobile ? 14 : (isMobile ? 16 : 18),
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: isSmallMobile ? 3 : (isMobile ? 4 : 6)),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isSmallMobile ? 10 : (isMobile ? 11 : null),
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.8 * 255).toInt(),
                ),
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
