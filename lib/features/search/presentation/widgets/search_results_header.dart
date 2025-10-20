import 'package:flutter/material.dart';
import '../providers/search_view_mode_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Search results header with count and view mode toggles
class SearchResultsHeader extends StatelessWidget {
  const SearchResultsHeader({
    required this.totalResults,
    required this.viewMode,
    this.onViewModeChanged,
    super.key,
  });

  final int totalResults;
  final SearchViewMode viewMode;
  final ValueChanged<SearchViewMode>? onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
      ),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Results count
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyLarge.copyWith(
                  color: context.textColor,
                ),
                children: [
                  TextSpan(
                    text: '$totalResults ',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: _getResultsText(totalResults),
                  ),
                ],
              ),
            ),
          ),

          // View mode toggles (desktop only)
          if (!isMobile) ...[
            _buildViewModeButton(
              icon: Icons.grid_view,
              isSelected: viewMode == SearchViewMode.grid,
              onTap: () => onViewModeChanged?.call(SearchViewMode.grid),
              tooltip: 'Grid prikaz',
            ),
            const SizedBox(width: AppDimensions.spaceXS),
            _buildViewModeButton(
              icon: Icons.view_list,
              isSelected: viewMode == SearchViewMode.list,
              onTap: () => onViewModeChanged?.call(SearchViewMode.list),
              tooltip: 'Lista prikaz',
            ),
            const SizedBox(width: AppDimensions.spaceXS),
            _buildViewModeButton(
              icon: Icons.map,
              isSelected: viewMode == SearchViewMode.map,
              onTap: () => onViewModeChanged?.call(SearchViewMode.map),
              tooltip: 'Mapa prikaz',
            ),
          ],
        ],
      ),
    );
  }

  String _getResultsText(int count) {
    if (count == 1) return 'smještaj pronađen';
    if (count < 5) return 'smještaja pronađeno';
    return 'smještaja pronađeno';
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Builder(
      builder: (context) {
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: context.borderColor,
                        ),
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconM,
                  color: isSelected ? context.textColorInverted : context.iconColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
