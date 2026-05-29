import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'logging_service.dart';

/// IP Geolocation result.
///
/// `ipAddress` is intentionally left empty — `getClientGeolocation` CF never
/// returns the IP to the client (privacy by design — the IP only lives
/// server-side for the lookup).
class GeoLocationResult {
  final String ipAddress;
  final String? country;
  final String? city;
  final String? region;
  final double? latitude;
  final double? longitude;

  GeoLocationResult({
    required this.ipAddress,
    this.country,
    this.city,
    this.region,
    this.latitude,
    this.longitude,
  });

  String get locationString {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isEmpty ? 'Unknown Location' : parts.join(', ');
  }
}

/// Server-side IP Geolocation (F-58c-13 closure).
///
/// Pre-fix this class called `ipapi.co` + `ipwhois.app` directly from the
/// browser on every login/signup, leaking the client IP and approximate
/// location to two third parties before the dashboard even rendered.
///
/// Now: calls `getClientGeolocation` callable in `europe-west1`. The CF reads
/// the verified `x-forwarded-for` / `rawRequest.ip`, proxies to a single
/// upstream (ipapi.co), returns only `{country, region, city}`. The IP itself
/// never enters the client.
///
/// Failure (network blip, CF cold-start past timeout, upstream 503) degrades
/// to `null` — callers in `enhanced_auth_provider.dart` already treat that as
/// "location unknown" and continue.
class IpGeolocationService {
  final FirebaseFunctions _functions;

  IpGeolocationService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<GeoLocationResult?> getCurrentLocation() async {
    try {
      final callable = _functions.httpsCallable(
        'getClientGeolocation',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 5)),
      );
      final response = await callable.call<Map<Object?, Object?>>();
      final raw = response.data;
      final country = (raw['country'] as String?) ?? '';
      final region = (raw['region'] as String?) ?? '';
      final city = (raw['city'] as String?) ?? '';
      if (country.isEmpty && region.isEmpty && city.isEmpty) return null;
      return GeoLocationResult(
        ipAddress: '',
        country: country.isEmpty ? null : country,
        region: region.isEmpty ? null : region,
        city: city.isEmpty ? null : city,
      );
    } catch (e) {
      unawaited(LoggingService.logError('getClientGeolocation CF failed', e));
      return null;
    }
  }

  /// API-surface compat shim: geolocation by arbitrary IP is no longer
  /// supported client-side (server uses the request's verified IP).
  Future<GeoLocationResult?> getGeolocation(String? ipAddress) async {
    return getCurrentLocation();
  }

  void dispose() {}
}
