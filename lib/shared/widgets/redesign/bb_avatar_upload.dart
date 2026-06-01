import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import '../../../core/services/logging_service.dart';
import 'bb_avatar.dart';
import 'bb_icon.dart';
import 'bb_spinner.dart';

/// Callback type emitted by [BbAvatarUpload] when the user picks an image.
///
/// Mirrors the existing `ProfileImagePicker.onImageSelected` signature so
/// Edit Profile + Register migrations are mechanical drop-ins:
///
/// ```dart
/// onImageSelected: (bytes, name) {
///   setState(() {
///     _profileImageBytes = bytes;
///     _profileImageName = name;
///   });
/// }
/// ```
///
/// `bytes` is the picked image bytes (already capped at 512×512, JPEG q=85
/// to match `ProfileImagePicker`); `name` is the source filename. Both are
/// nullable to leave room for a future "clear avatar" affordance.
typedef BbAvatarUploadCallback = void Function(Uint8List? bytes, String? name);

/// Avatar slot with built-in image-picker affordance — Phase 1.4 primitive.
///
/// Mirrors the gallery-pick logic from
/// `lib/features/auth/presentation/widgets/profile_image_picker.dart` (the
/// `image_picker` plugin invocation + 512×512 + q=85 + error/log path stay
/// identical, only the chrome is redesigned). Existing `ProfileImagePicker`
/// is preserved for unmigrated call sites; Edit Profile R2C + Register
/// cleanup will swap onto this primitive in follow-up PRs.
///
/// Visual contract:
/// - Circular surface matching [BbAvatar] (ring + tone palette via
///   [BBColor.of] + [BbRedesignTokens.of]).
/// - Edit affordance: ~32×32 circular overlay button (bottom-right) with
///   camera/edit icon on filled `c.primary`. Tappable when not uploading.
/// - Placeholder: when [imageUrl] is null and no pick has happened yet,
///   shows [initials] (uppercased) or `person` icon fallback.
/// - Loading: when [isUploading] is true OR the picker is reading bytes,
///   shows a circular [BbSpinner] overlay and disables tap.
///
/// State boundary:
/// - Internal `_isPicking` covers the ~100ms `ImagePicker.pickImage` →
///   `readAsBytes` window (no caller knowledge needed).
/// - Caller-controlled [isUploading] covers the seconds-long backend upload
///   (Firebase Storage etc.). Either state shows the same spinner.
///
/// Reduced-motion-friendly via [BBMotion.adapt] on the overlay crossfade.
class BbAvatarUpload extends StatefulWidget {
  const BbAvatarUpload({
    super.key,
    required this.onImageSelected,
    this.imageUrl,
    this.initials,
    this.size = BbAvatarSize.lg,
    this.isUploading = false,
    this.ring = true,
    this.semanticLabel,
  });

  /// Current avatar URL (rendered when no fresh pick exists). Null/empty
  /// → placeholder.
  final String? imageUrl;

  /// Fired when the user picks an image and bytes have been read. See
  /// [BbAvatarUploadCallback] for the API shape rationale.
  final BbAvatarUploadCallback onImageSelected;

  /// Initials shown when no image is available. 1-2 chars recommended;
  /// rendered uppercased. Null → `person` icon fallback.
  final String? initials;

  /// One of the standard [BbAvatarSize] presets (xs/sm/md/lg/xl).
  /// Defaults to `lg` (56px) — Edit Profile hero context.
  final BbAvatarSize size;

  /// Caller-controlled "backend upload in progress" flag. Shows the
  /// spinner overlay and disables tap. Independent from the internal
  /// pick state (which also shows the spinner during plugin invocation).
  final bool isUploading;

  /// Render a subtle white ring around the avatar (default `true` to make
  /// the upload affordance visually obvious).
  final bool ring;

  /// Accessibility label override for the entire tap target. Defaults to
  /// "Change profile photo".
  final String? semanticLabel;

  @override
  State<BbAvatarUpload> createState() => _BbAvatarUploadState();
}

class _BbAvatarUploadState extends State<BbAvatarUpload> {
  Uint8List? _pickedBytes;
  bool _isPicking = false;

  bool get _busy => _isPicking || widget.isUploading;

  double get _diameter {
    switch (widget.size) {
      case BbAvatarSize.xs:
        return 28;
      case BbAvatarSize.sm:
        return 36;
      case BbAvatarSize.md:
        return 44;
      case BbAvatarSize.lg:
        return 56;
      case BbAvatarSize.xl:
        return 80;
    }
  }

  /// Edit-button diameter scaled by avatar size; capped to a sane touch
  /// target on small avatars (handoff spec puts it at ~32 on lg/xl).
  double get _editButtonDiameter {
    final double d = _diameter;
    if (d <= 36) return 20;
    if (d <= 44) return 24;
    if (d <= 56) return 28;
    return 32;
  }

  double get _editIconSize => _editButtonDiameter * 0.55;

  // Mirrors `ProfileImagePicker._pickImage` 1-to-1 — gallery source,
  // 512×512 cap, JPEG q=85, same error/log path. WRAP-vs-rewrite finding
  // documented in audit/103 §3 and PR body.
  Future<void> _pickImage() async {
    if (_busy) return;
    setState(() => _isPicking = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedBytes = bytes;
          _isPicking = false;
        });
        widget.onImageSelected(bytes, image.name);
      } else {
        if (!mounted) return;
        setState(() => _isPicking = false);
      }
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'BbAvatarUpload: Failed to pick image',
        e,
        stackTrace,
      );
      if (!mounted) return;
      setState(() => _isPicking = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: ${e.toString().split(':').last.trim()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImage(BBColorSet c) {
    final double d = _diameter;

    // Fresh pick wins over imageUrl.
    if (_pickedBytes != null) {
      return ClipOval(
        child: Image.memory(
          _pickedBytes!,
          width: d,
          height: d,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: d,
          height: d,
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPlaceholder(c),
            loadingBuilder: (_, Widget child, ImageChunkEvent? p) =>
                p == null ? child : _buildPlaceholder(c),
          ),
        ),
      );
    }

    return _buildPlaceholder(c);
  }

  Widget _buildPlaceholder(BBColorSet c) {
    final double d = _diameter;
    final String? raw = widget.initials?.trim();
    final bool hasInitials = raw != null && raw.isNotEmpty;

    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: hasInitials
          ? Text(
              raw.toUpperCase(),
              style: TextStyle(
                color: c.primary,
                fontWeight: FontWeight.w600,
                fontSize: d * 0.4,
                height: 1,
              ),
            )
          : BbIcon(name: 'person', size: d * 0.5, color: c.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final double d = _diameter;
    final double editD = _editButtonDiameter;

    final Widget core = _buildImage(c);

    final Widget ringWrap = widget.ring
        ? Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Color(0x33FFFFFF), spreadRadius: 3),
              ],
            ),
            child: core,
          )
        : core;

    final Widget overlay = AnimatedSwitcher(
      duration: BBMotion.adapt(context, BBMotion.fast),
      child: _busy
          ? Container(
              key: const ValueKey<String>('bb-avatar-upload-busy'),
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: BbSpinner(size: d * 0.32, color: Colors.white),
            )
          : const SizedBox.shrink(
              key: ValueKey<String>('bb-avatar-upload-idle'),
            ),
    );

    final bool hasContent =
        _pickedBytes != null ||
        (widget.imageUrl != null && widget.imageUrl!.isNotEmpty);

    final Widget editButton = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _pickImage,
        customBorder: const CircleBorder(),
        child: Container(
          width: editD,
          height: editD,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.primary,
            border: Border.all(color: c.surface, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: c.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: BbIcon(
            name: hasContent ? 'edit' : 'add_a_photo',
            size: _editIconSize,
            color: c.surface,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !_busy,
      label: widget.semanticLabel ?? 'Change profile photo',
      child: SizedBox(
        // Stack overflows the avatar disc by ~25% bottom-right for the
        // edit pill; reserve space so callers' layouts don't jump.
        width: d + editD * 0.5,
        height: d + editD * 0.5,
        child: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            // Whole-disc tap target — tapping the avatar itself fires the
            // picker (parity with `ProfileImagePicker` hover affordance).
            Positioned(
              left: 0,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _busy ? null : _pickImage,
                child: SizedBox(
                  width: d,
                  height: d,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[ringWrap, overlay],
                  ),
                ),
              ),
            ),
            Positioned(right: 0, bottom: 0, child: editButton),
          ],
        ),
      ),
    );
  }
}
