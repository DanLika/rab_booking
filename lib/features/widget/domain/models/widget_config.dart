/// @deprecated This file is deprecated. Use [embed_url_params.dart] instead.
///
/// This file exists only for backward compatibility.
/// All code should migrate to use [EmbedUrlParams] directly.
///
/// ## Migration Guide
/// Replace:
/// ```dart
/// import '.../widget_config.dart';
/// final config = WidgetConfig.fromUrlParameters(uri);
/// ```
///
/// With:
/// ```dart
/// import '.../embed_url_params.dart';
/// final params = EmbedUrlParams.fromUrlParameters(uri);
/// ```
library;

export 'embed_url_params.dart';
