/// Design-system gallery — every BB primitive × every variant × every state,
/// rendered both light and dark. Dev-only (kDebugMode gate at the route level).
///
/// Use this to verify visual parity, diacritics, tabular-figure alignment,
/// reduced-motion fallback, and tap-target heights before composing pages
/// from the primitives.
library;

import 'package:flutter/material.dart';

import '../widgets/bb_avatar.dart';
import '../widgets/bb_bottom_sheet.dart';
import '../widgets/bb_button.dart';
import '../widgets/bb_card.dart';
import '../widgets/bb_chip.dart';
import '../widgets/bb_empty_state.dart';
import '../widgets/bb_input.dart';
import '../widgets/bb_section_header.dart';
import '../widgets/bb_skeleton.dart';
import '../widgets/bb_status_badge.dart';
import 'responsive.dart';
import 'tokens.dart';

class BBGalleryScreen extends StatefulWidget {
  const BBGalleryScreen({super.key});

  @override
  State<BBGalleryScreen> createState() => _BBGalleryScreenState();
}

class _BBGalleryScreenState extends State<BBGalleryScreen> {
  bool _darkPreview = false;

  @override
  Widget build(BuildContext context) {
    // Re-wrap the whole gallery in a Theme override so light/dark variants
    // can be toggled inline from a single screen.
    final ThemeData base = _darkPreview ? ThemeData.dark() : ThemeData.light();
    return Theme(
      data: base,
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final BBResponsive r = BBResponsive.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          'BB Gallery — ${_darkPreview ? "Dark" : "Light"} '
          '(${r.deviceClass.name})',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(_darkPreview ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _darkPreview = !_darkPreview),
          ),
          const SizedBox(width: BBSpace.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BBSpace.md),
        children: <Widget>[
          const _ColorPalette(),
          const SizedBox(height: BBSpace.lg),
          const _Typography(),
          const SizedBox(height: BBSpace.lg),
          const _Buttons(),
          const SizedBox(height: BBSpace.lg),
          const _Inputs(),
          const SizedBox(height: BBSpace.lg),
          const _Chips(),
          const SizedBox(height: BBSpace.lg),
          const _StatusBadges(),
          const SizedBox(height: BBSpace.lg),
          const _Avatars(),
          const SizedBox(height: BBSpace.lg),
          const _Cards(),
          const SizedBox(height: BBSpace.lg),
          const _Skeletons(),
          const SizedBox(height: BBSpace.lg),
          const _SectionHeaders(),
          const SizedBox(height: BBSpace.lg),
          const _EmptyStates(),
          const SizedBox(height: BBSpace.lg),
          _DialogTriggers(),
          const SizedBox(height: BBSpace.lg),
          const _DiacriticsCheck(),
          const SizedBox(height: BBSpace.xl),
        ],
      ),
    );
  }
}

// ============================================================================
// Sections
// ============================================================================

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.all(BBSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: BBType.h2(context)),
          const SizedBox(height: BBSpace.sm),
          child,
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette();

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final List<({String name, Color color})> swatches =
        <({String name, Color color})>[
          (name: 'primary', color: c.primary),
          (name: 'primaryDark', color: c.primaryDark),
          (name: 'primaryLight', color: c.primaryLight),
          (name: 'secondary', color: c.secondary),
          (name: 'tertiary', color: c.tertiary),
          (name: 'success', color: c.success),
          (name: 'warning', color: c.warning),
          (name: 'error', color: c.error),
          (name: 'info', color: c.info),
          (name: 'bg', color: c.bg),
          (name: 'surface', color: c.surface),
          (name: 'surfaceVariant', color: c.surfaceVariant),
          (name: 'border', color: c.border),
          (name: 'statusConfirmed', color: c.statusConfirmed),
          (name: 'statusPending', color: c.statusPending),
          (name: 'statusCancelled', color: c.statusCancelled),
          (name: 'statusCompleted', color: c.statusCompleted),
          (name: 'statusImported', color: c.statusImported),
        ];
    return _SectionFrame(
      title: 'Colors',
      child: Wrap(
        spacing: BBSpace.xs,
        runSpacing: BBSpace.xs,
        children: <Widget>[
          for (final ({String name, Color color}) sw in swatches)
            _Swatch(name: sw.name, color: sw.color),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BBRadius.smAll,
            border: Border.all(color: BBColor.of(context).border),
          ),
        ),
        const SizedBox(height: BBSpace.xxs),
        SizedBox(
          width: 64,
          child: Text(
            name,
            style: BBType.caption(context),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Typography extends StatelessWidget {
  const _Typography();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Typography',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('display 32/700', style: BBType.display(context)),
          Text('h1 24/700', style: BBType.h1(context)),
          Text('h2 20/600', style: BBType.h2(context)),
          Text('h3 18/600', style: BBType.h3(context)),
          Text('bodyLg 16/400', style: BBType.bodyLg(context)),
          Text('body 14/400', style: BBType.body(context)),
          Text('caption 12/400', style: BBType.caption(context)),
          Text('label 13/500', style: BBType.label(context)),
          Text('mono — 0123456789', style: BBType.mono(context)),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Buttons',
      child: Wrap(
        spacing: BBSpace.sm,
        runSpacing: BBSpace.sm,
        children: <Widget>[
          BBButton(label: 'Primary', onPressed: () {}),
          BBButton(
            label: 'Secondary',
            onPressed: () {},
            variant: BBButtonVariant.secondary,
          ),
          BBButton(
            label: 'Tertiary',
            onPressed: () {},
            variant: BBButtonVariant.tertiary,
          ),
          BBButton(
            label: 'Destructive',
            onPressed: () {},
            variant: BBButtonVariant.destructive,
          ),
          const BBButton(label: 'Disabled'),
          BBButton(label: 'Loading', loading: true, onPressed: () {}),
          BBButton(
            label: 'With icons',
            onPressed: () {},
            leadingIcon: Icons.add,
            trailingIcon: Icons.arrow_forward,
          ),
          BBButton(label: 'sm', onPressed: () {}, size: BBButtonSize.sm),
          BBButton(label: 'lg', onPressed: () {}, size: BBButtonSize.lg),
        ],
      ),
    );
  }
}

class _Inputs extends StatelessWidget {
  const _Inputs();

  @override
  Widget build(BuildContext context) {
    return const _SectionFrame(
      title: 'Inputs',
      child: Column(
        children: <Widget>[
          BBInput(label: 'Email', hintText: 'ana@bookbed.io'),
          SizedBox(height: BBSpace.sm),
          BBInput(
            label: 'Password',
            obscureText: true,
            showObscureToggle: true,
            hintText: '••••••••',
          ),
          SizedBox(height: BBSpace.sm),
          BBInput(label: 'Disabled', enabled: false, initialValue: 'read-only'),
          SizedBox(height: BBSpace.sm),
          BBInput(
            label: 'Error state',
            initialValue: 'bad@',
            errorText: 'Neispravan email format.',
          ),
          SizedBox(height: BBSpace.sm),
          BBInput(
            label: 'With counter',
            hintText: 'Description',
            maxLength: 200,
            showCounter: true,
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      'Sve',
      'Aktivne',
      'Završene',
      'Otkazane',
    ];
    return _SectionFrame(
      title: 'Chips',
      child: Wrap(
        spacing: BBSpace.xs,
        runSpacing: BBSpace.xs,
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            BBChip(
              label: labels[i],
              count: i * 3,
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            ),
          const BBChip(label: 'Disabled'),
          BBChip(label: 'Icon', icon: Icons.filter_list, onTap: () {}),
        ],
      ),
    );
  }
}

class _StatusBadges extends StatelessWidget {
  const _StatusBadges();

  @override
  Widget build(BuildContext context) {
    return const _SectionFrame(
      title: 'Status badges',
      child: Wrap(
        spacing: BBSpace.xs,
        runSpacing: BBSpace.xs,
        children: <Widget>[
          BBStatusBadge(status: BBStatus.confirmed),
          BBStatusBadge(status: BBStatus.pending),
          BBStatusBadge(status: BBStatus.cancelled),
          BBStatusBadge(status: BBStatus.completed),
          BBStatusBadge(status: BBStatus.imported),
        ],
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars();

  @override
  Widget build(BuildContext context) {
    return const _SectionFrame(
      title: 'Avatars',
      child: Row(
        children: <Widget>[
          BBAvatar(name: 'Ana Marković', size: BBAvatarSize.sm),
          SizedBox(width: BBSpace.sm),
          BBAvatar(name: 'Ana Marković'),
          SizedBox(width: BBSpace.sm),
          BBAvatar(name: 'Ana Marković', size: BBAvatarSize.lg),
          SizedBox(width: BBSpace.sm),
          BBAvatar(size: BBAvatarSize.lg),
        ],
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Cards',
      child: Wrap(
        spacing: BBSpace.sm,
        runSpacing: BBSpace.sm,
        children: <Widget>[
          SizedBox(
            width: 240,
            child: BBCard(
              header: Text('Resting', style: BBType.label(context)),
              body: Text(
                'Default state. No tap. Just sits on the surface.',
                style: BBType.body(context),
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: BBCard(
              onTap: () {},
              header: Text('Hoverable', style: BBType.label(context)),
              body: Text(
                'Tap or hover (web). Lifts on hover.',
                style: BBType.body(context),
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: BBCard(
              selected: true,
              header: Text('Selected', style: BBType.label(context)),
              body: Text('2px primary border.', style: BBType.body(context)),
            ),
          ),
          SizedBox(
            width: 240,
            child: BBCard(
              disabled: true,
              header: Text('Disabled', style: BBType.label(context)),
              body: Text('50% opacity.', style: BBType.body(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeletons extends StatelessWidget {
  const _Skeletons();

  @override
  Widget build(BuildContext context) {
    return const _SectionFrame(
      title: 'Skeletons',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BBSkeleton(width: 180),
          SizedBox(height: BBSpace.xs),
          BBSkeleton(width: 240),
          SizedBox(height: BBSpace.sm),
          BBSkeleton(variant: BBSkeletonVariant.listRow),
          SizedBox(height: BBSpace.sm),
          Row(
            children: <Widget>[
              BBSkeleton(variant: BBSkeletonVariant.statTile),
              SizedBox(width: BBSpace.sm),
              BBSkeleton(variant: BBSkeletonVariant.statTile),
            ],
          ),
          SizedBox(height: BBSpace.sm),
          BBSkeleton(variant: BBSkeletonVariant.card),
        ],
      ),
    );
  }
}

class _SectionHeaders extends StatelessWidget {
  const _SectionHeaders();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Section headers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const BBSectionHeader(title: 'Sve rezervacije', count: 7),
          BBSectionHeader(
            title: 'Predstojeće',
            count: 3,
            actionLabel: 'Vidi sve',
            onActionTap: () {},
          ),
        ],
      ),
    );
  }
}

class _EmptyStates extends StatelessWidget {
  const _EmptyStates();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Empty state',
      child: BBEmptyState(
        icon: Icons.event_busy,
        headline: 'Još nema rezervacija',
        body:
            'Kad gost rezervira termin, vidjet ćeš ga ovdje sa svim detaljima.',
        primaryCtaLabel: 'Dodaj prvu rezervaciju',
        onPrimaryCta: () {},
        secondaryCtaLabel: 'Saznaj više',
        onSecondaryCta: () {},
        benefits: const <BBEmptyStateBenefit>[
          BBEmptyStateBenefit(icon: Icons.bolt, label: 'Instant rezervacije'),
          BBEmptyStateBenefit(icon: Icons.lock, label: 'Siguran payment'),
          BBEmptyStateBenefit(icon: Icons.sync, label: 'iCal sinkronizacija'),
        ],
      ),
    );
  }
}

class _DialogTriggers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Dialogs / Bottom sheets',
      child: Wrap(
        spacing: BBSpace.sm,
        children: <Widget>[
          BBButton(
            label: 'Open dialog',
            onPressed: () {
              BBDialog.show<void>(
                context: context,
                title: 'Potvrdi otkazivanje',
                child: Text(
                  'Ova rezervacija će biti otkazana. Akcija je nepovratna.',
                  style: BBType.body(context),
                ),
                actions: <Widget>[
                  BBButton(
                    label: 'Odustani',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: BBButtonVariant.tertiary,
                  ),
                  BBButton(
                    label: 'Otkaži',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: BBButtonVariant.destructive,
                  ),
                ],
              );
            },
          ),
          BBButton(
            label: 'Open sheet',
            onPressed: () {
              BBBottomSheet.show<void>(
                context: context,
                title: 'Filteri',
                child: const _Chips(),
                actions: <Widget>[
                  BBButton(
                    label: 'Primijeni',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiacriticsCheck extends StatelessWidget {
  const _DiacriticsCheck();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Croatian diacritics + tabular figures',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Č ć Đ đ Š š Ž ž — žučljive čvrste šljive',
            style: BBType.body(context),
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            '1234567890\n1100   24\n  990 1024',
            style: BBType.bodyNum(context),
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            'Napomena: brojke iznad su tabularne — uspravne kolone moraju biti poravnate.',
            style: BBType.caption(context),
          ),
        ],
      ),
    );
  }
}
