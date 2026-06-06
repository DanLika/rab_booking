import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../screens/cookies_policy_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_conditions_screen.dart';

/// Cross-doc tab row for the legal trio (Terms · Privacy · Cookies).
///
/// Renders `BbChip(variant: tab)` for each sibling. Tapping a sibling chip
/// calls `Navigator.pushReplacement(MaterialPageRoute(...))` so the back stack
/// stays balanced — works in both pre-auth modal-push contexts (register
/// `Navigator.of(context).push(MaterialPageRoute(builder: _ => TermsScreen))`)
/// and post-auth go_router routes (`OwnerRoutes.privacyPolicy` etc.).
///
/// Mirrors `design_handoff/source/legal.jsx` `LegalTabsRow`.
enum LegalTab { terms, privacy, cookies }

class LegalTabsRow extends StatelessWidget {
  const LegalTabsRow({super.key, required this.current});

  final LegalTab current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        BbChip(
          label: l10n.termsScreenTitle,
          variant: BbChipVariant.tab,
          selected: current == LegalTab.terms,
          onTap: current == LegalTab.terms
              ? null
              : () => _swap(context, const TermsConditionsScreen()),
        ),
        BbChip(
          label: l10n.privacyScreenTitle,
          variant: BbChipVariant.tab,
          selected: current == LegalTab.privacy,
          onTap: current == LegalTab.privacy
              ? null
              : () => _swap(context, const PrivacyPolicyScreen()),
        ),
        BbChip(
          label: l10n.cookiesScreenTitle,
          variant: BbChipVariant.tab,
          selected: current == LegalTab.cookies,
          onTap: current == LegalTab.cookies
              ? null
              : () => _swap(context, const CookiesPolicyScreen()),
        ),
      ],
    );
  }

  void _swap(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
