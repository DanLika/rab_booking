import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.shadow.withValues(alpha: 0.06),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;
                final isSmallMobile = constraints.maxWidth < 350;

                return ClipRect(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tappable area (Image + Main Info)
                      InkWell(
                        onTap: widget.onTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            _buildImage(isSmallMobile, isMobile),

                            // Main Content (without action buttons)
                            Padding(
                              padding: EdgeInsets.all(
                                isSmallMobile ? 10 : (isMobile ? 12 : 14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildMainContent(
                                  context,
                                  theme,
                                  isMobile,
                                  isSmallMobile,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons (separate, not tappable for main action)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmallMobile ? 10 : (isMobile ? 12 : 16),
                          0,
                          isSmallMobile ? 10 : (isMobile ? 12 : 16),
                          isSmallMobile ? 10 : (isMobile ? 12 : 16),
                        ),
                        child: _buildActions(
                          context,
                          theme,
                          isMobile,
                          isSmallMobile,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainContent(
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
                SizedBox(height: isSmallMobile ? 3 : 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 6 : 8,
                    vertical: isSmallMobile ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.secondary.withValues(alpha: 0.15),
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
      SizedBox(height: isSmallMobile ? 8 : (isMobile ? 10 : 12)),

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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      SizedBox(height: isSmallMobile ? 8 : (isMobile ? 10 : 12)),
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
      SizedBox(height: isSmallMobile ? 8 : (isMobile ? 10 : 12)),

      // Stats row
      Row(
        children: [
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.apartment,
              label: AppLocalizations.of(
                context,
              ).propertyCardUnits(widget.property.unitsCount),
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
    ];
  }

  Widget _buildActions(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return Column(
      children: [
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
        SizedBox(height: isSmallMobile ? 8 : (isMobile ? 10 : 12)),

        // Actions row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Published toggle with styled switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.property.isActive
                            ? [
                                theme.colorScheme.tertiary.withValues(alpha: 0.1),
                                theme.colorScheme.tertiary.withValues(alpha: 0.05),
                              ]
                            : [
                                theme.colorScheme.error.withValues(alpha: 0.1),
                                theme.colorScheme.error.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.property.isActive
                            ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                            : theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.property.isActive
                                ? AppLocalizations.of(
                                    context,
                                  ).propertyCardPublished
                                : AppLocalizations.of(
                                    context,
                                  ).propertyCardHidden,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.property.isActive
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Switch(
                          value: widget.property.isActive,
                          onChanged: widget.onTogglePublished,
                          activeThumbColor: theme.colorScheme.primary,
                          activeTrackColor: theme.colorScheme.primary
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Edit button
                      _StyledIconButton(
                        onPressed: widget.onEdit,
                        icon: Icons.edit_outlined,
                        tooltip: AppLocalizations.of(context).propertyCardEdit,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      _StyledIconButton(
                        onPressed: widget.onDelete,
                        icon: Icons.delete_outline,
                        tooltip: AppLocalizations.of(
                          context,
                        ).propertyCardDelete,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
              );
            }
            final l10n = AppLocalizations.of(context);
            return Row(
              children: [
                // Published toggle with styled switch
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.property.isActive
                            ? [
                                theme.colorScheme.tertiary.withValues(alpha: 0.1),
                                theme.colorScheme.tertiary.withValues(alpha: 0.05),
                              ]
                            : [
                                theme.colorScheme.error.withValues(alpha: 0.1),
                                theme.colorScheme.error.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.property.isActive
                            ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                            : theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.property.isActive
                                ? l10n.propertyCardPublished
                                : l10n.propertyCardHidden,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.property.isActive
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: widget.property.isActive,
                          onChanged: widget.onTogglePublished,
                          activeThumbColor: theme.colorScheme.primary,
                          activeTrackColor: theme.colorScheme.primary
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Edit button
                _StyledIconButton(
                  onPressed: widget.onEdit,
                  icon: Icons.edit_outlined,
                  tooltip: l10n.propertyCardEdit,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(width: 8),

                // Delete button
                _StyledIconButton(
                  onPressed: widget.onDelete,
                  icon: Icons.delete_outline,
                  tooltip: l10n.propertyCardDelete,
                  color: theme.colorScheme.error,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildImage(bool isSmallMobile, bool isMobile) {
    // Use higher aspect ratio (wider/shorter) to save vertical space
    final aspectRatio = isSmallMobile ? 2.2 : (isMobile ? 2.0 : 1.95);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: AspectRatio(
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
      ),
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
        horizontal: isSmallMobile ? 4 : (isMobile ? 6 : 8),
        vertical: isSmallMobile ? 3 : (isMobile ? 4 : 6),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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

/// Styled icon button with gradient background
class _StyledIconButton extends StatelessWidget {
  const _StyledIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
