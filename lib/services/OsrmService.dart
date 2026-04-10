import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  static const String _baseUrl = 'http://router.project-osrm.org';

  // Get route between 2 points → returns list of LatLng
  static Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    try {
      final url = '$_baseUrl/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return [from, to];

      final data   = jsonDecode(res.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;

      return coords.map((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      )).toList();
    } catch (e) {
      return [from, to];
    }
  }

  // Get distance (km) and duration (min) between 2 points
  static Future<Map<String, double>> getDistanceAndDuration(
      LatLng from, LatLng to) async {
    try {
      final url = '$_baseUrl/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=false';

      final res   = await http.get(Uri.parse(url));
      final data  = jsonDecode(res.body);
      final route = data['routes'][0];

      return {
        'distance': (route['distance'] as num).toDouble() / 1000,
        'duration': (route['duration'] as num).toDouble() / 60,
      };
    } catch (e) {
      return {'distance': 0.0, 'duration': 0.0};
    }
  }

  // ✅ NEW: Returns route points AND real distance + duration in one single call
  static Future<Map<String, dynamic>> getRouteWithMetrics(
      LatLng from,
      LatLng to,
      ) async {
    try {
      final url = '$_baseUrl/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return {
          'points':      [from, to],
          'distanceKm':  null,
          'durationMin': null,
        };
      }

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        return {
          'points':      [from, to],
          'distanceKm':  null,
          'durationMin': null,
        };
      }

      final route  = routes[0] as Map<String, dynamic>;
      final coords = (route['geometry']?['coordinates'] as List?) ?? [];

      final points = coords
          .map((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      ))
          .toList();

      final distanceKm = route['distance'] != null
          ? (route['distance'] as num).toDouble() / 1000.0
          : null;

      final durationMin = route['duration'] != null
          ? (route['duration'] as num).toDouble() / 60.0
          : null;

      return {
        'points':      points.isNotEmpty ? points : [from, to],
        'distanceKm':  distanceKm,   // double? — kilometers
        'durationMin': durationMin,  // double? — minutes
      };
    } catch (e) {
      // Fallback: straight line, no metrics
      return {
        'points':      [from, to],
        'distanceKm':  null,
        'durationMin': null,
      };
    }
  }

  // Get route for multiple stops (VRP use case)
  static Future<List<LatLng>> getMultiStopRoute(List<LatLng> points) async {
    if (points.length < 2) return points;
    try {
      final coords = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = '$_baseUrl/route/v1/driving/$coords'
          '?overview=full&geometries=geojson';

      final res        = await http.get(Uri.parse(url));
      final data       = jsonDecode(res.body);
      final coordsList = data['routes'][0]['geometry']['coordinates'] as List;

      return coordsList.map((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      )).toList();
    } catch (e) {
      return points;
    }
  }
}