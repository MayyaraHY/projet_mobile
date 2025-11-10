import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class GeolocationService {
  // Using ip-api.com - Free tier: 45 requests/minute, no API key needed
  static const String _baseUrl = 'http://ip-api.com/json';

  Future<LocationInfo?> getCurrentLocation() async {
    try {
      print('Fetching geolocation from ip-api.com...');
      final response = await http.get(
        Uri.parse(_baseUrl),
      );

      print('Geolocation response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Geolocation data: $data');
        return LocationInfo.fromJson(data);
      }
      print('Geolocation failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Geolocation error: $e');
      return null;
    }
  }

  Future<LocationInfo?> getLocationByIP(String ip) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$ip'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LocationInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Geolocation error: $e');
      return null;
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class LocationInfo {
  final String ip;
  final String? city;
  final String? region;
  final String? country;
  final String? countryName;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? postal;
  final String? org; // ISP/Organization

  LocationInfo({
    required this.ip,
    this.city,
    this.region,
    this.country,
    this.countryName,
    this.latitude,
    this.longitude,
    this.timezone,
    this.postal,
    this.org,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      ip: json['query'] as String? ?? '', // ip-api uses 'query' instead of 'ip'
      city: json['city'] as String?,
      region: json['regionName'] as String?, // ip-api uses 'regionName'
      country: json['countryCode'] as String?, // ip-api uses 'countryCode'
      countryName: json['country'] as String?,
      latitude: (json['lat'] as num?)?.toDouble(), // ip-api uses 'lat'
      longitude: (json['lon'] as num?)?.toDouble(), // ip-api uses 'lon'
      timezone: json['timezone'] as String?,
      postal: json['zip'] as String?, // ip-api uses 'zip'
      org: json['isp'] as String?, // ip-api uses 'isp'
    );
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'city': city,
        'region': region,
        'country': country,
        'country_name': countryName,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'postal': postal,
        'org': org,
      };

  String get locationDisplay {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (region != null) parts.add(region!);
    if (countryName != null) parts.add(countryName!);
    return parts.join(', ');
  }

  String get shortLocation {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
