import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/search_results_provider.dart';
import '../providers/search_state_provider.dart';
import '../providers/search_view_mode_provider.dart';
import '../widgets/filter_panel.dart';
import '../widgets/property_card.dart';
import '../widgets/search_results_header.dart';
import '../widgets/search_no_results.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/save_search_dialog.dart';
import '../../domain/models/search_filters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../data/repositories/search_constants.dart';

/// Premium search results screen
/// Features: Grid/List/Map views, filters, sorting, infinite scroll
class PremiumSearchResultsScreen extends ConsumerStatefulWidget {
  const PremiumSearchResultsScreen({
    this.location,
    this.checkIn,
    this.checkOut,
    this.guests,
    super.key,
  });

  final String? location;
  final String? checkIn;
  final String? checkOut;
  final int? guests;

  @override
  ConsumerState<PremiumSearchResultsScreen> createState() =>
      _PremiumSearchResultsScreenState();
}

class _PremiumSearchResultsScreenState
    extends ConsumerState<PremiumSearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize filters from parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFilters();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    if (widget.location != null) {
      notifier.updateLocation(widget.location!);
    }

    if (widget.guests != null) {
      notifier.updateGuests(widget.guests!);
    }

    if (widget.checkIn != null && widget.checkOut != null) {
      try {
        final checkIn = DateTime.parse(widget.checkIn!);
        final checkOut = DateTime.parse(widget.checkOut!);
        notifier.updateDates(checkIn, checkOut);
      } catch (e) {
        debugPrint('Invalid date format: $e');
      }
    }
  }

  void _onScroll() {
    // Memory leak protection - check if widget is still mounted
    if (!mounted) return;
    if (_isLoadingMore) return;

    // Safety check for scroll position
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * SearchConstants.scrollLoadThreshold; // 0.8 = 80%

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    await ref.read(searchResultsNotifierProvider.notifier).loadNextPage();

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsNotifierProvider);
    final filters = ref.watch(searchFiltersNotifierProvider);
    final viewMode = ref.watch(searchViewModeNotifierProvider);
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchSummary(filters),
        actions: [
          // Filter button (mobile/tablet)
          if (!isDesktop)
            IconButton(
              icon: filters.filterCount > 0
                  ? Badge(
                      label: Text('${filters.filterCount}'),
                      child: const Icon(Icons.filter_list),
                    )
                  : const Icon(Icons.filter_list),
              onPressed: () => PremiumFilterPanel.showBottomSheet(context),
              tooltip: 'Filteri',
            ),

          // Save search button
          () {
            final authState = ref.watch(authStateNotifierProvider);
            final isLoggedIn = authState.isAuthenticated;

            if (isLoggedIn && resultsAsync.properties.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: () => _showSaveSearchDialog(context, filters),
                tooltip: 'Sačuvaj pretragu',
              );
            }
            return const SizedBox.shrink();
          }(),

          // View mode toggle
          IconButton(
            icon: Icon(
              viewMode == SearchViewMode.grid
                  ? Icons.view_list
                  : viewMode == SearchViewMode.list
                      ? Icons.map
                      : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(searchViewModeNotifierProvider.notifier).toggle();
            },
            tooltip: _getViewModeTooltip(viewMode),
          ),

          // Sort dropdown
          _buildSortDropdown(filters),

          const SizedBox(width: AppDimensions.spaceS),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter sidebar (desktop only) - RESPONSIVE WIDTH
          if (isDesktop)
            Container(
              width: _getFilterPanelWidth(context),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                boxShadow: AppShadows.elevation2,
              ),
              child: const PremiumFilterPanel(),
            ),

          // Results area
          Expanded(
            child: () {
              // Handle error state
              if (resultsAsync.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      Text(
                        'Greška pri učitavanju rezultata',
                        style: AppTypography.h3,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        resultsAsync.error.toString(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      PremiumButton.primary(
                        label: 'Pokušaj ponovo',
                        icon: Icons.refresh,
                        onPressed: () {
                          ref.invalidate(searchResultsNotifierProvider);
                        },
                      ),
                    ],
                  ),
                );
              }

              // Handle loading state
              if (resultsAsync.isLoading && resultsAsync.properties.isEmpty) {
                return _buildLoadingState(viewMode, isMobile, isTablet);
              }

              // Handle empty results
              if (resultsAsync.properties.isEmpty) {
                return SearchNoResults(
                  filters: filters,
                  onClearFilters: () {
                    ref.read(searchFiltersNotifierProvider.notifier).clearFilters();
                  },
                );
              }

              // Display results
              return _buildResultsView(
                results: resultsAsync.properties,
                viewMode: viewMode,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              );
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filters.location ?? 'Sva odredišta',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: AppTypography.weightSemibold,
          ),
        ),
        if (filters.checkIn != null && filters.checkOut != null)
          Text(
            '${_formatDate(filters.checkIn!)} - ${_formatDate(filters.checkOut!)}',
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getViewModeTooltip(SearchViewMode mode) {
    switch (mode) {
      case SearchViewMode.grid:
        return 'Prikaz liste';
      case SearchViewMode.list:
        return 'Prikaz mape';
      case SearchViewMode.map:
        return 'Prikaz grida';
    }
  }

  /// Get responsive filter panel width based on screen size
  double _getFilterPanelWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Small desktop/laptop (900-1200px)
    if (screenWidth < 1200) return 280.0;

    // Medium desktop (1200-1600px)
    if (screenWidth < 1600) return 320.0;

    // Large desktop/ultrawide (1600px+)
    return 360.0;
  }

  /// Get grid columns based on screen width - FIX #2: Match Home Page breakpoints
  int _getGridColumns(double screenWidth) {
    // Mobile (< 600px) - Match ResponsivePropertyGrid
    if (screenWidth < AppDimensions.mobile) return 1;

    // Tablet (600-1024px) - Match ResponsivePropertyGrid
    if (screenWidth < AppDimensions.tablet) return 2;

    // Desktop (1024-1440px) - Match ResponsivePropertyGrid
    if (screenWidth < AppDimensions.desktop) return 3;

    // Large Desktop (1440px+) - Match ResponsivePropertyGrid
    return 4;
  }

  /// Get responsive grid padding - FIX #1 & #3: MaxWidth + consistent spacing
  EdgeInsets _getResponsiveGridPadding(BuildContext context, double screenWidth) {
    // Calculate max content width (containerXXL = 1536px)
    const maxContentWidth = AppDimensions.containerXXL;

    // Base horizontal padding (matches Home Page)
    final baseHorizontalPadding = context.horizontalPadding; // 16/24/32px

    // If screen is wider than max content + filter panel, add extra padding to center
    final filterPanelWidth = screenWidth >= AppDimensions.tablet
        ? _getFilterPanelWidth(context)
        : 0.0;

    final availableWidth = screenWidth - filterPanelWidth;
    final extraPadding = availableWidth > maxContentWidth
        ? (availableWidth - maxContentWidth) / 2
        : 0.0;

    final horizontalPadding = baseHorizontalPadding + extraPadding;
    final verticalPadding = context.sectionSpacing; // 24/32/48px

    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  Widget _buildSortDropdown(SearchFilters filters) {
    return Semantics(
      label: 'Sort by: ${filters.sortBy.displayName}',
      hint: 'Double tap to change sort order',
      button: true,
      child: PopupMenuButton<SortBy>(
        icon: Badge(
          label: filters.sortBy != SortBy.recommended
              ? const Icon(Icons.circle, size: 8)
              : const SizedBox.shrink(),
          child: const Icon(Icons.sort),
        ),
        tooltip: 'Sortiraj: ${filters.sortBy.displayName}',
        initialValue: filters.sortBy,
        onSelected: (sortBy) {
          // Debug: Log sort change
          debugPrint('🔄 [Search] Sorting changed: ${sortBy.displayName}');

          // Update sorting
          ref.read(searchFiltersNotifierProvider.notifier).updateSortBy(sortBy);

          // Visual feedback: Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.sort, color: Colors.white, size: 20),
                  const SizedBox(width: AppDimensions.spaceS),
                  Text('Sortiranje: ${sortBy.displayName}'),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(AppDimensions.spaceM),
            ),
          );
        },
        itemBuilder: (context) => SortBy.values.map((sortBy) {
          final isSelected = sortBy == filters.sortBy;
          return PopupMenuItem(
            value: sortBy,
            child: Semantics(
              label: sortBy.displayName,
              selected: isSelected,
              child: Row(
                children: [
                  if (isSelected)
                    const Icon(Icons.check, size: 20, color: AppColors.primary)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: AppDimensions.spaceS),
                  Text(
                    sortBy.displayName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? AppTypography.weightSemibold
                          : AppTypography.weightMedium,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSaveSearchDialog(
    BuildContext context,
    SearchFilters filters,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveSearchDialog(filters: filters),
    );

    // Dialog returns true if search was saved successfully
    if (result == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pretraga je uspješno sačuvana!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildResultsView({
    required List<PropertyModel> results,
    required SearchViewMode viewMode,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (viewMode == SearchViewMode.map) {
      // Map view with property markers
      return MapViewWidget(
        properties: results,
        onPropertyTap: (property) {
          context.push('/property/${property.id}');
        },
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Results header
        SliverToBoxAdapter(
          child: SearchResultsHeader(
            totalResults: results.length,
            viewMode: viewMode,
            onViewModeChanged: (mode) {
              ref.read(searchViewModeNotifierProvider.notifier).setMode(mode);
            },
          ),
        ),

        // Results grid/list
        if (viewMode == SearchViewMode.grid)
          _buildGrid(results, isMobile, isTablet, isDesktop)
        else
          _buildList(results),

        // Loading more indicator - FIXED: Always show when loading
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppDimensions.spaceL),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: AppDimensions.spaceS),
                          Text(
                            'Učitavanje...',
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // FIX: Footer removed from search results - doesn't belong in mid-page context
        // Footer should only appear on landing page
        // Added spacing instead for visual balance
        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimensions.spaceXXL),
        ),
      ],
    );
  }

  Widget _buildGrid(
    List<PropertyModel> results,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    // RESPONSIVE GRID: Match Home Page breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridColumns(screenWidth);

    // FIX #1: MaxWidth constraint + FIX #3: Responsive padding (match Home Page)
    return SliverPadding(
      padding: _getResponsiveGridPadding(context, screenWidth),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppDimensions.spaceL,
          crossAxisSpacing: AppDimensions.spaceL,
          childAspectRatio: isMobile ? 0.75 : 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PremiumPropertyCard(
              property: results[index],
              onTap: () {
                context.push('/property/${results[index].id}');
              },
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildList(List<PropertyModel> results) {
    final screenWidth = MediaQuery.of(context).size.width;

    // FIX #1 & #3: Use same responsive padding as grid
    return SliverPadding(
      padding: _getResponsiveGridPadding(context, screenWidth),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceL),
              child: PremiumPropertyCard.horizontal(
                property: results[index],
                onTap: () {
                  context.push('/property/${results[index].id}');
                },
              ),
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState(
    SearchViewMode viewMode,
    bool isMobile,
    bool isTablet,
  ) {
    // FIX #2: Use same grid columns calculation as actual results
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridColumns(screenWidth);

    // Dynamic skeleton count based on screen
    final skeletonCount = SearchConstants.getSkeletonCount(crossAxisCount);

    // FIX #3: Use responsive padding
    final responsivePadding = _getResponsiveGridPadding(context, screenWidth);

    if (viewMode == SearchViewMode.list) {
      return ListView.builder(
        padding: responsivePadding,
        itemCount: skeletonCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceL),
            child: SkeletonLoader.propertyCardHorizontal(),
          );
        },
      );
    }

    return GridView.builder(
      padding: responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spaceL,
        crossAxisSpacing: AppDimensions.spaceL,
        childAspectRatio: isMobile ? 0.75 : 0.8,
      ),
      itemCount: skeletonCount,
      itemBuilder: (context, index) {
        return SkeletonLoader.propertyCard();
      },
    );
  }
}

// Backwards compatibility typedef
typedef SearchResultsScreen = PremiumSearchResultsScreen;
