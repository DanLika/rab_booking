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
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/providers/auth_state_provider.dart';

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
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more at 80% scroll

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
          // Filter sidebar (desktop only)
          if (isDesktop)
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
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

  Widget _buildSortDropdown(SearchFilters filters) {
    return PopupMenuButton<SortBy>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sortiraj',
      initialValue: filters.sortBy,
      onSelected: (sortBy) {
        ref.read(searchFiltersNotifierProvider.notifier).updateSortBy(sortBy);
      },
      itemBuilder: (context) => SortBy.values.map((sortBy) {
        return PopupMenuItem(
          value: sortBy,
          child: Row(
            children: [
              if (sortBy == filters.sortBy)
                const Icon(Icons.check, size: 20, color: AppColors.primary)
              else
                const SizedBox(width: 20),
              const SizedBox(width: AppDimensions.spaceS),
              Text(sortBy.displayName),
            ],
          ),
        );
      }).toList(),
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

        // Loading more indicator
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spaceL),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // Footer
        const SliverToBoxAdapter(
          child: AppFooter(),
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
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return SliverPadding(
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
      ),
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
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
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
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    if (viewMode == SearchViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceL),
            child: SkeletonLoader.propertyCardHorizontal(),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spaceL,
        crossAxisSpacing: AppDimensions.spaceL,
        childAspectRatio: isMobile ? 0.75 : 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return SkeletonLoader.propertyCard();
      },
    );
  }
}

// Backwards compatibility typedef
typedef SearchResultsScreen = PremiumSearchResultsScreen;
