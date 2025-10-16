import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

/// Design System Demo Screen
/// Showcases all design system components: colors, typography, buttons, cards, inputs
class DesignSystemDemoScreen extends StatelessWidget {
  const DesignSystemDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // COLOR PALETTE
            // ============================================================
            _buildSectionTitle('Color Palette'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildColorSection('Primary Colors', [
              _ColorItem('Primary', AppColors.primary, '#0891B2'),
              _ColorItem('Primary Dark', AppColors.primaryDark, '#0E7490'),
              _ColorItem('Primary Light', AppColors.primaryLight, '#06B6D4'),
            ]),
            const SizedBox(height: AppDimensions.spaceL),
            _buildColorSection('Secondary Colors', [
              _ColorItem('Secondary', AppColors.secondary, '#F59E0B'),
              _ColorItem('Secondary Dark', AppColors.secondaryDark, '#D97706'),
              _ColorItem('Secondary Light', AppColors.secondaryLight, '#FBBF24'),
            ]),
            const SizedBox(height: AppDimensions.spaceL),
            _buildColorSection('Semantic Colors', [
              _ColorItem('Success', AppColors.success, '#10B981'),
              _ColorItem('Error', AppColors.error, '#EF4444'),
              _ColorItem('Warning', AppColors.warning, '#F97316'),
              _ColorItem('Info', AppColors.info, '#3B82F6'),
            ]),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // TYPOGRAPHY
            // ============================================================
            _buildSectionTitle('Typography'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildTypographySection(context),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // BUTTONS
            // ============================================================
            _buildSectionTitle('Buttons'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildButtonsSection(),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // CARDS
            // ============================================================
            _buildSectionTitle('Cards'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildCardsSection(),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // INPUT FIELDS
            // ============================================================
            _buildSectionTitle('Input Fields'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildInputFieldsSection(),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // CHIPS
            // ============================================================
            _buildSectionTitle('Chips'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildChipsSection(),
            const SizedBox(height: AppDimensions.spaceXL),

            // ============================================================
            // SPACING & DIMENSIONS
            // ============================================================
            _buildSectionTitle('Spacing Scale'),
            const SizedBox(height: AppDimensions.spaceM),
            _buildSpacingSection(),
            const SizedBox(height: AppDimensions.spaceXXL),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.textTheme.headlineSmall,
    );
  }

  Widget _buildColorSection(String title, List<_ColorItem> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Wrap(
          spacing: AppDimensions.spaceM,
          runSpacing: AppDimensions.spaceM,
          children: colors.map((item) => _buildColorBox(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildColorBox(_ColorItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.borderLight),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        Text(
          item.name,
          style: AppTypography.textTheme.labelSmall,
        ),
        Text(
          item.hex,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTypographySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display styles
        Text('Display Large', style: AppTypography.textTheme.displayLarge),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Display Medium', style: AppTypography.textTheme.displayMedium),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Display Small', style: AppTypography.textTheme.displaySmall),
        const SizedBox(height: AppDimensions.spaceL),

        // Headline styles
        Text('Headline Large', style: AppTypography.textTheme.headlineLarge),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Headline Medium', style: AppTypography.textTheme.headlineMedium),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Headline Small', style: AppTypography.textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.spaceL),

        // Title styles
        Text('Title Large', style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Title Medium', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Title Small', style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.spaceL),

        // Body styles
        Text(
          'Body Large - Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          style: AppTypography.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          'Body Medium - Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          'Body Small - Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          style: AppTypography.textTheme.bodySmall,
        ),
        const SizedBox(height: AppDimensions.spaceL),

        // Custom styles
        Text('Hero Title', style: AppTypography.heroTitle),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Property Card Title', style: AppTypography.propertyCardTitle),
        const SizedBox(height: AppDimensions.spaceS),
        Text('Price: €120/night', style: AppTypography.priceText),
      ],
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Elevated buttons
        Text('Elevated Buttons', style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Primary Button'),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            const ElevatedButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceL),

        // Outlined buttons
        Text('Outlined Buttons', style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          children: [
            OutlinedButton(
              onPressed: () {},
              child: const Text('Secondary Button'),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            const OutlinedButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceL),

        // Text buttons
        Text('Text Buttons', style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            const TextButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceL),

        // Icon buttons
        Text('Icon Buttons', style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Card Title',
                  style: AppTypography.propertyCardTitle,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Location: Rab, Croatia',
                  style: AppTypography.propertyCardSubtitle,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€120/night',
                      style: AppTypography.priceText.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.star, size: 20),
                        const SizedBox(width: AppDimensions.spaceXXS),
                        Text('4.8', style: AppTypography.textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.villa,
                    color: AppColors.primary,
                    size: AppDimensions.iconSizeL,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feature Card',
                        style: AppTypography.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        'Subtitle text goes here',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: Icon(Icons.visibility_off),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppDimensions.spaceM),
        TextField(
          decoration: InputDecoration(
            labelText: 'Error State',
            hintText: 'Invalid input',
            errorText: 'This field is required',
            prefixIcon: const Icon(Icons.error),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipsSection() {
    return Wrap(
      spacing: AppDimensions.spaceS,
      runSpacing: AppDimensions.spaceS,
      children: [
        Chip(
          label: const Text('Chip'),
          onDeleted: () {},
        ),
        const Chip(
          label: Text('Selected Chip'),
          backgroundColor: AppColors.primary,
        ),
        const Chip(
          label: Text('With Avatar'),
          avatar: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text('R'),
          ),
        ),
        ActionChip(
          label: const Text('Action Chip'),
          onPressed: () {},
        ),
        FilterChip(
          label: const Text('Filter Chip'),
          selected: true,
          onSelected: (value) {},
        ),
      ],
    );
  }

  Widget _buildSpacingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpacingItem('XXS', AppDimensions.spaceXXS),
        _buildSpacingItem('XS', AppDimensions.spaceXS),
        _buildSpacingItem('S', AppDimensions.spaceS),
        _buildSpacingItem('M', AppDimensions.spaceM),
        _buildSpacingItem('L', AppDimensions.spaceL),
        _buildSpacingItem('XL', AppDimensions.spaceXL),
        _buildSpacingItem('XXL', AppDimensions.spaceXXL),
        _buildSpacingItem('XXXL', AppDimensions.spaceXXXL),
      ],
    );
  }

  Widget _buildSpacingItem(String name, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              name,
              style: AppTypography.textTheme.labelMedium,
            ),
          ),
          Container(
            width: size,
            height: 24,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Text(
            '${size.toInt()}px',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _ColorItem {
  final String name;
  final Color color;
  final String hex;

  _ColorItem(this.name, this.color, this.hex);
}
