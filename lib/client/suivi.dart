import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'clientpage.dart';
import 'commandes.dart';
import 'historique.dart';
import 'profile.dart';
import '../services/api_service.dart';
import '../services/osrmservice.dart'; // ✅ OSRM import

const List<Color> _routeColors = [
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
  Color(0xFFFF5722),
  Color(0xFF00BCD4),
];

class suivi extends StatefulWidget {
  final int? fournisseurId;
  const suivi({super.key, this.fournisseurId});

  @override
  State<suivi> createState() => _suiviState();
}

class _suiviState extends State<suivi> {
  final MapController mapController = MapController();

  List<Polyline> _polylines     = [];
  List<Marker>   _markers       = [];
  bool           _loadingRoutes = false;
  String?        _routeError;
  double?        _totalDistance;

  Timer?  _refreshTimer;
  LatLng? _myPosition;

  @override
  void initState() {
    super.initState();
    _loadSolution();
    _loadOnlineFournisseurs(); // 👈
    _startGpsTracking();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 30), (_) {
      _loadSolution();
      _loadOnlineFournisseurs(); // 👈 refresh every 30s too
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _onlineFournisseurs = [];

  Future<void> _loadOnlineFournisseurs() async {
    final list = await ApiService.getFournisseurs();
    print('🔍 Total fournisseurs from API: ${list.length}');
    for (var f in list) {
      print('👤 ${f['nom']} | isOnline: ${f['isOnline']} | position: ${f['position']}');
    }
    setState(() {
      _onlineFournisseurs = list
          .where((f) =>
      f['isOnline'] == true &&
          f['position']?['lat'] != null &&
          f['position']?['lon'] != null)
          .map((f) => Map<String, dynamic>.from(f))
          .toList();
    });
    print('✅ Online with position: ${_onlineFournisseurs.length}');
  }
  // ── Load solution using OSRM ──────────────────────────────
  Future<void> _loadSolution() async {
    setState(() { _loadingRoutes = true; _routeError = null; });

    try {
      // ✅ Get client's commandes that are en livraison
      final commandes = await ApiService.getMyCommandes();
      final accepted  = commandes.where((c) =>
      (c['status'] ?? '').toString() == 'en livraison').toList();

      if (accepted.isEmpty) {
        setState(() {
          _routeError    = 'Aucune commande en livraison pour le moment.';
          _loadingRoutes = false;
        });
        return;
      }

      final newPolylines = <Polyline>[];
      final newMarkers   = <Marker>[];
      double totalDist   = 0.0;

      for (int i = 0; i < accepted.length; i++) {
        final cmd   = accepted[i];
        final color = _routeColors[i % _routeColors.length];

        // ✅ Client destination position
        final clientLat = (cmd['position']?['lat'] as num?)?.toDouble();
        final clientLon = (cmd['position']?['lon'] as num?)?.toDouble();
        if (clientLat == null || clientLon == null) continue;
        final clientPos = LatLng(clientLat, clientLon);

        // ✅ Fournisseur position from populated fournisseur field
        final fourn    = cmd['fournisseur'];
        double? fournLat, fournLon;
        if (fourn is Map) {
          fournLat = (fourn['position']?['lat'] as num?)?.toDouble();
          fournLon = (fourn['position']?['lon'] as num?)?.toDouble();
        }

        List<LatLng> routePoints;
        if (fournLat != null && fournLon != null) {
          final fournPos = LatLng(fournLat, fournLon);

          // ✅ OSRM real road route
          routePoints = await OsrmService.getRoute(fournPos, clientPos);
          final dist  = await OsrmService.getDistanceAndDuration(fournPos, clientPos);
          totalDist  += dist['distance'] ?? 0.0;

          // Fournisseur truck marker
          newMarkers.add(Marker(
            point: fournPos, width: 44, height: 44,
            child: Tooltip(
              message: 'Votre livreur',
              child: Icon(Icons.local_shipping, color: color, size: 36),
            ),
          ));
        } else {
          // No fournisseur position yet — just show client marker
          routePoints = [clientPos];
        }

        // Client home marker
        newMarkers.add(Marker(
          point: clientPos, width: 44, height: 55,
          child: Tooltip(
            message: 'Votre adresse',
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.home, color: color, size: 30),
            ]),
          ),
        ));

        // ✅ OSRM real road polyline
        if (routePoints.length > 1) {
          newPolylines.add(Polyline(
            points:      routePoints,
            color:       color,
            strokeWidth: 4.0,
          ));
        }
      }

      setState(() {
        _polylines     = newPolylines;
        _markers       = newMarkers;
        _totalDistance = totalDist > 0 ? totalDist : null;
        _loadingRoutes = false;
      });

      if (newMarkers.isNotEmpty) {
        mapController.move(newMarkers.last.point, 13);
      }
    } catch (e) {
      setState(() {
        _routeError    = 'Erreur: $e';
        _loadingRoutes = false;
      });
    }
  }

  // ── GPS tracking ──────────────────────────────────────────
  Future<void> _startGpsTracking() async {
    try {
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));
      });
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  void _goToMyLocation() async {
    if (_myPosition != null) {
      mapController.move(_myPosition!, 15);
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition();
        mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      } catch (_) {}
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(36.7538, 3.0588),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yourname.yourapp',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: [
                if (_myPosition != null)
                  Marker(
                    point: _myPosition!, width: 40, height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                  ),

                // 👇 Online fournisseurs markers
                ..._onlineFournisseurs.map((f) {
                  final lat = (f['position']['lat'] as num).toDouble();
                  final lon = (f['position']['lon'] as num).toDouble();
                  final nom = '${f['prenom'] ?? ''} ${f['nom'] ?? ''}'.trim();
                  return Marker(
                    point: LatLng(lat, lon),
                    width: 60,
                    height: 60,
                    child: Tooltip(
                      message: nom.isNotEmpty ? nom : 'Chauffeur',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nom.isNotEmpty ? nom.split(' ').first : 'Livreur',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.local_shipping, color: Colors.teal, size: 28),
                        ],
                      ),
                    ),
                  );
                }),

                ..._markers,
              ]),
            ],
          ),

          // ── Loading ────────────────────────────────────
          if (_loadingRoutes)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Calcul de la route...', style: TextStyle(fontSize: 13)),
                  ]),
                ),
              ),
            ),

          // ── Error ──────────────────────────────────────
          if (_routeError != null && !_loadingRoutes)
            Positioned(
              top: 60, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: Colors.deepOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_routeError!,
                      style: const TextStyle(
                          color: Colors.deepOrange, fontSize: 13))),
                  TextButton(
                    onPressed: _loadSolution,
                    child: const Text('Réessayer',
                        style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ),
            ),

          // ── Distance badge ─────────────────────────────
          if (_totalDistance != null)
            Positioned(
              top: 60, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF0B3C49),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.route, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('${_totalDistance!.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),

          // ── My location FAB ────────────────────────────
          Positioned(
            bottom: 110, right: 16,
            child: FloatingActionButton.small(
              heroTag: 'location', backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location,
                  color: Color(0xFF0B3C49)),
            ),
          ),

          // ── Refresh FAB ────────────────────────────────
          Positioned(
            bottom: 160, right: 16,
            child: FloatingActionButton.small(
              heroTag: 'refresh', backgroundColor: Colors.white,
              onPressed: _loadSolution,
              child: const Icon(Icons.refresh, color: Color(0xFF0B3C49)),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B3C49),
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.home, color: Colors.white),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => clientpage())),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        notchMargin: 8, height: 90, color: const Color(0xFF0B3C49),
        child: Row(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(CupertinoIcons.map,
                        color: Colors.white, size: 20),
                    onPressed: () {}),
                const Text('suivi',
                    style: TextStyle(fontSize: 10, color: Colors.white)),
              ]),
          const SizedBox(width: 35),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.cube_box_fill,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => commandes(
                        clientId: int.tryParse(
                            ApiService.userId ?? '1') ?? 1,
                      ))),
                ),
                const Text('commandes',
                    style: TextStyle(fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ]),
          const SizedBox(width: 25),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(CupertinoIcons.clock,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => historique())),
                ),
                const Text('historique',
                    style: TextStyle(color: Colors.white, fontSize: 8)),
              ]),
          const SizedBox(width: 22, height: 80),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.profile_circled,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => profile())),
                ),
                const Text('profile',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ]),
        ]),
      ),
    );
  }
}