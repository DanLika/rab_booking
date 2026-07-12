part of 'owner_bookings_screen.dart';

/// Page sections of the owner Bookings screen: mobile panel, lean ledger,
/// synchronization + FAQ sections, and the overbooking banner widget.
///
/// Extracted from `_OwnerBookingsScreenState` on 2026-07-11 — file split
/// only, ZERO behavior change.
mixin _BookingsSectionsMixin
    on _OwnerBookingsScreenStateBase, _BookingDialogsMixin {
  Widget _buildMobilePanel(
    BuildContext context,
    BookingsFilters filters,
    WindowedBookingsState windowedState,
    List<OwnerBooking> bookings,
    int conflictCount,
    AppLocalizations l10n,
  ) {
    final rd = BbRedesignTokens.of(context);
    final bool hasActiveFilter =
        filters.hasActiveFilters || filters.showImportedOnly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kMobileGutter,
        BBSpace.sm,
        _kMobileGutter,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: rd.panelBg,
          borderRadius: BorderRadius.circular(BBRadius.lg),
          border: Border.all(color: rd.panelBorder),
          boxShadow: rd.panelShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kMobilePanelPadH,
            _kMobilePanelPadTop,
            _kMobilePanelPadH,
            _kMobilePanelPadBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header + KPI strip + AI nudge + pending queue (real providers).
              BookingsPremiumHeader(
                hasActiveFilter: hasActiveFilter,
                padding: EdgeInsets.zero,
              ),
              // Ledger section header (eyebrow + count).
              BookingsPremiumLedgerHeader(
                hasActiveFilter: hasActiveFilter,
                padding: const EdgeInsets.only(bottom: _kMobilePanelGap),
              ),
              if (conflictCount > 0) ...<Widget>[
                _OverbookingBanner(
                  label: _formatConflictLabel(conflictCount),
                  onTap: () => _handleOverbookingBadgeTap(ref),
                ),
                const SizedBox(height: _kMobilePanelGap),
              ],
              // Lean ledger (tabs + rows + count; real data / empty state).
              _buildLeanLedger(context, filters, windowedState, bookings, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the lean premium ledger card for the active tab/state. Normalizes
  /// the current data source into [BookingsLedgerEntry]s; loading / empty /
  /// error render as the card body so the tabs header stays visible.
  Widget _buildLeanLedger(
    BuildContext context,
    BookingsFilters filters,
    WindowedBookingsState windowedState,
    List<OwnerBooking> bookings,
    AppLocalizations l10n,
  ) {
    List<BookingsLedgerEntry> entries = const <BookingsLedgerEntry>[];
    Widget? bodyOverride;
    String? footerLabel;

    if (filters.showImportedOnly) {
      // Uvezene — iCal events (read-only, no owner detail route).
      final AsyncValue<List<IcalEvent>> eventsAsync = ref.watch(
        allOwnerIcalEventsProvider,
      );
      bodyOverride = eventsAsync.when(
        loading: _ledgerLoadingBody,
        error: (Object e, _) => _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: e.toString(),
        ),
        data: (List<IcalEvent> events) => events.isEmpty
            ? _ledgerMessageBody(
                icon: 'event_busy',
                title: l10n.icalNoEventsTitle,
                body: l10n.icalNoEventsSubtitle,
              )
            : null,
      );
      if (bodyOverride == null) {
        final List<IcalEvent> events = eventsAsync.value ?? const <IcalEvent>[];
        entries = events
            .map(BookingsLedgerEntry.fromImportedEvent)
            .toList(growable: false);
        footerLabel = _ledgerFooterLabel(entries.length, false);
      }
    } else if (filters.status == null) {
      // Sve — unified (regular + imported), pre-merged + sorted.
      final bool isLoading = ref.watch(isUnifiedBookingsLoadingProvider);
      final String? error = ref.watch(unifiedBookingsErrorProvider);
      final List<UnifiedBookingItem> items =
          ref.watch(unifiedBookingsProvider).valueOrNull ??
          const <UnifiedBookingItem>[];
      if (isLoading) {
        bodyOverride = _ledgerLoadingBody();
      } else if (error != null) {
        bodyOverride = _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: error,
        );
      } else if (items.isEmpty) {
        bodyOverride = const Padding(
          padding: EdgeInsets.all(BBSpace.md),
          child: RevenueGuideEmptyState(),
        );
      } else {
        entries = items.map(_ledgerEntryFromUnified).toList(growable: false);
        footerLabel = _ledgerFooterLabel(entries.length, false);
      }
    } else {
      // Specific status tab — windowed bookings.
      if (windowedState.isInitialLoad && bookings.isEmpty) {
        bodyOverride = _ledgerLoadingBody();
      } else if (windowedState.error != null && bookings.isEmpty) {
        bodyOverride = _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: windowedState.error,
        );
      } else if (windowedState.isEmpty) {
        bodyOverride = const Padding(
          padding: EdgeInsets.all(BBSpace.md),
          child: RevenueGuideEmptyState(),
        );
      } else {
        entries = bookings
            .map(BookingsLedgerEntry.fromOwnerBooking)
            .toList(growable: false);
        footerLabel = _ledgerFooterLabel(
          entries.length,
          windowedState.hasMoreBottom,
        );
      }
    }

    return BookingsLedger(
      tabBar: const BookingsTabBar(),
      entries: entries,
      bodyOverride: bodyOverride,
      footerLabel: footerLabel,
      onFilters: () => showDialog<void>(
        context: context,
        builder: (BuildContext context) => const BookingsFiltersDialog(),
      ),
      onOpenDetail: (String bookingId) => context.push(
        OwnerRoutes.bookingDetail.replaceFirst(':bookingId', bookingId),
      ),
    );
  }

  BookingsLedgerEntry _ledgerEntryFromUnified(UnifiedBookingItem item) {
    return switch (item) {
      RegularBookingItem(:final OwnerBooking ownerBooking) =>
        BookingsLedgerEntry.fromOwnerBooking(ownerBooking),
      ImportedBookingItem(:final IcalEvent event) =>
        BookingsLedgerEntry.fromImportedEvent(event),
    };
  }

  Widget _ledgerLoadingBody() => Padding(
    padding: const EdgeInsets.all(BBSpace.md),
    child: SkeletonLoader.bookingsTable(),
  );

  Widget _ledgerMessageBody({
    required String icon,
    required String title,
    String? body,
  }) => Padding(
    padding: const EdgeInsets.all(BBSpace.md),
    child: BbEmptyState(icon: icon, title: title, body: body, compact: true),
  );

  String _ledgerFooterLabel(int visible, bool hasMore) => hasMore
      ? 'Prikazano $visible · listanjem se učitavaju nove'
      : 'Prikazano svih $visible rezervacija';

  Widget _buildSynchronizationSection(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return BbCard(
      padded: false,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showSync = !_showSync),
            borderRadius: BBRadius.mdAll,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: _kIconTextGap),
                  Expanded(
                    child: Text(
                      l10n.icalSyncTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showSync ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showSync) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.icalWhySync,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: _kIconTextGap),
                  Text(
                    l10n.icalSyncNoFeedsDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: _kSectionPadLg),
                  FilledButton.icon(
                    onPressed: () => context.push(OwnerRoutes.icalImport),
                    icon: const Icon(Icons.sync, size: 20),
                    label: Text(l10n.icalSyncTitle),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaqSection(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    final faqs = [
      (l10n.ownerFaqBookings1Q, l10n.ownerFaqBookings1A),
      (l10n.ownerFaqBookings2Q, l10n.ownerFaqBookings2A),
      (l10n.ownerFaqBookings3Q, l10n.ownerFaqBookings3A),
      (l10n.ownerFaqBookings4Q, l10n.ownerFaqBookings4A),
      (l10n.ownerFaqBookings5Q, l10n.ownerFaqBookings5A),
    ];

    return BbCard(
      padded: false,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BBRadius.mdAll,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: _kIconTextGap),
                  Expanded(
                    child: Text(
                      l10n.ownerFaqCategoryBookings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showFaq ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Column(
                children: faqs
                    .map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❓ ${faq.$1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: _kFaqAnswerGap),
                            Text(
                              faq.$2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slim, tappable overbooking-conflict banner shown above the ledger.
/// Token-styled (error tint); preserves the old filters-card affordance.
class _OverbookingBanner extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OverbookingBanner({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(BBRadius.sm)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.sm,
            vertical: BBSpace.xs,
          ),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(BBRadius.sm)),
            border: Border.all(color: c.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: c.error, size: 18),
              const SizedBox(width: BBSpace.xs),
              Flexible(
                child: Text(
                  label,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
