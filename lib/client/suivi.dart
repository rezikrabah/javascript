import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'client_info.dart';
import 'commandes.dart';
import 'historique.dart';
import 'profile.dart';
import '../services/api_service.dart';


class suivi extends StatefulWidget {
  final int? fournisseurId;
  const suivi({super.key, this.fournisseurId});

  @override
  State<suivi> createState() => _suiviState();
}

class _suiviState extends State<suivi> {
  final MapController mapController = MapController();






  Timer?  _refreshTimer;
  LatLng? _myPosition;
  List<Map<String, dynamic>> _onlineFournisseurs = [];

  @override
  void initState() {
    super.initState();
    _loadOnlineFournisseurs();
    _startGpsTracking();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOnlineFournisseurs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnlineFournisseurs() async {
    final list = await ApiService.getMyChauffeurs();
    setState(() {
      _onlineFournisseurs = list
          .where((f) =>
      f['isOnline'] == true &&
          f['position']?['lat'] != null &&
          f['position']?['lon'] != null)
          .map((f) => Map<String, dynamic>.from(f))
          .toList();
    });
  }



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

  // ── Nav Item Helper ──────────────────────────────────────
  Widget _navItem(IconData icon, String label, VoidCallback onTap, {bool active = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(icon,
            color: active ? const Color(0xFF4ECDC4) : Colors.white,
            size: 20,
          ),
          onPressed: onTap,
        ),
        Text(label,
          style: TextStyle(
            fontSize: 8,
            color: active ? const Color(0xFF4ECDC4) : Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

              MarkerLayer(markers: [
                if (_myPosition != null)
                  Marker(
                    point: _myPosition!,
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                  ),

                ..._onlineFournisseurs.map((f) {
                  final lat = (f['position']['lat'] as num).toDouble();
                  final lon = (f['position']['lon'] as num).toDouble();
                  final nom = '${f['prenom'] ?? ''} ${f['nom'] ?? ''}'.trim();
                  return Marker(
                    point: LatLng(lat, lon),
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
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

              ]),
            ],
          ),

          // ── Bouton "Faire une commande" ───────────────────────
          Positioned(
            top: screenHeight * 0.66,
            right: screenWidth *  0.1 ,
            left:  screenWidth *  0.05 ,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => commandes(
                      clientId: int.tryParse(ApiService.userId ?? '1') ?? 1,
                    ),
                  ),
                );
              },
              child: Container(
                height: screenHeight * 0.11,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.018,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3C49),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    const Text(
                      'Faire une commande',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── My location FAB ───────────────────────────────
          Positioned(
            bottom: screenHeight * 0.6,
            right: screenWidth * 0.04,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF0B3C49)),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.69,
            right: screenWidth * 0.04,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: Colors.white,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ClientInfoScreen())),
              child: const Icon(Icons.info_outline, color: Color(0xFF0B3C49)),
            ),
          ),

          // ── Refresh FAB ───────────────────────────────────

        ],
      ),


      bottomNavigationBar: BottomAppBar(
        notchMargin: 8,
        color: const Color(0xFF0B3C49),
        padding: EdgeInsets.zero,   // supprime le padding interne par défaut
        child: SizedBox(
          height: 60,               // hauteur fixe et fiable
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(CupertinoIcons.map, 'suivi', () {}, active: true),
              _navItem(CupertinoIcons.cube_box_fill, 'commandes', () =>
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => commandes(
                      clientId: int.tryParse(ApiService.userId ?? '1') ?? 1,
                    ),
                  )),
              ),
              _navItem(CupertinoIcons.clock, 'historique', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => historique())),
              ),
              _navItem(CupertinoIcons.profile_circled, 'profile', () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => profile())),
              ),
            ],
          ),
        ),


      ),
    );
  }
}