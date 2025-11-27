/// Widget utility classes.
///
/// This barrel file exports utility classes used throughout
/// the Widget feature for common operations.
///
/// ## Available Utils
///
/// - [DateNormalizer] - DateTime normalization and comparison utilities
/// - [DateKeyGenerator] - Consistent date key generation for map lookups
///
/// ## Usage
/// ```dart
/// import 'package:rab_booking/features/widget/utils/utils.dart';
///
/// final normalized = DateNormalizer.normalize(DateTime.now());
/// final key = DateKeyGenerator.fromDate(normalized);
/// ```
library;

export 'date_normalizer.dart';
export 'date_key_generator.dart';
