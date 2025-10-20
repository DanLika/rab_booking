import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/home_search_provider.dart';

// Destinations on Rab Island
const List<String> rabDestinations = [
  'Rab Town',
  'Lopar',
  'Banjol',
  'Barbat',
  'Kampor',
  'Suha Punta',
  'Supetarska Draga',
  'Mundanije',
  'Palit',
];

/// Premium HomeHeroSection with functional search
class HomeHeroSectionPremium extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String? backgroundImage;

  const HomeHeroSectionPremium({
    super.key,
    this.title = 'Discover Your Perfect Getaway on Rab Island',
    this.subtitle = 'Premium villas, apartments & vacation homes in the heart of the Adriatic',
    this.backgroundImage = 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1600',
  });

  @override
  ConsumerState<HomeHeroSectionPremium> createState() => _HomeHeroSectionPremiumState();
}

class _HomeHeroSectionPremiumState extends ConsumerState<HomeHeroSectionPremium>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TextEditingController _destinationController;
  late AnimationController _searchButtonAnimController;
  late Animation<double> _searchButtonScale;

  // Focus nodes
  final _destinationFocus = FocusNode();

  // Hover states
  bool _isSearchButtonHovered = false;
  bool _isPropertyTypeHovered = false;

  // Dropdown states
  List<String> _filteredDestinations = [];
  bool _showDestinationDropdown = false;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController();
    _filteredDestinations = rabDestinations;

    // Search button pulse animation
    _searchButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _searchButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _searchButtonAnimController, curve: Curves.easeInOut),
    );

    // Destination controller listener for autocomplete
    _destinationController.addListener(() {
      final query = _destinationController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _filteredDestinations = rabDestinations;
          _showDestinationDropdown = false;
        } else {
          _filteredDestinations = rabDestinations
              .where((dest) => dest.toLowerCase().contains(query))
              .toList();
          _showDestinationDropdown = true;
        }
      });
    });

    _destinationFocus.addListener(() {
      setState(() {
        _showDestinationDropdown = _destinationFocus.hasFocus && _destinationController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _searchButtonAnimController.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final searchState = ref.read(homeSearchProvider);

    context.goToSearch(
      location: searchState.destination,
      checkIn: searchState.checkIn?.toIso8601String(),
      checkOut: searchState.checkOut?.toIso8601String(),
      maxGuests: searchState.guests > 0 ? searchState.guests : null,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final currentState = ref.read(homeSearchProvider);
    final initialDate = isCheckIn
        ? currentState.checkIn ?? now
        : currentState.checkOut ?? (currentState.checkIn?.add(const Duration(days: 3)) ?? now.add(const Duration(days: 3)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isCheckIn) {
        ref.read(homeSearchProvider.notifier).setCheckIn(picked);
      } else {
        ref.read(homeSearchProvider.notifier).setCheckOut(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(homeSearchProvider);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: context.isMobile ? 600 : 700,
      ),
      decoration: _buildDecoration(isDark),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Background image
          if (widget.backgroundImage != null)
            Positioned.fill(
              child: _PremiumBackgroundImage(imageUrl: widget.backgroundImage!),
            ),

          // Gradient overlay
          Positioned.fill(
            child: _AnimatedGradientOverlay(),
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppDimensions.containerXL),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                    vertical: context.isMobile ? AppDimensions.spaceXXL : AppDimensions.sectionPaddingVerticalDesktop,
                  ),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  _buildTitle(context)
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: AppDimensions.spaceM),

                  // Subtitle
                  _buildSubtitle(context)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),

                  SizedBox(
                    height: context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
                  ),

                  // Search widget
                  _buildPremiumSearchWidget(context, searchState)
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 900.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                ],
              ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    if (widget.backgroundImage != null) {
      return const BoxDecoration();
    }
    return const BoxDecoration(gradient: AppColors.heroGradient);
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      widget.title,
      style: (context.isMobile ? AppTypography.h1 : AppTypography.heroTitle.copyWith(fontSize: 72)).copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          Shadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 60,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      widget.subtitle,
      style: (context.isMobile ? AppTypography.bodyLarge : AppTypography.heroSubtitle).copyWith(
        color: Colors.white.withValues(alpha: 0.95),
        fontWeight: FontWeight.w400,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
    );
  }

  Widget _buildPremiumSearchWidget(BuildContext context, HomeSearchState searchState) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.containerM),
        child: _GlassMorphicCard(
        child: Padding(
          padding: EdgeInsets.all(context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property Type Dropdown + Destination (Desktop)
              if (!context.isMobile) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPropertyTypeDropdown(searchState),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      flex: 3,
                      child: _buildDestinationField(searchState),
                    ),
                  ],
                ),
              ],

              // Mobile: Stack vertically
              if (context.isMobile) ...[
                _buildPropertyTypeDropdown(searchState),
                const SizedBox(height: AppDimensions.spaceM),
                _buildDestinationField(searchState),
              ],

              const SizedBox(height: AppDimensions.spaceM),

              // Dates + Guests
              if (!context.isMobile) ...[
                Row(
                  children: [
                    Expanded(child: _buildCheckInField(searchState)),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(child: _buildCheckOutField(searchState)),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(child: _buildGuestsDropdown(searchState)),
                  ],
                ),
              ],

              if (context.isMobile) ...[
                _buildCheckInField(searchState),
                const SizedBox(height: AppDimensions.spaceM),
                _buildCheckOutField(searchState),
                const SizedBox(height: AppDimensions.spaceM),
                _buildGuestsDropdown(searchState),
              ],

              const SizedBox(height: AppDimensions.spaceL), // REDUCED from spaceXL

              // Search Button
              _buildPremiumSearchButton(),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPropertyTypeDropdown(HomeSearchState searchState) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isPropertyTypeHovered = true),
      onExit: (_) => setState(() => _isPropertyTypeHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48, // FIXED HEIGHT
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12), // REDUCED from 20
          border: Border.all(
            color: _isPropertyTypeHovered
                ? AppColors.primary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: _isPropertyTypeHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: searchState.propertyType,
            hint: Row(
              children: [
                Icon(Icons.home_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  'Property Type',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.8), size: 20),
            dropdownColor: AppColors.surfaceDark,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Types')),
              DropdownMenuItem(value: 'villa', child: Text('🏰 Villa')),
              DropdownMenuItem(value: 'apartment', child: Text('🏢 Apartment')),
              DropdownMenuItem(value: 'house', child: Text('🏡 House')),
              DropdownMenuItem(value: 'studio', child: Text('🛋️ Studio')),
            ],
            onChanged: (value) {
              ref.read(homeSearchProvider.notifier).setPropertyType(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationField(HomeSearchState searchState) {
    return Stack(
      children: [
        _PremiumTextField(
          controller: _destinationController,
          focusNode: _destinationFocus,
          hint: 'Where do you want to go?',
          icon: Icons.location_on_outlined,
          onChanged: (value) {
            ref.read(homeSearchProvider.notifier).setDestination(value);
          },
        ),
        // Autocomplete dropdown
        if (_showDestinationDropdown && _filteredDestinations.isNotEmpty)
          Positioned(
            top: 52, // Below input field
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceDark,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(4),
                  itemCount: _filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final destination = _filteredDestinations[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city, color: AppColors.primary, size: 20),
                      title: Text(
                        destination,
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      onTap: () {
                        _destinationController.text = destination;
                        ref.read(homeSearchProvider.notifier).setDestination(destination);
                        setState(() {
                          _showDestinationDropdown = false;
                        });
                        _destinationFocus.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        // No results message
        if (_showDestinationDropdown && _filteredDestinations.isEmpty)
          Positioned(
            top: 52,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceDark,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                child: Text(
                  'No results for "${_destinationController.text}"',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckInField(HomeSearchState searchState) {
    return _PremiumDateField(
      hint: 'Check-in',
      icon: Icons.calendar_today_outlined,
      date: searchState.checkIn,
      onTap: () => _selectDate(context, true),
    );
  }

  Widget _buildCheckOutField(HomeSearchState searchState) {
    return _PremiumDateField(
      hint: 'Check-out',
      icon: Icons.event_outlined,
      date: searchState.checkOut,
      onTap: () => _selectDate(context, false),
    );
  }

  Widget _buildGuestsDropdown(HomeSearchState searchState) {
    return _PremiumGuestsDropdown(
      guests: searchState.guests,
      onChanged: (value) {
        if (value != null) {
          ref.read(homeSearchProvider.notifier).setGuests(value);
        }
      },
    );
  }

  Widget _buildPremiumSearchButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isSearchButtonHovered = true),
      onExit: (_) => setState(() => _isSearchButtonHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _searchButtonAnimController.forward(),
        onTapUp: (_) {
          _searchButtonAnimController.reverse();
          _handleSearch();
        },
        onTapCancel: () => _searchButtonAnimController.reverse(),
        child: ScaleTransition(
          scale: _searchButtonScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 56, // Consistent height
            decoration: BoxDecoration(
              gradient: _isSearchButtonHovered
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF0052CC),
                        Color(0xFF0066FF),
                        Color(0xFF3385FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12), // CONSISTENT with inputs
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _isSearchButtonHovered ? 0.5 : 0.3),
                  blurRadius: _isSearchButtonHovered ? 30 : 20,
                  offset: Offset(0, _isSearchButtonHovered ? 12 : 8),
                ),
                if (_isSearchButtonHovered)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSearch,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 24) // Consistent icon size
                          .animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          )
                          .shimmer(
                            duration: 2000.ms,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Text(
                        'Search Properties',
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PREMIUM COMPONENTS
// ============================================================================

class _GlassMorphicCard extends StatelessWidget {
  final Widget child;

  const _GlassMorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 80,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const _PremiumTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.onChanged,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48, // FIXED HEIGHT
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isFocused ? 0.2 : 0.15),
          borderRadius: BorderRadius.circular(12), // REDUCED from 20
          border: Border.all(
            color: isFocused
                ? AppColors.primary.withValues(alpha: 0.8)
                : _isHovered
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(widget.icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceM,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumDateField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;

  const _PremiumDateField({
    required this.hint,
    required this.icon,
    required this.date,
    required this.onTap,
  });

  @override
  State<_PremiumDateField> createState() => _PremiumDateFieldState();
}

class _PremiumDateFieldState extends State<_PremiumDateField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateText = widget.date != null ? DateFormat('MMM dd, yyyy').format(widget.date!) : widget.hint;
    final hasDate = widget.date != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48, // FIXED HEIGHT
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12), // CONSISTENT
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Text(
                  dateText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasDate ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumGuestsDropdown extends StatefulWidget {
  final int guests;
  final ValueChanged<int?> onChanged;

  const _PremiumGuestsDropdown({
    required this.guests,
    required this.onChanged,
  });

  @override
  State<_PremiumGuestsDropdown> createState() => _PremiumGuestsDropdownState();
}

class _PremiumGuestsDropdownState extends State<_PremiumGuestsDropdown> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48, // FIXED HEIGHT
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12), // CONSISTENT
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: widget.guests,
            icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.8), size: 20),
            dropdownColor: AppColors.surfaceDark,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: AppDimensions.spaceS),
                    const Text('1 Guest'),
                  ],
                ),
              ),
              ...List.generate(9, (index) {
                final count = index + 2;
                return DropdownMenuItem(
                  value: count,
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.8), size: 20),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text('$count Guests'),
                    ],
                  ),
                );
              }),
            ],
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

class _PremiumBackgroundImage extends StatelessWidget {
  final String imageUrl;

  const _PremiumBackgroundImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primary,
              child: Center(
                child: Icon(Icons.villa, size: 100, color: Colors.white.withValues(alpha: 0.3)),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedGradientOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.premiumOverlayGradient,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .shimmer(
          duration: 4000.ms,
          color: AppColors.primary.withValues(alpha: 0.1),
        );
  }
}
