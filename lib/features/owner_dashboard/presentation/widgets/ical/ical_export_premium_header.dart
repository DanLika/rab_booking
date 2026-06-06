import 'package:flutter/material.dart';

import '../../../../../core/design/tokens.dart';

/// Premium header for iCal Export screen (audit/117 §B4, mirrors `ical.jsx`
/// pattern — eyebrow + display H1 + subtitle stats).
class IcalExportPremiumHeader extends StatelessWidget {
  const IcalExportPremiumHeader({
    super.key,
    required this.unitCount,
    this.exportableCount,
  });

  /// Total units the owner manages.
  final int unitCount;

  /// Optional subset already configured with an export token. Null when the
  /// caller does not derive it yet — subtitle gracefully omits the chip.
  final int? exportableCount;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

    final String subtitle;
    if (unitCount == 0) {
      subtitle =
          'Stvorite jedinicu da generirate vlastiti iCal feed za druge platforme.';
    } else {
      final String exportPart = exportableCount == null
          ? ''
          : ' · $exportableCount s aktivnim izvozom';
      subtitle =
          '$unitCount jedinica$exportPart · podijelite svoj kalendar s Booking.com, Airbnb-om i drugim platformama.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'INTEGRACIJE · ICAL IZVOZ',
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'iCal izvoz',
          style: BBType.h1(context).copyWith(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: BBType.body(context).copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}
