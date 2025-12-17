import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logging_service.dart';

/// IP Geolocation result
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

  factory GeoLocationResult.fromJson(Map<String, dynamic> json) {
    return GeoLocationResult(
      ipAddress: json['ip'] ?? json['query'] ?? '',
      country: json['country'] ?? json['country_name'],
      city: json['city'],
      region: json['region'] ?? json['regionName'],
      latitude: json['latitude']?.toDouble() ?? json['lat']?.toDouble(),
      longitude: json['longitude']?.toDouble() ?? json['lon']?.toDouble(),
    );
  }
}

/// Free IP Geolocation Service.
///
/// Uses multiple free APIs as fallbacks:
/// 1. ipapi.co (150 requests/day, no key required)
/// 2. ip-api.com (45 requests/minute, no key required)
/// 3. ipwhois.app (10000 requests/month, no key required)
///
/// Usage:
/// ```dart
/// final service = IpGeolocationService();
///
/// // Get current location (auto-detect IP)
/// final location = await service.getCurrentLocation();
/// print(location?.locationString); // "Zagreb, Croatia"
///
/// // Get location for specific IP
/// final result = await service.getGeolocation('8.8.8.8');
/// ```
class IpGeolocationService {
  final http.Client _client;

  IpGeolocationService({http.Client? client})
      : _client = client ?? http.Client();

  /// Get geolocation for current IP (automatic detection)
  Future<GeoLocationResult?> getCurrentLocation() async {
    return await getGeolocation(null);
  }

  /// Get geolocation for specific IP address
  Future<GeoLocationResult?> getGeolocation(String? ipAddress) async {
    // Try multiple providers in sequence
    final providers = [
      () => _tryIpApiCo(ipAddress),
      () => _tryIpApiCom(ipAddress),
      () => _tryIpWhoisApp(ipAddress),
    ];

    for (final provider in providers) {
      try {
        final result = await provider();
        if (result != null) return result;
      } catch (e) {
        // Continue to next provider
        unawaited(LoggingService.logError('Geolocation provider failed', e));
      }
    }

    return null; // All providers failed
  }

  /// Try ipapi.co (150 requests/day)
  Future<GeoLocationResult?> _tryIpApiCo(String? ipAddress) async {
    final url = ipAddress != null && ipAddress.isNotEmpty
        ? 'https://ipapi.co/$ipAddress/json/'
        : 'https://ipapi.co/json/';

    // PERFORMANCE: 1s timeout per provider (total 3s for all providers)
    final response = await _client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 1),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for error
      if (json.containsKey('error') && json['error'] == true) {
        return null;
      }

      return GeoLocationResult(
        ipAddress: json['ip'] ?? '',
        country: json['country_name'],
        city: json['city'],
        region: json['region'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );
    }

    return null;
  }

  /// Try ip-api.com (45 requests/minute)
  Future<GeoLocationResult?> _tryIpApiCom(String? ipAddress) async {
    final url = ipAddress != null && ipAddress.isNotEmpty
        ? 'http://ip-api.com/json/$ipAddress'
        : 'http://ip-api.com/json/';

    // PERFORMANCE: 1s timeout per provider (total 3s for all providers)
    final response = await _client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 1),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check status
      if (json['status'] != 'success') {
        return null;
      }

      return GeoLocationResult(
        ipAddress: json['query'] ?? '',
        country: json['country'],
        city: json['city'],
        region: json['regionName'],
        latitude: json['lat']?.toDouble(),
        longitude: json['lon']?.toDouble(),
      );
    }

    return null;
  }

  /// Try ipwhois.app (10000 requests/month)
  Future<GeoLocationResult?> _tryIpWhoisApp(String? ipAddress) async {
    final url = ipAddress != null && ipAddress.isNotEmpty
        ? 'https://ipwhois.app/json/$ipAddress'
        : 'https://ipwhois.app/json/';

    // PERFORMANCE: 1s timeout per provider (total 3s for all providers)
    final response = await _client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 1),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for success
      if (json['success'] == false) {
        return null;
      }

      return GeoLocationResult(
        ipAddress: json['ip'] ?? '',
        country: json['country'],
        city: json['city'],
        region: json['region'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
