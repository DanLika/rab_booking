import 'package:flutter/material.dart';

/// List virtualization utilities for optimal scrolling performance
/// Only renders visible items + buffer, dramatically reduces memory usage

/// Optimized grid view with automatic virtualization
class VirtualizedGridView<T> extends StatelessWidget {
  const VirtualizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    // Use GridView.builder for automatic virtualization
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// Optimized list view with automatic virtualization
class VirtualizedListView<T> extends StatelessWidget {
  const VirtualizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    // Use ListView.builder for automatic virtualization
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, items[index], index);
        },
        separatorBuilder: separatorBuilder!,
      );
    }

    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

/// Lazy loading list view with infinite scroll
class LazyLoadingListView<T> extends StatefulWidget {
  const LazyLoadingListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.loadingWidget,
    this.padding,
    this.physics,
    this.separatorBuilder,
    this.threshold = 0.8, // Load more when 80% scrolled
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final double threshold;

  @override
  State<LazyLoadingListView<T>> createState() =>
      _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.threshold;

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      await widget.onLoadMore();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: widget.separatorBuilder ??
          (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }

        // Loading indicator at the end
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.loadingWidget ??
                const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

/// Sliver list with automatic virtualization
class VirtualizedSliverList<T> extends StatelessWidget {
  const VirtualizedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return itemBuilder(context, items[index], index);
        },
        childCount: items.length,
      ),
    );
  }
}

/// Sliver grid with automatic virtualization
class VirtualizedSliverGrid<T> extends StatelessWidget {
  const VirtualizedSliverGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return itemBuilder(context, items[index], index);
        },
        childCount: items.length,
      ),
    );
  }
}

/// Paginated list view with page-based loading
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    required this.fetchPage,
    this.pageSize = 20,
    this.initialPage = 1,
    this.padding,
    this.physics,
    this.separatorBuilder,
    this.emptyWidget,
    this.errorWidget,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int pageSize) fetchPage;
  final int pageSize;
  final int initialPage;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget? emptyWidget;
  final Widget Function(Object error)? errorWidget;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || !_hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.8) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchPage(_currentPage, widget.pageSize);

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget?.call(_error!) ??
          Center(child: Text('Error: $_error'));
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(child: Text('No items found'));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: widget.separatorBuilder ??
          (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return widget.itemBuilder(context, _items[index], index);
        }

        // Loading indicator at the end
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
