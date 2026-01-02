import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/navigation_helpers.dart';

/// Adaptive Bottom Navigation Bar
///
/// Platform-specific behavior (NO runtime overhead - uses compile-time kIsWeb):
/// - **iOS/Android apps**: Fixed bottom navigation (always visible)
/// - **Web**: Auto-hide on scroll (hide on scroll down, show on scroll up)
///
/// Uses compile-time constant `kIsWeb` so there's ZERO performance impact.
/// The unused code branch is tree-shaken during compilation.
class AdaptiveBottomNavigationBar extends ConsumerStatefulWidget {
  const AdaptiveBottomNavigationBar({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<AdaptiveBottomNavigationBar> createState() =>
      _AdaptiveBottomNavigationBarState();
}

class _AdaptiveBottomNavigationBarState
    extends ConsumerState<AdaptiveBottomNavigationBar>
    with SingleTickerProviderStateMixin {

  // Web-only: Auto-hide behaviour
  bool _isVisible = true;
  double _lastScrollOffset = 0;

  // Animation controller for smooth hide/show
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1), // Slide down to hide
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Only attach scroll listener for web
    if (kIsWeb) {
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      widget.scrollController.removeListener(_onScroll);
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Web-only: Auto-hide logic
    if (!kIsWeb) return;

    final currentScrollOffset = widget.scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;

    // Threshold to prevent jitter
    const threshold = 5.0;

    if (scrollDelta > threshold && _isVisible) {
      // Scrolling down - hide navbar
      setState(() => _isVisible = false);
      _animationController.forward();
    } else if (scrollDelta < -threshold && !_isVisible) {
      // Scrolling up - show navbar
      setState(() => _isVisible = true);
      _animationController.reverse();
    }

    _lastScrollOffset = currentScrollOffset;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    // Determine current index based on route
    final int currentIndex = _getIndexFromRoute(currentRoute);

    // Mobile apps: Always visible (no animation)
    // Web: Animated slide up/down
    final navigationBar = _buildNavigationBar(context, currentIndex);

    if (kIsWeb) {
      // Web: Animated auto-hide
      return SlideTransition(
        position: _slideAnimation,
        child: navigationBar,
      );
    } else {
      // iOS/Android: Always visible
      return navigationBar;
    }
  }

  Widget _buildNavigationBar(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onDestinationSelected(context, index),
          destinations: _buildDestinations(context),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
        ),
      ),
    );
  }

  List<Widget> _buildDestinations(BuildContext context) {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
        tooltip: 'Go to Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Search',
        tooltip: 'Search properties',
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_outline),
        selectedIcon: Icon(Icons.bookmark),
        label: 'Favorites',
        tooltip: 'View favorites',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today),
        label: 'Bookings',
        tooltip: 'My bookings',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'My profile',
      ),
    ];
  }

  int _getIndexFromRoute(String route) {
    if (route == Routes.home || route == '/') return 0;
    if (route.startsWith('/search')) return 1;
    if (route == Routes.favorites) return 2;
    if (route.startsWith('/booking')) return 3;
    if (route == Routes.profile) return 4;
    return 0; // Default to home
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.goToSearch();
        break;
      case 2:
        context.go(Routes.favorites);
        break;
      case 3:
        context.go(Routes.myBookings);
        break;
      case 4:
        context.go(Routes.profile);
        break;
    }
  }
}

/// Alternative: Material 2 style BottomNavigationBar
/// (Uncomment if you prefer classic Material 2 design)
/*
class AdaptiveBottomNavigationBarM2 extends ConsumerStatefulWidget {
  const AdaptiveBottomNavigationBarM2({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<AdaptiveBottomNavigationBarM2> createState() =>
      _AdaptiveBottomNavigationBarM2State();
}

class _AdaptiveBottomNavigationBarM2State
    extends ConsumerState<AdaptiveBottomNavigationBarM2>
    with SingleTickerProviderStateMixin {

  bool _isVisible = true;
  double _lastScrollOffset = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (kIsWeb) {
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      widget.scrollController.removeListener(_onScroll);
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!kIsWeb) return;

    final currentScrollOffset = widget.scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;
    const threshold = 5.0;

    if (scrollDelta > threshold && _isVisible) {
      setState(() => _isVisible = false);
      _animationController.forward();
    } else if (scrollDelta < -threshold && !_isVisible) {
      setState(() => _isVisible = true);
      _animationController.reverse();
    }

    _lastScrollOffset = currentScrollOffset;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    int currentIndex = _getIndexFromRoute(currentRoute);

    final navigationBar = BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onDestinationSelected(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryLight,
      selectedLabelStyle: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTypography.caption,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_outline),
          activeIcon: Icon(Icons.bookmark),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );

    if (kIsWeb) {
      return SlideTransition(
        position: _slideAnimation,
        child: navigationBar,
      );
    } else {
      return navigationBar;
    }
  }

  int _getIndexFromRoute(String route) {
    if (route == Routes.home || route == '/') return 0;
    if (route.startsWith('/search')) return 1;
    if (route == Routes.favorites) return 2;
    if (route.startsWith('/booking')) return 3;
    if (route == Routes.profile) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.goToSearch();
        break;
      case 2:
        context.go(Routes.favorites);
        break;
      case 3:
        context.go(Routes.myBookings);
        break;
      case 4:
        context.go(Routes.profile);
        break;
    }
  }
}
*/
