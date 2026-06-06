import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/design/tokens.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../providers/owner_properties_provider.dart';

/// Premium hero header for the Unit Hub screen (audit/117 §B4 +
/// prompt: "Jedinice premium hero + KPI per 06-owner.png").
///
/// Eyebrow date + display H1 + 4-tile KPI strip:
///   Objekti · Jedinice · Dostupne · Kapacitet
///
/// FROZEN: Cjenovnik tab unaffected. This widget only adds the hero +
/// KPI strip ABOVE the master/detail split in `unified_unit_hub_screen.dart`.
class UnitsPremiumHeader extends ConsumerWidget {
  const UnitsPremiumHeader({super.key, required this.title});
  final String title;

  static const List<String> _hrMonths = <String>[
    'siječnja',
    'veljače',
    'ožujka',
    'travnja',
    'svibnja',
    'lipnja',
    'srpnja',
    'kolovoza',
    'rujna',
    'listopada',
    'studenoga',
    'prosinca',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BBColorSet c = BBColor.of(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

    final List<PropertyModel> properties =
        ref.watch(ownerPropertiesProvider).valueOrNull ??
        const <PropertyModel>[];
    final List<UnitModel> units =
        ref.watch(ownerUnitsProvider).valueOrNull ?? const <UnitModel>[];

    final int propertyCount = properties.length;
    final int unitCount = units.length;
    final int availableCount = units.where((u) => u.isAvailable).length;
    final int totalCapacity = units.fold<int>(0, (sum, u) => sum + u.maxGuests);

    final DateTime now = DateTime.now();
    final String eyebrow =
        '${now.day}. ${_hrMonths[(now.month - 1).clamp(0, 11)]} ${now.year} · JEDINICE';

    final EdgeInsets pad = EdgeInsets.fromLTRB(
      isMobile ? 16 : 24,
      isMobile ? 12 : 18,
      isMobile ? 16 : 24,
      isMobile ? 4 : 8,
    );

    final Widget headerRow = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: BBType.h1(context).copyWith(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );

    final List<Widget> tiles = <Widget>[
      _Tile(
        icon: 'domain',
        label: 'OBJEKTI',
        value: '$propertyCount',
        tone: c.primary,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'bed',
        label: 'JEDINICE',
        value: '$unitCount',
        tone: c.info,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'check_circle',
        label: 'DOSTUPNE',
        value: '$availableCount',
        tone: c.success,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'group',
        label: 'KAPACITET',
        value: '$totalCapacity',
        tone: c.tertiary,
        isMobile: isMobile,
      ),
    ];

    final Widget kpiStrip = isMobile
        ? Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[3]),
                ],
              ),
            ],
          )
        : Row(
            children: <Widget>[
              for (int i = 0; i < tiles.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: tiles[i]),
              ],
            ],
          );

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          headerRow,
          SizedBox(height: isMobile ? 12 : 16),
          kpiStrip,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.isMobile,
  });

  final String icon;
  final String label;
  final String value;
  final Color tone;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: <Widget>[
          Container(
            width: isMobile ? 28 : 32,
            height: isMobile ? 28 : 32,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: isMobile ? 15 : 17, color: tone),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: BBType.caption(context).copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: BBType.bodyLgNum(context).copyWith(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
