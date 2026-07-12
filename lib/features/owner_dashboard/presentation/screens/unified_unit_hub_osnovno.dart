part of 'unified_unit_hub_screen.dart';

/// Osnovno (Basic-Info) tab of the Unit Hub: tab body, services card and
/// the units.jsx handoff primitives (header, gallery, price card, tappable
/// Cjenovnik hint — the hint only calls `_tabController.animateTo(1)` and
/// never touches the FROZEN Cjenovnik grid content).
///
/// Extracted verbatim from `_UnifiedUnitHubScreenState` on 2026-07-11 —
/// file split only, ZERO behavior change.
mixin _OsnovnoTabMixin on _UnifiedUnitHubScreenStateBase {
  Widget _buildBasicInfoTab(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _kDesktopBreakpoint;
    final isTablet =
        screenWidth >= _kTabletBreakpoint && screenWidth < _kDesktopBreakpoint;
    final isMobile = screenWidth < _kMobileBreakpoint;

    final l10n = AppLocalizations.of(context);
    final unit = _selectedUnit!;
    final BBColorSet c = BBColor.of(context);

    // Informacije card — handoff units.jsx: Naziv / URL slug / Opis / Status badge
    final informacijeCard = BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(c, icon: 'info', title: l10n.unitHubInfoSection),
          _kvRow(c, l10n.unitHubName, value: unit.name),
          _kvRow(
            c,
            l10n.unitHubSlug,
            value: unit.slug,
            placeholder: l10n.notSet,
          ),
          if (unit.description != null && unit.description!.isNotEmpty)
            _kvRow(
              c,
              l10n.unitHubDescription,
              value: unit.description,
              stack: true,
            ),
          _kvRow(
            c,
            l10n.unitHubStatus,
            isLast: true,
            child: BbStatusBadge(
              status: unit.isAvailable
                  ? BbBookingStatus.confirmed
                  : BbBookingStatus.cancelled,
              label: unit.isAvailable
                  ? l10n.unitHubStatusAvailable
                  : l10n.unitHubStatusUnavailable,
              size: BbStatusBadgeSize.sm,
            ),
          ),
        ],
      ),
    );

    // Kapacitet card
    final kapacitetCard = BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(
            c,
            icon: 'hotel',
            title: l10n.unitHubCapacitySection,
          ),
          _kvRow(c, l10n.unitHubBedrooms, value: '${unit.bedrooms}'),
          _kvRow(c, l10n.unitHubBathrooms, value: '${unit.bathrooms}'),
          _kvRow(
            c,
            l10n.unitHubMaxGuests,
            value: '${unit.maxGuests}',
            isLast: unit.areaSqm == null,
          ),
          if (unit.areaSqm != null)
            _kvRow(
              c,
              l10n.unitHubArea,
              value: '${unit.areaSqm!.toStringAsFixed(0)} m²',
              isLast: true,
            ),
        ],
      ),
    );

    return ListView(
      // Web performance: Use ClampingScrollPhysics to prevent elastic overscroll jank
      physics: PlatformScrollPhysics.adaptive,
      padding: EdgeInsets.all(context.horizontalPadding),
      children: [
        // Gallery (desktop only, when the unit carries photos) — handoff cover + 2×2
        if (isDesktop && unit.images.isNotEmpty) ...[
          _buildUnitGallery(c, unit.images),
          const SizedBox(height: _kOsnovnoSectionGap),
        ],

        // Header: title + subtitle, Kopiraj (duplicate) + Uredi (edit)
        _buildOsnovnoHeader(theme, c, l10n, unit, isMobile),
        const SizedBox(height: _kOsnovnoSectionGap),

        // 2-col cards: Informacije + Kapacitet (stack on mobile)
        if (isDesktop || isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: informacijeCard),
              const SizedBox(width: 16),
              Expanded(child: kapacitetCard),
            ],
          )
        else ...[
          informacijeCard,
          const SizedBox(height: BBSpace.sm),
          kapacitetCard,
        ],
        const SizedBox(height: _kOsnovnoSectionGap),

        // Cijena card: PriceTile grid + extra fees + Cjenovnik cross-reference banner
        _buildCijenaCard(c, l10n, unit),
        const SizedBox(height: _kOsnovnoSectionGap),

        // Additional services (loaded from Firestore)
        _buildServicesCard(),
      ],
    );
  }

  Widget _buildServicesCard() {
    if (_selectedProperty == null || _selectedUnit == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final BBColorSet c = BBColor.of(context);
    final repo = ref.read(additionalServicesRepositoryProvider);

    return FutureBuilder<List<AdditionalServiceModel>>(
      // Key ensures rebuild when unit changes
      key: ValueKey('services_${_selectedUnit!.id}'),
      future: repo.fetchByUnit(
        propertyId: _selectedProperty!.id,
        unitId: _selectedUnit!.id,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final services = snapshot.data!;
        return BbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _osnovnoCardHeader(
                c,
                icon: 'room_service',
                title: l10n.additionalServicesTitle,
              ),
              for (int i = 0; i < services.length; i++)
                _kvRow(
                  c,
                  services[i].name,
                  value: services[i].formattedPrice,
                  isLast: i == services.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Osnovno-tab handoff primitives (units.jsx) ──────────────────────────
  // Header: unit name + subtitle, Kopiraj (duplicate) + Uredi (edit).
  Widget _buildOsnovnoHeader(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
    UnitModel unit,
    bool isMobile,
  ) {
    final BbButtonSize size = isMobile ? BbButtonSize.sm : BbButtonSize.md;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.unitHubBasicDataSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BbButton(
          label: l10n.unitHubCopy,
          iconLeft: 'content_copy',
          variant: BbButtonVariant.secondary,
          size: size,
          onPressed: () {
            context.push(
              '${OwnerRoutes.unitWizard}?propertyId=${unit.propertyId}&duplicateFromId=${unit.id}',
            );
          },
        ),
        const SizedBox(width: 8),
        BbButton(
          label: l10n.unitHubEdit,
          iconLeft: 'edit',
          size: size,
          onPressed: () {
            context.push(OwnerRoutes.unitWizardEdit.replaceAll(':id', unit.id));
          },
        ),
      ],
    );
  }

  // Gallery (desktop): cover (2fr) + 2×2 tile grid (1fr). Read-only display of
  // unit.images; empty slots render a neutral placeholder.
  Widget _buildUnitGallery(BBColorSet c, List<String> images) {
    String? at(int i) => i < images.length ? images[i] : null;
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _galleryTile(c, at(0), 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _galleryTile(c, at(1), 14)),
                      const SizedBox(width: 8),
                      Expanded(child: _galleryTile(c, at(2), 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _galleryTile(c, at(3), 14)),
                      const SizedBox(width: 8),
                      Expanded(child: _galleryTile(c, at(4), 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryTile(BBColorSet c, String? url, double radius) {
    final Widget placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: BbIcon(name: 'image', size: 22, color: c.textTertiary),
      ),
    );
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }

  // Card header: 32px primary-tint icon badge + title (handoff CardHeader).
  Widget _osnovnoCardHeader(
    BBColorSet c, {
    required String icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: BbIcon(name: icon, size: 18, color: c.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Key/value row (handoff KeyValueRow). `stack` = full-width label-over-value
  // (used for prose like the description); otherwise label left / value right.
  Widget _kvRow(
    BBColorSet c,
    String label, {
    String? value,
    String? placeholder,
    Widget? child,
    bool isLast = false,
    bool stack = false,
  }) {
    final Widget labelWidget = Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: c.textTertiary,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );

    final Widget valueWidget =
        child ??
        ((value != null && value.isNotEmpty)
            ? Text(
                value,
                textAlign: stack ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: c.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: stack ? 6 : 3,
              )
            : Text(
                placeholder ?? '',
                textAlign: stack ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: c.textTertiary,
                ),
              ));

    final Widget content = stack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              SizedBox(width: double.infinity, child: valueWidget),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 4, child: labelWidget),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
      child: content,
    );
  }

  // Cijena card: emphasized PriceTile grid + extra-fee rows + Cjenovnik banner.
  Widget _buildCijenaCard(BBColorSet c, AppLocalizations l10n, UnitModel unit) {
    final List<Widget> tiles = <Widget>[
      _priceTile(
        c,
        l10n.unitHubPricePerNight,
        '€${unit.pricePerNight.toStringAsFixed(0)}',
        emphasis: true,
      ),
      if (unit.weekendBasePrice != null)
        _priceTile(
          c,
          l10n.unitWizardStep3WeekendPrice,
          '€${unit.weekendBasePrice!.toStringAsFixed(0)}',
        ),
      _priceTile(c, l10n.unitHubMinNights, '${unit.minStayNights}'),
      if (unit.maxStayNights != null)
        _priceTile(c, l10n.unitWizardStep3MaxStay, '${unit.maxStayNights}'),
    ];

    // Extra fees the model carries but the handoff tiles omit — kept as rows.
    final List<(String, String)> extras = <(String, String)>[
      if (unit.maxTotalCapacity != null &&
          unit.maxTotalCapacity! > unit.maxGuests)
        (
          l10n.unitWizardStep5ExtraBeds,
          '${unit.maxTotalCapacity! - unit.maxGuests}',
        ),
      if (unit.extraBedFee != null)
        (
          l10n.unitWizardStep5ExtraBedFee,
          '€${unit.extraBedFee!.toStringAsFixed(0)}',
        ),
      if (unit.petFee != null)
        (l10n.unitWizardStep5PetFee, '€${unit.petFee!.toStringAsFixed(0)}'),
    ];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(c, icon: 'euro', title: l10n.unitHubPriceSection),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (ctx, cons) {
              final double w = cons.maxWidth;
              final int cols = w >= 520 ? 4 : (w >= 340 ? 3 : 2);
              final int useCols = tiles.length < cols ? tiles.length : cols;
              const double gap = 12;
              final double tileW = (w - (useCols - 1) * gap) / useCols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tiles
                    .map((t) => SizedBox(width: tileW, child: t))
                    .toList(),
              );
            },
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: _kPriceExtrasGap),
            for (int i = 0; i < extras.length; i++)
              _kvRow(
                c,
                extras[i].$1,
                value: extras[i].$2,
                isLast: i == extras.length - 1,
              ),
          ],
          const SizedBox(height: BBSpace.sm),
          _buildCjenovnikHint(c, l10n),
        ],
      ),
    );
  }

  Widget _priceTile(
    BBColorSet c,
    String label,
    String value, {
    bool emphasis = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: emphasis ? c.primary.withValues(alpha: 0.10) : c.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: emphasis
            ? Border.all(color: c.primary.withValues(alpha: 0.25))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: c.textTertiary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: emphasis ? c.primary : c.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Cross-reference banner — tappable, jumps to the Cjenovnik tab (index 1).
  // Local tab switch only; never reads/writes the FROZEN Cjenovnik content.
  Widget _buildCjenovnikHint(BBColorSet c, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tabController.animateTo(1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              BbIcon(name: 'info', size: 16, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.unitHubAdvancedPricingHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BbIcon(name: 'chevron_right', size: 18, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}
