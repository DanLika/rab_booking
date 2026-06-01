/// Redesign primitive library — handoff `Bb*` widgets.
///
/// Single-import barrel for Phase 2 screen refactors:
/// ```dart
/// import 'package:bookbed/shared/widgets/redesign.dart';
/// ```
///
/// Existing legacy `BB*` widgets at `lib/core/widgets/bb_*.dart` are NOT
/// re-exported; they remain available via direct import for unmigrated
/// screens. Phase 2 PRs swap call-sites onto these redesign primitives.
library;

export 'redesign/bb_app_bar.dart';
export 'redesign/bb_avatar.dart';
export 'redesign/bb_avatar_slot.dart';
export 'redesign/bb_avatar_upload.dart';
export 'redesign/bb_bottom_sheet.dart';
export 'redesign/bb_button.dart';
export 'redesign/bb_card.dart';
export 'redesign/bb_checkbox.dart';
export 'redesign/bb_chip.dart';
export 'redesign/bb_dialog.dart';
export 'redesign/bb_dropdown.dart';
export 'redesign/bb_empty_state.dart';
export 'redesign/bb_icon.dart';
export 'redesign/bb_input.dart';
export 'redesign/bb_logo.dart';
export 'redesign/bb_radio.dart';
export 'redesign/bb_scaffold.dart';
export 'redesign/bb_section_header.dart';
export 'redesign/bb_sidebar.dart';
export 'redesign/bb_sidebar_rail.dart';
export 'redesign/bb_skeleton.dart';
export 'redesign/bb_sparkline.dart';
export 'redesign/bb_spinner.dart';
export 'redesign/bb_status_badge.dart';
export 'redesign/bb_switch.dart';
