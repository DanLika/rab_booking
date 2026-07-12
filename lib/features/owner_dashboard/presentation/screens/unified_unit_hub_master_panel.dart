part of 'unified_unit_hub_screen.dart';

/// Master-panel side of the Unit Hub (properties + units tree, selection,
/// reorder, search) plus the top-level PropertyTree widgets it renders.
///
/// Extracted verbatim from `_UnifiedUnitHubScreenState` on 2026-07-11 —
/// file split only, ZERO behavior change.
mixin _MasterPanelMixin on _UnifiedUnitHubScreenStateBase {
  Widget _buildMasterPanel(
    ThemeData theme,
    bool isDark, {
    VoidCallback? onUnitSelected,
    bool isEndDrawer = false,
  }) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final l10n = AppLocalizations.of(context);
    final bb = BBColor.of(context);
    final propertyCount = propertiesAsync.asData?.value.length ?? 0;
    final unitCount = ref.watch(ownerUnitsProvider).asData?.value.length ?? 0;

    return Column(
      children: [
        // Header
        Container(
          padding: isEndDrawer
              ? const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16,
                ) // SafeArea handles top padding for endDrawer
              : const EdgeInsets.fromLTRB(
                  16,
                  36,
                  16,
                  16,
                ), // Increased top padding for desktop sidebar
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Handoff: 32px primary-tint badge around apartment icon.
                  Container(
                    width: _kMasterBadgeSize,
                    height: _kMasterBadgeSize,
                    decoration: BoxDecoration(
                      color: bb.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(_kMasterBadgeRadius),
                    ),
                    child: Icon(Icons.apartment, color: bb.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.unitHubPropertiesAndUnits,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.unitHubPropertiesUnitsSubtitle(
                            propertyCount,
                            unitCount,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bb.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Add Property button
                  IconButton(
                    icon: const Icon(Icons.add_business, size: 22),
                    onPressed: () {
                      context.push(OwnerRoutes.propertyNew);
                    },
                    tooltip: l10n.unitHubAddProperty,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                decoration:
                    InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitHubSearch,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      context: context,
                    ).copyWith(
                      hintText: l10n.unitHubSearch,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      isDense: true,
                    ),
              ),
            ],
          ),
        ),

        // Properties and Units list (hierarchical)
        Expanded(
          child: propertiesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.unitHubLoadingError,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Molimo osvježite aplikaciju ili pokušajte ponovno.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(ownerPropertiesProvider);
                        ref.invalidate(ownerUnitsProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.tryAgain),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (properties) {
              if (properties.isEmpty) {
                return _buildEmptyPropertiesState(theme, isDark);
              }
              return _buildPropertiesWithUnits(
                theme,
                isDark,
                properties,
                onUnitSelected: onUnitSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Empty state when no properties exist
  Widget _buildEmptyPropertiesState(ThemeData theme, bool isDark) {
    return const UnitHubEmptyState();
  }

  /// Properties with their units - hierarchical view
  Widget _buildPropertiesWithUnits(
    ThemeData theme,
    bool isDark,
    List<PropertyModel> properties, {
    VoidCallback? onUnitSelected,
  }) {
    final unitsAsync = ref.watch(ownerUnitsProvider);

    return unitsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
      error: (error, stack) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.unitHubError(error.toString()),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(ownerUnitsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        );
      },
      data: (allUnits) {
        // Group units by property
        final unitsByProperty = <String, List<UnitModel>>{};
        for (final unit in allUnits) {
          unitsByProperty.putIfAbsent(unit.propertyId, () => []);
          unitsByProperty[unit.propertyId]!.add(unit);
        }

        // Filter properties by search query
        final filteredProperties = properties.where((property) {
          if (_searchQuery.isEmpty) return true;

          // Match property name
          if (property.name.toLowerCase().contains(_searchQuery)) return true;

          // Match any unit in this property
          final propertyUnits = unitsByProperty[property.id] ?? [];
          return propertyUnits.any(
            (unit) =>
                unit.name.toLowerCase().contains(_searchQuery) ||
                (unit.description?.toLowerCase().contains(_searchQuery) ??
                    false),
          );
        }).toList();

        if (filteredProperties.isEmpty) {
          final l10n = AppLocalizations.of(context);
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 24.0,
              ),
              child: AnimatedEmptyState(
                icon: Icons.search_off,
                title: l10n.unitHubNoResults,
                iconColor: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            80,
          ), // Increased bottom padding for last unit visibility
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            final propertyUnits = (unitsByProperty[property.id] ?? [])
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ); // Ascending A-Z sort

            // Filter units by search
            final filteredUnits =
                (_searchQuery.isEmpty
                      ? propertyUnits
                      : propertyUnits
                            .where(
                              (unit) =>
                                  unit.name.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  (unit.description?.toLowerCase().contains(
                                        _searchQuery,
                                      ) ??
                                      false),
                            )
                            .toList())
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  ); // Ascending A-Z sort

            return _buildPropertySection(
              theme,
              isDark,
              property: property,
              units: filteredUnits,
              onUnitSelected: onUnitSelected,
            );
          },
        );
      },
    );
  }

  /// Property section with expandable units.
  ///
  /// Handoff units.jsx `PropertyTree`: the property header is a FLAT toggle row
  /// (`[chevron][domain icon][name (flex:1)][count][actions]`), NOT an
  /// `ExpansionTile`. The old ExpansionTile packed the name into a fixed `title`
  /// slot competing with a `trailing` 3-icon action cluster, so a long name had
  /// no room and wrapped (band-aided with ellipsis in iter 6/#850). Restructured
  /// to a real `Row` where the name gets true `Expanded` priority and the action
  /// cluster is fixed-width trailing — the name shrinks/ellipsizes cleanly, no
  /// vertical wrap at any width. Expand/collapse, actions, and selection wiring
  /// are unchanged.
  Widget _buildPropertySection(
    ThemeData theme,
    bool isDark, {
    required PropertyModel property,
    required List<UnitModel> units,
    VoidCallback? onUnitSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // Handoff PropertyTree: property groups are flat rows inside the panel
        // card, not individually-elevated cards. Keep a hairline border for
        // grouping without the heavy shadow.
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        border: Border.all(color: context.gradients.sectionBorder),
      ),
      child: _PropertyTreeSection(
        header: (expanded, onToggle) => PropertyTreeHeader(
          theme: theme,
          propertyName: property.name,
          canDelete: units.isEmpty,
          expanded: expanded,
          onToggle: onToggle,
          editTooltip: l10n.unitHubEditProperty,
          addTooltip: l10n.unitHubAddUnit,
          deleteTooltip: units.isEmpty
              ? l10n.unitHubDeleteProperty
              : l10n.unitHubDeleteAllUnitsFirst,
          // Handoff PropertyTree count = bare tnum number (not "N jedinica"): the
          // verbose label crushed the Expanded name to ~22px on the narrow mobile
          // panel (edit/delete/add cluster already claims 84px). Total is in the
          // panel subtitle; units are listed directly below.
          unitsCountLabel: '${units.length}',
          onEdit: () => context.push(
            OwnerRoutes.propertyEdit.replaceAll(':id', property.id),
          ),
          onDelete: () =>
              _confirmDeleteProperty(context, property, units.length),
          onAdd: () => context.push(
            '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
          ),
        ),
        children: [
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.unitHubNoUnitsInProperty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    BbButton(
                      label: l10n.unitHubAdd,
                      size: BbButtonSize.sm,
                      onPressed: () {
                        context.push(
                          '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            _buildReorderableUnitList(
              theme,
              isDark,
              units: units,
              property: property,
              onUnitSelected: onUnitSelected,
            ),
        ],
      ),
    );
  }

  /// Confirm and delete a property
  Future<void> _confirmDeleteProperty(
    BuildContext dialogContext,
    PropertyModel property,
    int unitCount,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);

    // Check if property has units - cannot delete
    if (unitCount > 0) {
      if (!dialogContext.mounted) return;
      await showDialog<void>(
        context: dialogContext,
        builder: (ctx) => BbDialog(
          title: l10n.unitHubCannotDelete,
          body: l10n.unitHubCannotDeleteDesc(property.name, unitCount),
          primary: BbDialogAction(
            label: l10n.unitHubUnderstand,
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => BbDialog(
        title: l10n.unitHubDeletePropertyTitle,
        body: l10n.unitHubDeletePropertyConfirm(property.name),
        destructive: true,
        secondary: BbDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        primary: BbDialogAction(
          label: l10n.delete,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(ownerPropertiesRepositoryProvider)
            .deleteProperty(property.id);

        // Invalidate providers to refresh UI
        ref.invalidate(ownerPropertiesProvider);
        ref.invalidate(ownerUnitsProvider);

        // Reset selection if deleted property's unit was selected
        if (_selectedProperty?.id == property.id) {
          setState(() {
            _selectedUnit = null;
            _selectedProperty = null;
          });
        }

        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10nCtx.unitHubPropertyDeleted(property.name),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10nCtx.unitHubDeleteError(e.toString()),
          );
        }
      }
    }
  }

  /// Confirm and delete a unit
  Future<void> _confirmDeleteUnit(
    BuildContext dialogContext,
    UnitModel unit,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => BbDialog(
        title: l10n.unitHubDeleteUnitTitle,
        body: l10n.unitHubDeleteUnitConfirm(unit.name),
        destructive: true,
        secondary: BbDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        primary: BbDialogAction(
          label: l10n.delete,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(ownerPropertiesRepositoryProvider)
            .deleteUnit(unit.propertyId, unit.id);

        // Invalidate providers to refresh UI
        ref.invalidate(ownerUnitsProvider);

        // Reset selection if deleted unit was selected
        if (_selectedUnit?.id == unit.id) {
          setState(() {
            _selectedUnit = null;
            _selectedProperty = null;
          });
        }

        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10nCtx.unitHubUnitDeleted(unit.name),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10nCtx.unitHubDeleteError(e.toString()),
          );
        }
      }
    }
  }

  /// Unit list (simple, no drag and drop)
  Widget _buildReorderableUnitList(
    ThemeData theme,
    bool isDark, {
    required List<UnitModel> units,
    required PropertyModel property,
    VoidCallback? onUnitSelected,
  }) {
    // Sort units by sortOrder
    final sortedUnits = List<UnitModel>.from(units)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      children: sortedUnits.map((unit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildUnitListTile(
            theme,
            isDark,
            unit: unit,
            property:
                property, // OPTIMIZED: Pass full property to avoid N+1 query
            isSelected: _selectedUnit?.id == unit.id,
            onUnitSelected: onUnitSelected,
          ),
        );
      }).toList(),
    );
  }

  /// Unit list tile (simple, no drag handle)
  Widget _buildUnitListTile(
    ThemeData theme,
    bool isDark, {
    required UnitModel unit,
    required PropertyModel
    property, // OPTIMIZED: Accept full property instead of just name
    required bool isSelected,
    VoidCallback? onUnitSelected,
  }) {
    final bb = BBColor.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        // Handoff UnitTreeItem: selected = primary-tint bg + 3px left accent;
        // unselected = flat/transparent (no card border/shadow).
        color: isSelected
            ? bb.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        border: Border(
          left: BorderSide(
            color: isSelected ? bb.primary : Colors.transparent,
            width: _kMasterSelectedBar,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // OPTIMIZED: Use passed property directly - eliminates N+1 query pattern
          setState(() {
            _selectedUnit = unit;
            _selectedProperty = property;
          });
          onUnitSelected?.call();
        },
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit name + status + actions
              Row(
                children: [
                  // Handoff: leading bed icon (primary when selected).
                  Icon(
                    Icons.bed_rounded,
                    size: 15,
                    color: isSelected ? bb.primary : bb.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? bb.primary : bb.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Handoff: status as uppercase micro-label (success / tertiary),
                  // no pill chrome.
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        (unit.isAvailable
                                ? l10n.unitHubAvailable
                                : l10n.unitHubUnavailable)
                            .toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: unit.isAvailable
                              ? _availableColor(theme)
                              : bb.textTertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Duplicate button
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return IconButton(
                          onPressed: () {
                            context.push(
                              '${OwnerRoutes.unitWizard}?propertyId=${unit.propertyId}&duplicateFromId=${unit.id}',
                            );
                          },
                          icon: Icon(
                            Icons.copy_outlined,
                            size: 15,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                          ),
                          // This is the DUPLICATE button — it announced itself as "Edit unit"
                          // to screen readers, naming the wrong action.
                          tooltip: l10n.unitHubCopy,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Delete button
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return IconButton(
                          onPressed: () => _confirmDeleteUnit(context, unit),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: theme.colorScheme.error.withAlpha(
                              (0.8 * 255).toInt(),
                            ),
                          ),
                          tooltip: l10n.unitHubDeleteUnit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Handoff meta row indent aligns under the unit name (past the
              // 15px bed icon + 8px gap).
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Property name
                    Text(
                      property.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bb.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Max guests + price
                    Row(
                      children: [
                        Icon(
                          Icons.group_rounded,
                          size: 15,
                          color: bb.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${unit.maxGuests}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bb.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: BBSpace.sm),
                        Icon(
                          Icons.euro_rounded,
                          size: 15,
                          color: bb.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                '${unit.pricePerNight.toStringAsFixed(0)}${l10n.unitHubPerNight}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: bb.textTertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================================
// PROPERTY TREE (handoff units.jsx PropertyTree flat-row layout)
// ============================================================================

/// Collapsible property group. Owns expand/collapse state (default expanded,
/// matching the old `ExpansionTile(initiallyExpanded: true)`) and renders the
/// flat [PropertyTreeHeader] toggle row above its animated children.
class _PropertyTreeSection extends StatefulWidget {
  const _PropertyTreeSection({required this.header, required this.children});

  /// Builds the header given the current expanded state + a toggle callback.
  final Widget Function(bool expanded, VoidCallback onToggle) header;
  final List<Widget> children;

  @override
  State<_PropertyTreeSection> createState() => _PropertyTreeSectionState();
}

class _PropertyTreeSectionState extends State<_PropertyTreeSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header(_expanded, () => setState(() => _expanded = !_expanded)),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Flat property-header row per handoff units.jsx `PropertyTree`.
///
/// `[chevron][domain icon][name (Expanded)][count][edit][delete][add]`. The
/// name gets true `Expanded` priority so it shrinks/ellipsizes cleanly instead
/// of wrapping vertically under the fixed-width trailing action cluster — this
/// is the structural fix for the wrap bug band-aided with ellipsis in
/// iter 6/#850. Tapping anywhere on the name/chevron region toggles expand.
@visibleForTesting
class PropertyTreeHeader extends StatelessWidget {
  const PropertyTreeHeader({
    super.key,
    required this.theme,
    required this.propertyName,
    required this.canDelete,
    required this.expanded,
    required this.onToggle,
    required this.editTooltip,
    required this.deleteTooltip,
    required this.addTooltip,
    required this.unitsCountLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final ThemeData theme;
  final String propertyName;
  final bool canDelete;
  final bool expanded;
  final VoidCallback onToggle;
  final String editTooltip;
  final String deleteTooltip;
  final String addTooltip;
  final String unitsCountLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        // Toggle region: chevron + domain icon + name. Expanded so the name
        // owns all slack width and never competes with the action cluster.
        Expanded(
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(_kMasterRowRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0 : -0.25,
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.domain, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Handoff count badge (bb-tnum). Fixed intrinsic width.
                  Text(
                    unitsCountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Fixed-width action cluster — never steals width from the name.
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  tooltip: editTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: canDelete
                        ? cs.error
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: onDelete,
                  tooltip: deleteTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  onPressed: onAdd,
                  tooltip: addTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
