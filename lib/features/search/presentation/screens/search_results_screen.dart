import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/property_card.dart';
import '../providers/search_results_provider.dart';
import '../providers/search_state_provider.dart';
import '../providers/search_view_mode_provider.dart';
import '../widgets/filter_panel_widget.dart';
import '../../domain/models/search_filters.dart';

/// Search results screen with grid/list view and filters
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    this.query,
    this.location,
    this.maxGuests,
    this.checkIn,
    this.checkOut,
    super.key,
  });

  final String? query;
  final String? location;
  final int? maxGuests;
  final String? checkIn;
  final String? checkOut;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize filters from URL parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFilters();
    });
  }

  void _initializeFilters() {
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);

    if (widget.location != null) {
      notifier.updateLocation(widget.location!);
    }

    if (widget.maxGuests != null) {
      notifier.updateGuests(widget.maxGuests!);
    }

    if (widget.checkIn != null && widget.checkOut != null) {
      try {
        final checkIn = DateTime.parse(widget.checkIn!);
        final checkOut = DateTime.parse(widget.checkOut!);
        notifier.updateDates(checkIn, checkOut);
      } catch (e) {
        // Invalid date format, ignore
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    setState(() => _isLoadingMore = true);

    // Load next page
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);
    await notifier.loadNextPage();

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final filters = ref.watch(searchFiltersNotifierProvider);
    final viewMode = ref.watch(searchViewModeNotifierProvider);

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
                     MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchSummary(filters),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(
              viewMode == SearchViewMode.grid
                ? Icons.view_list
                : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(searchViewModeNotifierProvider.notifier).toggle();
            },
            tooltip: viewMode == SearchViewMode.grid
              ? 'Prikaz kao lista'
              : 'Prikaz kao grid',
          ),

          // Sort dropdown
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sortiraj',
            onSelected: (sortBy) {
              ref.read(searchFiltersNotifierProvider.notifier).updateSortBy(sortBy);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortBy.recommended,
                child: Text('Preporučeno'),
              ),
              const PopupMenuItem(
                value: SortBy.priceLowToHigh,
                child: Text('Cijena: Niska → Visoka'),
              ),
              const PopupMenuItem(
                value: SortBy.priceHighToLow,
                child: Text('Cijena: Visoka → Niska'),
              ),
              const PopupMenuItem(
                value: SortBy.rating,
                child: Text('Ocjena'),
              ),
              const PopupMenuItem(
                value: SortBy.newest,
                child: Text('Najnovije'),
              ),
            ],
          ),

          // Filter button (mobile only)
          if (isMobile)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (filters.hasActiveFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${filters.filterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                FilterPanelWidget.showBottomSheet(context);
              },
              tooltip: 'Filteri',
            ),
        ],
      ),
      body: Row(
        children: [
          // Desktop sidebar with filters
          if (!isMobile && !isTablet)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: const FilterPanelWidget(),
            ),

          // Main content area
          Expanded(
            child: resultsAsync.when(
              data: (properties) => _buildResultsView(
                properties,
                viewMode,
                isMobile,
                isTablet,
              ),
              loading: () => _buildLoadingState(isMobile),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(SearchFilters filters) {
    final parts = <String>[];

    if (filters.location != null && filters.location!.isNotEmpty) {
      parts.add(filters.location!);
    }

    if (filters.checkIn != null && filters.checkOut != null) {
      final checkIn = filters.checkIn!;
      final checkOut = filters.checkOut!;
      parts.add('${checkIn.day}.${checkIn.month}. - ${checkOut.day}.${checkOut.month}.');
    }

    if (filters.guests > 0) {
      parts.add('${filters.guests} ${filters.guests == 1 ? 'gost' : 'gostiju'}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rezultati pretrage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (parts.isNotEmpty)
          Text(
            parts.join(' • '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildResultsView(
    List<dynamic> properties,
    SearchViewMode viewMode,
    bool isMobile,
    bool isTablet,
  ) {
    if (properties.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(
            '${properties.length} ${properties.length == 1 ? 'smještaj pronađen' : 'smještaja pronađeno'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Results grid/list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(searchResultsProvider);
            },
            child: viewMode == SearchViewMode.grid
              ? _buildGridView(properties, isMobile, isTablet)
              : _buildListView(properties),
          ),
        ),

        // Loading more indicator
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildGridView(
    List<dynamic> properties,
    bool isMobile,
    bool isTablet,
  ) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return PropertyCard(property: properties[index]);
      },
    );
  }

  Widget _buildListView(List<dynamic> properties) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return PropertyCard(property: properties[index]);
      },
    );
  }

  Widget _buildLoadingState(bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

          // Content placeholder
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: 100,
                  color: Colors.grey[200],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Nema rezultata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pokušajte promijeniti filtere ili kriterije pretrage.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(searchFiltersNotifierProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Očisti sve filtere'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Greška prilikom učitavanja',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(searchResultsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
