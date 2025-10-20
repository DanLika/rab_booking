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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                _buildImage(),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.property.propertyType.displayNameHR,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: context.iconColorSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: context.textColorSecondary,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.iconColorSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textColorSecondary,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
