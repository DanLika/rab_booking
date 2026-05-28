/// Dev-only Responsive Probe.
///
/// Live-prints every variable redesign prompts care about: breakpoint,
/// orientation, raw size, safe-area insets, view-insets (keyboard),
/// textScaleFactor, brightness. Plus three textScale proof rows (1.0×/1.5×/2.0×)
/// so reviewers can confirm `BBCard` + `BBChip` + content survive large font.
///
/// Reach via `lib/responsive_probe_dev.dart`:
///   flutter run --target lib/responsive_probe_dev.dart -d chrome
///   flutter run --target lib/responsive_probe_dev.dart -d ios-simulator
///   flutter run --target lib/responsive_probe_dev.dart -d android-emulator
library;

import 'package:flutter/material.dart';

import '../widgets/bb_button.dart';
import '../widgets/bb_card.dart';
import '../widgets/bb_chip.dart';
import '../widgets/bb_input.dart';
import '../widgets/bb_status_badge.dart';
import 'responsive.dart';
import 'tokens.dart';

class BBResponsiveProbeScreen extends StatefulWidget {
  const BBResponsiveProbeScreen({super.key});

  @override
  State<BBResponsiveProbeScreen> createState() =>
      _BBResponsiveProbeScreenState();
}

class _BBResponsiveProbeScreenState extends State<BBResponsiveProbeScreen> {
  bool _darkPreview = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData base = _darkPreview ? ThemeData.dark() : ThemeData.light();
    return Theme(
      data: base,
      child: Builder(builder: _content),
    );
  }

  Widget _content(BuildContext context) {
    final BBResponsive r = BBResponsive.of(context);
    final BBColorSet c = BBColor.of(context);

    return BBScaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text('Responsive Probe — ${r.deviceClass.name}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_darkPreview ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle theme',
            onPressed: () => setState(() => _darkPreview = !_darkPreview),
          ),
          const SizedBox(width: BBSpace.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BBSpace.md),
        child: BBContentMaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SnapshotCard(r: r),
              const SizedBox(height: BBSpace.md),
              _BreakpointBoundaries(r: r),
              const SizedBox(height: BBSpace.md),
              _SafeAreaCard(r: r),
              const SizedBox(height: BBSpace.md),
              const _ResponsivePickerDemo(),
              const SizedBox(height: BBSpace.md),
              const _TextScaleProof(),
              const SizedBox(height: BBSpace.md),
              const _KeyboardInsetDemo(),
              const SizedBox(height: BBSpace.md),
              const _DiacriticsCheck(),
              const SizedBox(height: BBSpace.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.r});
  final BBResponsive r;

  Widget _row(BuildContext ctx, String k, String v) {
    final BBColorSet c = BBColor.of(ctx);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 180,
            child: Text(
              k,
              style: BBType.label(ctx).copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(child: Text(v, style: BBType.mono(ctx))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text('Live snapshot', style: BBType.h3(context)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _row(context, 'deviceClass', r.deviceClass.name),
          _row(
            context,
            'size',
            '${r.size.width.toStringAsFixed(0)} × ${r.size.height.toStringAsFixed(0)}',
          ),
          _row(context, 'orientation', r.orientation.name),
          _row(context, 'isLandscape', '${r.isLandscape}'),
          _row(context, 'isTabletOrLarger', '${r.isTabletOrLarger}'),
          _row(context, 'isDesktopOrLarger', '${r.isDesktopOrLarger}'),
          _row(
            context,
            'textScaleFactor',
            r.textScaleFactor.toStringAsFixed(2),
          ),
          _row(
            context,
            'padding (safe-area)',
            'L${r.padding.left.toStringAsFixed(0)} T${r.padding.top.toStringAsFixed(0)} R${r.padding.right.toStringAsFixed(0)} B${r.padding.bottom.toStringAsFixed(0)}',
          ),
          _row(
            context,
            'viewInsets (keyboard)',
            'L${r.viewInsets.left.toStringAsFixed(0)} T${r.viewInsets.top.toStringAsFixed(0)} R${r.viewInsets.right.toStringAsFixed(0)} B${r.viewInsets.bottom.toStringAsFixed(0)}',
          ),
          _row(context, 'isKeyboardVisible', '${r.isKeyboardVisible}'),
        ],
      ),
    );
  }
}

// ============================================================================

class _BreakpointBoundaries extends StatelessWidget {
  const _BreakpointBoundaries({required this.r});
  final BBResponsive r;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    Widget pill(String label, bool active) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.sm,
        vertical: BBSpace.xs,
      ),
      decoration: BoxDecoration(
        color: active ? c.primary : c.surfaceVariant,
        borderRadius: BBRadius.fullAll,
      ),
      child: Text(
        label,
        style: BBType.caption(context).copyWith(
          color: active ? Colors.white : c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return BBCard(
      header: Text('Breakpoint boundaries', style: BBType.h3(context)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: BBSpace.xs,
            runSpacing: BBSpace.xs,
            children: <Widget>[
              pill('mobile <600', r.isMobile),
              pill('tablet 600-1023', r.isTablet),
              pill('desktop 1024-1439', r.isDesktop),
              pill('wide ≥1440', r.isWide),
            ],
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            'Resize the window / rotate the device — the active pill switches in real time.',
            style: BBType.caption(context),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

class _SafeAreaCard extends StatelessWidget {
  const _SafeAreaCard({required this.r});
  final BBResponsive r;

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text('Safe-area + display cutouts', style: BBType.h3(context)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Expected non-zero values on iOS notched devices (status bar + bottom indicator), '
            'Android devices with punch-hole or gesture nav, and any device in landscape with cutouts.',
            style: BBType.body(context),
          ),
          const SizedBox(height: BBSpace.sm),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: BBColor.of(context).surfaceVariant,
              borderRadius: BBRadius.smAll,
            ),
            alignment: Alignment.center,
            child: Text(
              'top ${r.padding.top.toStringAsFixed(0)}  '
              'bottom ${r.padding.bottom.toStringAsFixed(0)}  '
              'left ${r.padding.left.toStringAsFixed(0)}  '
              'right ${r.padding.right.toStringAsFixed(0)}',
              style: BBType.mono(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

class _ResponsivePickerDemo extends StatelessWidget {
  const _ResponsivePickerDemo();

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text(
        'BBResponsiveBuilder — pick widget per tier',
        style: BBType.h3(context),
      ),
      body: BBResponsiveBuilder(
        mobile: _Slot(
          label: 'mobile slot',
          color: Colors.red.withValues(alpha: 0.15),
        ),
        tablet: _Slot(
          label: 'tablet slot',
          color: Colors.orange.withValues(alpha: 0.15),
        ),
        desktop: _Slot(
          label: 'desktop slot',
          color: Colors.green.withValues(alpha: 0.15),
        ),
        wide: _Slot(
          label: 'wide slot',
          color: Colors.blue.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BBRadius.smAll,
        border: Border.all(color: BBColor.of(context).border),
      ),
      alignment: Alignment.center,
      child: Text(label, style: BBType.h3(context)),
    );
  }
}

// ============================================================================

class _TextScaleProof extends StatelessWidget {
  const _TextScaleProof();

  Widget _row(BuildContext context, double scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'textScale ${scale.toStringAsFixed(1)}× — Žučljive čvrste šljive ŠČĆĐŽ',
              style: BBType.body(context),
            ),
            const SizedBox(height: BBSpace.xs),
            Wrap(
              spacing: BBSpace.xs,
              runSpacing: BBSpace.xs,
              children: <Widget>[
                BBChip(label: 'Sve', count: 7, onTap: () {}),
                BBChip(label: 'Aktivne', count: 3, onTap: () {}),
                BBChip(label: 'Završene', count: 2, onTap: () {}),
                BBChip(label: 'Otkazane', count: 1, onTap: () {}),
              ],
            ),
            const SizedBox(height: BBSpace.xs),
            BBCard(
              body: Row(
                children: <Widget>[
                  const BBStatusBadge(status: BBStatus.confirmed),
                  const SizedBox(width: BBSpace.xs),
                  Expanded(
                    child: Text(
                      'Ana Marković · 5 noći · 1 200 €',
                      style: BBType.bodyNum(context),
                    ),
                  ),
                  BBButton(
                    label: 'OK',
                    onPressed: () {},
                    size: BBButtonSize.sm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text(
        'Text scale resilience (1.0× / 1.5× / 2.0×)',
        style: BBType.h3(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Each row simulates a different system font scale. No clipping, '
            'no overflow, chips wrap to new line — that is the audit/63 F-63-04 contract.',
            style: BBType.caption(context),
          ),
          _row(context, 1.0),
          _row(context, 1.5),
          _row(context, 2.0),
        ],
      ),
    );
  }
}

// ============================================================================

class _KeyboardInsetDemo extends StatelessWidget {
  const _KeyboardInsetDemo();

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text('Keyboard inset behaviour', style: BBType.h3(context)),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BBInput(
            label: 'Tap here on a mobile device',
            hintText: 'Type to open keyboard',
          ),
          SizedBox(height: BBSpace.xs),
          Text(
            'When the keyboard appears, `BBScaffold.resizeToAvoidBottomInset` should '
            'shrink the body so this Card stays visible. The live snapshot above shows '
            'viewInsets.bottom updating in real time.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================

class _DiacriticsCheck extends StatelessWidget {
  const _DiacriticsCheck();

  @override
  Widget build(BuildContext context) {
    return BBCard(
      header: Text('Inter + Croatian diacritics', style: BBType.h3(context)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('č ć ž š đ — Č Ć Ž Š Đ', style: BBType.display(context)),
          const SizedBox(height: BBSpace.xs),
          Text(
            'Žučljive čvrste šljive · Šećerna mliječ · Đurđevdan',
            style: BBType.bodyLg(context),
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            'Body 14/400 sans-serif (Inter post-#545). If anything renders as serif '
            '(Playfair) or mojibake (??č), the font-asset wiring regressed.',
            style: BBType.caption(context),
          ),
        ],
      ),
    );
  }
}
