import 'dart:async';
import 'dart:math' as dartMath;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'orders_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../services/osrmservice.dart';

class ProviderHomeScreen extends StatefulWidget {
  final bool    isGerant;
  final bool    startOnline;
  final String? activeCommandeId;
  final double? destinationLat;
  final double? destinationLon;
  final List<Map<String, dynamic>> testOrders; // ← NEW

  const ProviderHomeScreen({
    super.key,
    this.isGerant        = false,
    this.startOnline     = false,
    this.activeCommandeId,
    this.destinationLat,
    this.destinationLon,
    this.testOrders      = const [], // ← NEW (default empty)
  });

  @override
  State<ProviderHomeScreen> createState() => ProviderHomeScreenState();
}

class ProviderHomeScreenState extends State<ProviderHomeScreen> {
  final MapController         _mapController      = MapController();
  final TextEditingController _capacityController = TextEditingController();

  bool isOnline     = false;
  int  currentIndex = 0;

  LatLng _currentPosition = const LatLng(36.76639, 3.47717);
  bool   _gpsReady        = false;

  double _capacityLiters  = 0;
  bool   _loadingCapacity = true;

  // Map display
  List<Polyline> _polylines     = [];
  List<Marker>   _markers       = [];
  bool           _loadingRoutes = false;

  // Optimized route info shown in bottom sheet
  List<_RouteStop> _optimizedStops = [];
  double?          _totalDistanceKm;
  bool             _routeIsValid   = false;

  // ← NEW: local test orders (set from goToMapWithRoute or widget param)
  List<Map<String, dynamic>> _testOrders = [];

  StreamSubscription<Position>? _gpsSub;
  Timer?                        _gpsUploadTimer;

  @override
  void initState() {
    super.initState();
    // Initialise from widget param if provided (Navigator.pushAndRemoveUntil path)
    if (widget.testOrders.isNotEmpty) {
      _testOrders = List<Map<String, dynamic>>.from(widget.testOrders);
    }
    _loadCapacity();
    _startGps();
    if (widget.startOnline) _waitForGpsAndGoOnline();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _gpsUploadTimer?.cancel();
    _capacityController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC — called by OrdersScreen after accepting a commande
  // ─────────────────────────────────────────────────────────
  void goToMapWithRoute({
    required String  commandeId,
    required double? destLat,
    required double? destLon,
    List<Map<String, dynamic>>? testOrders, // ← NEW
  }) {
    setState(() {
      currentIndex = 0;
      if (testOrders != null && testOrders.isNotEmpty) {
        _testOrders = List<Map<String, dynamic>>.from(testOrders);
      }
    });
    if (!isOnline) {
      setState(() => isOnline = true);
      ApiService.updatePosition(
        lat: _currentPosition.latitude,
        lon: _currentPosition.longitude,
      );
    }
    _loadOptimizedRoutes();
  }

  // ─────────────────────────────────────────────────────────
  // GPS
  // ─────────────────────────────────────────────────────────

  Future<void> _waitForGpsAndGoOnline() async {
    _showSnack('Initialisation du GPS...', Colors.blue);
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_gpsReady) break;
    }
    if (!mounted) return;
    if (_gpsReady) {
      setState(() => isOnline = true);
      await ApiService.updatePosition(
        lat: _currentPosition.latitude,
        lon: _currentPosition.longitude,
      );
      _showSnack('Vous êtes maintenant EN LIGNE ✓', Colors.green);
      await _loadOptimizedRoutes();
    } else {
      _showSnack('GPS non disponible', Colors.orange);
    }
  }

  Future<void> _startGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _updatePosition(pos.latitude, pos.longitude);

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy:       LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) => _updatePosition(pos.latitude, pos.longitude));

      _gpsUploadTimer = Timer.periodic(
        const Duration(seconds: 30),
            (_) { if (isOnline) _uploadGps(); },
      );
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  void _updatePosition(double lat, double lon) {
    setState(() {
      _currentPosition = LatLng(lat, lon);
      _gpsReady        = true;
    });
    if (isOnline) _mapController.move(_currentPosition, 13.0);
  }

  Future<void> _uploadGps() async {
    await ApiService.updatePosition(
      lat: _currentPosition.latitude,
      lon: _currentPosition.longitude,
    );
  }

  void _toggleOnlineStatus() async {
    final newStatus = !isOnline;
    setState(() => isOnline = newStatus);

    if (newStatus) {
      if (!_gpsReady) {
        _showSnack('Obtention du GPS...', Colors.blue);
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_gpsReady) break;
        }
      }
      await ApiService.updatePosition(
        lat: _currentPosition.latitude,
        lon: _currentPosition.longitude,
      );
      _showSnack('Vous êtes maintenant EN LIGNE ✓', Colors.green);
      await _loadOptimizedRoutes();
    } else {
      await ApiService.setOffline();
      setState(() {
        _polylines        = [];
        _markers          = [];
        _optimizedStops   = [];
        _totalDistanceKm  = null;
        _testOrders       = []; // ← clear test orders on go-offline
      });
      _showSnack('Vous êtes maintenant HORS LIGNE', Colors.grey);
    }
  }

  // ─────────────────────────────────────────────────────────
  // CORE: decide whether to use test data or real API
  // ─────────────────────────────────────────────────────────
  Future<void> _loadOptimizedRoutes() async {
    // ── TEST MODE: bypass API entirely ───────────────────────
    if (_testOrders.isNotEmpty) {
      await _buildRouteFromTestOrders();
      return;
    }
    // ── REAL MODE ────────────────────────────────────────────
    await _loadOptimizedRoutesFromApi();
  }

  // ─────────────────────────────────────────────────────────
  // Nearest-neighbour greedy sort
  // Mirrors Python generate_solution() + cheapest-insertion idea:
  // at each step pick the unvisited order closest to current position.
  // ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _nearestNeighbourSort(
      LatLng startPosition,
      List<Map<String, dynamic>> orders,
      ) {
    if (orders.isEmpty) return [];

    final unvisited = List<Map<String, dynamic>>.from(orders);
    final sorted    = <Map<String, dynamic>>[];
    double curLat   = startPosition.latitude;
    double curLon   = startPosition.longitude;

    while (unvisited.isNotEmpty) {
      // Find nearest unvisited order from current position
      int    bestIdx  = 0;
      double bestDist = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final lat = (unvisited[i]['lat'] as num?)?.toDouble();
        final lon = (unvisited[i]['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        // straight-line haversine to decide order (OSRM used later for display)
        final d = _haversineKmStatic(curLat, curLon, lat, lon);
        if (d < bestDist) {
          bestDist = d;
          bestIdx  = i;
        }
      }

      final chosen = unvisited.removeAt(bestIdx);
      sorted.add(chosen);
      curLat = (chosen['lat'] as num?)?.toDouble() ?? curLat;
      curLon = (chosen['lon'] as num?)?.toDouble() ?? curLon;
    }

    return sorted;
  }

  static double _haversineKmStatic(
      double lat1, double lon1, double lat2, double lon2) {
    const r    = 6371.0;
    const pi   = 3.141592653589793;
    final dlat = (lat2 - lat1) * pi / 180.0;
    final dlon = (lon2 - lon1) * pi / 180.0;
    final sinD = _dartSin(dlat / 2);
    final sinL = _dartSin(dlon / 2);
    final a = sinD * sinD +
        _dartCos(lat1 * pi / 180.0) * _dartCos(lat2 * pi / 180.0) * sinL * sinL;
    return r * 2 * _dartAsin(_dartSqrt(a < 0 ? 0 : a));
  }

  // dart:math delegates (dart:math is already imported via flutter_map transitively;
  // add `import 'dart:math' as dartMath;` at the top of the file if not present)
  static double _dartSin(double x)  => dartMath.sin(x);
  static double _dartCos(double x)  => dartMath.cos(x);
  static double _dartAsin(double x) => dartMath.asin(x);
  static double _dartSqrt(double x) => dartMath.sqrt(x);

  // ─────────────────────────────────────────────────────────
  // TEST MODE: build route using nearest-neighbour order
  // ─────────────────────────────────────────────────────────
  Future<void> _buildRouteFromTestOrders() async {
    setState(() => _loadingRoutes = true);
    try {
      // Only accepted orders contribute to the route
      final acceptedOrders = _testOrders
          .where((o) =>
      o['status'] == 'accepted' || o['status'] == 'en livraison')
          .toList();

      // Fallback: use all orders if none accepted yet (first tap scenario)
      final rawOrders =
      acceptedOrders.isNotEmpty ? acceptedOrders : _testOrders;

      // ── NEAREST-NEIGHBOUR SORT (mirrors Python generate_solution) ──
      // Greedy: always go to the closest unvisited order from current pos.
      // Example: driver at pos, order A=20km, order B=10km → visit B first.
      final ordersToRoute = _nearestNeighbourSort(_currentPosition, rawOrders);

      final List<LatLng>     waypoints = [_currentPosition];
      final List<_RouteStop> stops     = [];

      for (int i = 0; i < ordersToRoute.length; i++) {
        final o   = ordersToRoute[i];
        final lat = (o['lat'] as num?)?.toDouble();
        final lon = (o['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        waypoints.add(LatLng(lat, lon));
        stops.add(_RouteStop(
          index:      i + 1,
          mongoId:    o['id'].toString(),
          clientName: o['clientName'] ?? 'Client ${i + 1}',
          position:   LatLng(lat, lon),
          address:    o['address'] ?? '',
          quantity:   (o['quantity'] as num?)?.toDouble() ?? 0,
        ));
      }

      // ── OSRM segments for real road distances & polyline ──────────
      final List<LatLng> fullRoutePoints = [];
      double totalDist = 0;
      final List<double> legDist = [];
      final List<double> legDur  = [];

      for (int i = 0; i < waypoints.length - 1; i++) {
        final result = await OsrmService.getRouteWithMetrics(
            waypoints[i], waypoints[i + 1]);
        final pts = result['points'] as List<LatLng>;
        final d   = result['distanceKm']  as double? ?? 0;
        final dur = result['durationMin'] as double? ?? 0;

        if (fullRoutePoints.isNotEmpty && pts.isNotEmpty) {
          fullRoutePoints.addAll(pts.skip(1));
        } else {
          fullRoutePoints.addAll(pts);
        }
        totalDist += d;
        legDist.add(d);
        legDur.add(dur);
      }

      // Enrich stops with real per-leg road distance/duration from OSRM
      final List<_RouteStop> enrichedStops = List<_RouteStop>.from(stops);
      for (int i = 0; i < enrichedStops.length && i < legDist.length; i++) {
        enrichedStops[i] = enrichedStops[i].copyWith(
          distanceKm:  legDist[i],
          durationMin: legDur[i],
        );
      }

      // ── Markers ─────────────────────────────────────────────
      final List<Marker> newMarkers = [];

      // Driver marker
      newMarkers.add(Marker(
        point:  _currentPosition,
        width:  56,
        height: 56,
        child: GestureDetector(
          onTap: _showEditCapacityDialog,
          child: Container(
            decoration: BoxDecoration(
              color:  const Color(0xFF1E3A8A),
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.local_shipping,
                color: Colors.white, size: 28),
          ),
        ),
      ));

      // Stop markers
      final stopColors = [
        Colors.blue, Colors.green, Colors.purple,
        Colors.orange, Colors.teal, Colors.red,
      ];

      for (int i = 0; i < enrichedStops.length; i++) {
        final stop  = enrichedStops[i];
        final color = stopColors[i % stopColors.length];
        newMarkers.add(Marker(
          point:  stop.position,
          width:  72,
          height: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  stop.distanceKm != null
                      ? '${stop.index}. ${stop.distanceKm!.toStringAsFixed(1)} km\n'
                      '${stop.durationMin?.round()} min'
                      : '${stop.index}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   9,
                    fontWeight: FontWeight.bold,
                    height:     1.3,
                  ),
                ),
              ),
              Icon(Icons.location_on, color: color, size: 32),
            ],
          ),
        ));
      }

      // ── Polyline ─────────────────────────────────────────────
      final List<Polyline> newPolylines = [];
      if (fullRoutePoints.length > 1) {
        newPolylines.add(Polyline(
          points:            fullRoutePoints,
          color:             const Color(0xFF1565C0),
          strokeWidth:       5,
          borderStrokeWidth: 2,
          borderColor:       Colors.white,
        ));
      }

      if (!mounted) return;
      setState(() {
        _polylines        = newPolylines;
        _markers          = newMarkers;
        _optimizedStops   = enrichedStops;
        _totalDistanceKm  = totalDist;
        _routeIsValid     = true;
        _loadingRoutes    = false;
      });

      // Fit map to show all waypoints
      if (waypoints.length > 1) {
        final bounds = LatLngBounds.fromPoints(waypoints);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(
              padding: EdgeInsets.fromLTRB(40, 120, 40, 300)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRoutes = false);
      debugPrint('buildRouteFromTestOrders error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // REAL MODE: load VRP solution from API
  // ─────────────────────────────────────────────────────────
  Future<void> _loadOptimizedRoutesFromApi() async {
    setState(() => _loadingRoutes = true);

    try {
      // 1. Get all "en livraison" commandes
      final commandes = await ApiService.getCommandes(status: 'en livraison');

      if (commandes.isEmpty) {
        setState(() {
          _polylines       = [];
          _markers         = [];
          _optimizedStops  = [];
          _totalDistanceKm = null;
          _loadingRoutes   = false;
        });
        _mapController.move(_currentPosition, 13);
        return;
      }

      // Build lookup: mongoId → commande data
      final Map<String, Map<String, dynamic>> commandeById = {
        for (final c in commandes)
          (c['_id'] ?? c['id']).toString(): c,
      };

      // 2. Get VRP solution
      final vrpResult = await ApiService.getVrpSolution();

      // 3. Build ordered stop list
      List<String> orderedMongoIds = [];

      if (vrpResult['error'] == null && vrpResult['routes'] != null) {
        final routes = vrpResult['routes'] as List;
        _totalDistanceKm =
            (vrpResult['distance_totale_km'] as num?)?.toDouble();
        _routeIsValid = vrpResult['valide'] as bool? ?? false;

        final Map<String, String> vrpToMongo = {};
        for (final c in commandes) {
          final mongoId = (c['_id'] ?? c['id']).toString();
          final vrpId   = c['vrpId']?.toString();
          if (vrpId != null) vrpToMongo[vrpId] = mongoId;
        }

        for (final routeObj in routes) {
          final vrpIds = (routeObj['route'] as List?) ?? [];
          for (final vid in vrpIds) {
            final mongoId = vrpToMongo[vid.toString()];
            if (mongoId != null) orderedMongoIds.add(mongoId);
          }
        }
      }

      if (orderedMongoIds.isEmpty) {
        orderedMongoIds = commandeById.keys.toList();
        _totalDistanceKm = null;
        _routeIsValid    = false;
      }

      // 4. Build waypoints
      final List<LatLng>     waypoints = [_currentPosition];
      final List<_RouteStop> stops     = [];

      for (int i = 0; i < orderedMongoIds.length; i++) {
        final id  = orderedMongoIds[i];
        final cmd = commandeById[id];
        if (cmd == null) continue;

        final lat = (cmd['position']?['lat'] as num?)?.toDouble();
        final lon = (cmd['position']?['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        final clientName = (cmd['client'] is Map)
            ? '${cmd['client']['prenom'] ?? ''} ${cmd['client']['nom'] ?? ''}'
            .trim()
            : 'Client ${i + 1}';

        waypoints.add(LatLng(lat, lon));
        stops.add(_RouteStop(
          index:      i + 1,
          mongoId:    id,
          clientName: clientName.isEmpty ? 'Client ${i + 1}' : clientName,
          position:   LatLng(lat, lon),
          address:    cmd['adresse'] ?? '',
          quantity:   (cmd['capacite'] as num?)?.toDouble() ?? 0,
        ));
      }

      // 5. Draw multi-stop route via OSRM
      final List<LatLng> fullRoutePoints = [];
      double segmentDistKm = 0;
      double segmentDurMin = 0;

      final List<double> legDistances = [];
      final List<double> legDurations = [];

      for (int i = 0; i < waypoints.length - 1; i++) {
        final result = await OsrmService.getRouteWithMetrics(
            waypoints[i], waypoints[i + 1]);
        final pts = result['points'] as List<LatLng>;
        final d   = result['distanceKm']  as double? ?? 0;
        final dur = result['durationMin'] as double? ?? 0;

        if (fullRoutePoints.isNotEmpty && pts.isNotEmpty) {
          fullRoutePoints.addAll(pts.skip(1));
        } else {
          fullRoutePoints.addAll(pts);
        }

        segmentDistKm += d;
        segmentDurMin += dur;
        legDistances.add(d);
        legDurations.add(dur);
      }

      for (int i = 0; i < stops.length && i < legDistances.length; i++) {
        stops[i] = stops[i].copyWith(
          distanceKm:  legDistances[i],
          durationMin: legDurations[i],
        );
      }

      // 6. Build markers
      final List<Marker> newMarkers = [];

      newMarkers.add(Marker(
        point:  _currentPosition,
        width:  56,
        height: 56,
        child: GestureDetector(
          onTap: _showEditCapacityDialog,
          child: Container(
            decoration: BoxDecoration(
              color:  const Color(0xFF1E3A8A),
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.local_shipping,
                color: Colors.white, size: 28),
          ),
        ),
      ));

      final stopColors = [
        Colors.blue, Colors.green, Colors.purple,
        Colors.orange, Colors.teal, Colors.red,
      ];

      for (int i = 0; i < stops.length; i++) {
        final stop  = stops[i];
        final color = stopColors[i % stopColors.length];
        newMarkers.add(Marker(
          point:  stop.position,
          width:  72,
          height: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  stop.distanceKm != null
                      ? '${stop.index}. ${stop.distanceKm!.toStringAsFixed(1)} km\n'
                      '${stop.durationMin?.round()} min'
                      : '${stop.index}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   9,
                    fontWeight: FontWeight.bold,
                    height:     1.3,
                  ),
                ),
              ),
              Icon(Icons.location_on, color: color, size: 32),
            ],
          ),
        ));
      }

      // 7. Build polyline
      final List<Polyline> newPolylines = [];
      if (fullRoutePoints.length > 1) {
        newPolylines.add(Polyline(
          points:            fullRoutePoints,
          color:             const Color(0xFF1565C0),
          strokeWidth:       5,
          borderStrokeWidth: 2,
          borderColor:       Colors.white,
        ));
      }

      if (!mounted) return;
      setState(() {
        _polylines       = newPolylines;
        _markers         = newMarkers;
        _optimizedStops  = stops;
        _totalDistanceKm = _totalDistanceKm ?? segmentDistKm;
        _loadingRoutes   = false;
      });

      if (waypoints.length > 1) {
        final bounds = LatLngBounds.fromPoints(waypoints);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(
              padding: EdgeInsets.fromLTRB(40, 120, 40, 300)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRoutes = false);
      debugPrint('loadOptimizedRoutesFromApi error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // CAPACITY
  // ─────────────────────────────────────────────────────────

  Future<void> _loadCapacity() async {
    setState(() => _loadingCapacity = true);
    try {
      final info     = await ApiService.getMyInfo();
      final quantite =
          (info['fournisseurInfo']?['quantiteEau'] as num?)?.toDouble() ?? 0.0;
      if (!mounted) return;
      setState(() { _capacityLiters = quantite; _loadingCapacity = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _capacityLiters = 0; _loadingCapacity = false; });
    }
  }

  Future<void> _showEditCapacityDialog() async {
    _capacityController.text = _capacityLiters.toStringAsFixed(0);
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la quantité d\'eau'),
        content: TextField(
          controller:   _capacityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^[0-9]*[.,]?[0-9]*$')),
          ],
          decoration: const InputDecoration(
              hintText: 'Entrez la quantité en litres'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(
                  _capacityController.text.replaceAll(',', '.'));
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        final res =
        await ApiService.updateWaterQuantity(quantiteEau: result);
        if (res['error'] != null) {
          _showSnack('Erreur serveur', Colors.red);
          return;
        }
        await _loadCapacity();
        _showSnack('Quantité mise à jour ✓', Colors.green);
      } catch (_) {
        _showSnack('Erreur lors de la mise à jour', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      duration:        const Duration(seconds: 2),
    ));
  }

  // ─────────────────────────────────────────────────────────
  // MAP SCREEN
  // ─────────────────────────────────────────────────────────

  Widget _buildMapScreen() {
    return Stack(
      children: [
        // ── Map ─────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _gpsReady
                ? _currentPosition
                : const LatLng(36.76639, 3.47717),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.water_delivery_app',
            ),
            if (_polylines.isNotEmpty)
              PolylineLayer(polylines: _polylines),
            MarkerLayer(
              markers: [
                if (_gpsReady)
                  Marker(
                    point:  _currentPosition,
                    width:  18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color:  Colors.blue.withOpacity(0.25),
                        shape:  BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ..._markers,
              ],
            ),
          ],
        ),

        // ── Top bar ──────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    // Capacity pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color:      Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset:     const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        const Icon(Icons.local_shipping,
                            color: Color(0xFF1E3A8A), size: 24),
                        const SizedBox(width: 8),
                        _loadingCapacity
                            ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                            : Text(
                            '${_capacityLiters.toStringAsFixed(0)} L',
                            style: const TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.bold,
                              color:      Color(0xFF1E3A8A),
                            )),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showEditCapacityDialog,
                          child: const Icon(Icons.edit,
                              size: 18, color: Colors.black54),
                        ),
                      ]),
                    ),
                    // GPS / loading indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                            color:      Colors.black.withOpacity(0.1),
                            blurRadius: 8)],
                      ),
                      child: _loadingRoutes
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                          : Icon(Icons.gps_fixed,
                          color: _gpsReady
                              ? Colors.green
                              : Colors.grey,
                          size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── FABs ─────────────────────────────────────────────
        Positioned(
          right: 16,
          top:   MediaQuery.of(context).padding.top + 100,
          child: FloatingActionButton(
            mini:            true,
            heroTag:         'locate',
            backgroundColor: Colors.white,
            onPressed: () =>
                _mapController.move(_currentPosition, 14.0),
            child: const Icon(Icons.my_location,
                color: Color(0xFF1E3A8A)),
          ),
        ),
        Positioned(
          right: 16,
          top:   MediaQuery.of(context).padding.top + 160,
          child: FloatingActionButton(
            mini:            true,
            heroTag:         'refresh_routes',
            backgroundColor: Colors.white,
            onPressed:       isOnline ? _loadOptimizedRoutes : null,
            child: Icon(Icons.refresh,
                color: isOnline
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey),
          ),
        ),

        // ── Route summary panel or online/offline toggle ─────
        if (isOnline && _optimizedStops.isNotEmpty)
          Positioned(
            bottom: 90,
            left:   0,
            right:  0,
            child: _buildRouteSummaryPanel(),
          )
        else
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: _buildOnlineToggle(),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Route summary panel
  // ─────────────────────────────────────────────────────────
  Widget _buildRouteSummaryPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color:      Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset:     const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color:        Color(0xFF1E3A8A),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.route, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _routeIsValid
                        ? 'Itinéraire optimisé ✓'
                        : 'Itinéraire (non validé)',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   14,
                    ),
                  ),
                ),
                if (_totalDistanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_totalDistanceKm!.toStringAsFixed(1)} km total',
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleOnlineStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('STOP',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Stop list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap:  true,
              padding:     const EdgeInsets.symmetric(vertical: 8),
              itemCount:   _optimizedStops.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final stop  = _optimizedStops[i];
                final color = [
                  Colors.blue, Colors.green, Colors.purple,
                  Colors.orange, Colors.teal, Colors.red,
                ][i % 6];
                return ListTile(
                  dense:   true,
                  leading: CircleAvatar(
                    backgroundColor: color,
                    radius:          16,
                    child: Text('${stop.index}',
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   12,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(stop.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   13)),
                  subtitle: stop.address.isNotEmpty
                      ? Text(stop.address,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: stop.distanceKm != null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stop.distanceKm!.toStringAsFixed(1)} km',
                        style: TextStyle(
                            color:      color,
                            fontSize:   12,
                            fontWeight: FontWeight.bold),
                      ),
                      if (stop.durationMin != null)
                        Text(
                          '${stop.durationMin!.round()} min',
                          style: const TextStyle(
                              color:   Colors.grey,
                              fontSize: 10),
                        ),
                    ],
                  )
                      : null,
                  onTap: () =>
                      _mapController.move(stop.position, 15),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color:      Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset:     const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline
                        ? 'VOUS ÊTES EN LIGNE'
                        : 'VOUS ÊTES HORS LIGNE',
                    style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.green : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline
                        ? 'En attente de commandes.'
                        : 'Vous ne recevez pas de commandes.',
                    style:
                    TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleOnlineStatus,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? Colors.red
                      : const Color(0xFF1E3A8A),
                  boxShadow: [BoxShadow(
                    color: (isOnline ? Colors.red : const Color(0xFF1E3A8A))
                        .withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )],
                ),
                child: Center(
                  child: Text(
                    isOnline ? 'STOP' : 'GO',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.isGerant)
            SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFF0B3C49),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text('Retourner au tableau de bord Gérant',
                          style: TextStyle(
                              color:      Colors.white,
                              fontSize:   13,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: [
                _buildMapScreen(),
                const OrdersScreen(),
                const HistoryScreen(),
                const ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:        currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        type:                BottomNavigationBarType.fixed,
        backgroundColor:     const Color(0xFF1E3A8A),
        selectedItemColor:   Colors.white,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.map),      label: 'Carte'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Commandes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history),  label: 'Historique'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),   label: 'Profil'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Data model for a route stop
// ─────────────────────────────────────────────────────────
class _RouteStop {
  final int     index;
  final String  mongoId;
  final String  clientName;
  final LatLng  position;
  final String  address;
  final double  quantity;
  final double? distanceKm;
  final double? durationMin;

  const _RouteStop({
    required this.index,
    required this.mongoId,
    required this.clientName,
    required this.position,
    required this.address,
    required this.quantity,
    this.distanceKm,
    this.durationMin,
  });

  _RouteStop copyWith({double? distanceKm, double? durationMin}) {
    return _RouteStop(
      index:       index,
      mongoId:     mongoId,
      clientName:  clientName,
      position:    position,
      address:     address,
      quantity:    quantity,
      distanceKm:  distanceKm  ?? this.distanceKm,
      durationMin: durationMin ?? this.durationMin,
    );
  }
}