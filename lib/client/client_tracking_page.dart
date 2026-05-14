import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../fournisseur/chauffeur_review_screen.dart';
import '../services/api_service.dart';
import '../services/osrmservice.dart';
import 'client_review_screen.dart';

class ClientTrackingPage extends StatefulWidget {
  final String commandeId;
  final String clientId;
  final String? chauffeurId;
  final String clientNom;
  final String driverPhone;
  final double volumeLivre;
  final String adresse;

  const ClientTrackingPage({
    super.key,
    required this.commandeId,
    required this.clientId,
    required this.driverPhone,
    required this.clientNom,
    required this.volumeLivre,
    required this.adresse,
    this.chauffeurId,
  });

  @override
  State<ClientTrackingPage> createState() => _ClientTrackingPageState();
}

class _ClientTrackingPageState extends State<ClientTrackingPage> {
  final MapController _mapController = MapController();
  Timer? _timer;

  // ── State ──────────────────────────────────────────────────────
  String       _statut      = 'en_attente';
  LatLng?      _driverPos;
  LatLng?      _destination;
  List<LatLng> _routePoints = [];
  bool _deliveryDialogShown = false;
  double?   _distanceKm;
  double?   _durationMin;
  String?   _driverName;
  String?   _driverPhone;
  String?   _chauffeurId;
  double? _driverRating;
  DateTime? _lastDriverUpdate;
  bool      _loading = true;
  String?   _error;
  bool      _ratingNavigated = false;

  // Last position used for OSRM re-route (threshold gate)
  LatLng? _lastReroutedPos;

  // Prevents overlapping HTTP requests
  bool _isFetching = false;

  // Only auto-fit map bounds on first driver position
  bool _hasAutoFitted = false;

  static const double _rerouteThresholdMeters = 50.0;

  // ── FIX: Poll every 3 s so simulation movement (uploaded every ~1 s)
  // is visible to the client without noticeable lag.
  static const Duration _pollInterval = Duration(seconds: 8);
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _chauffeurId = widget.chauffeurId;
    _driverPhone = widget.driverPhone;
    _fetchTracking();
    _timer = Timer.periodic(_pollInterval, (_) => _fetchTracking());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
  Map<String, dynamic> _map(dynamic d) => {
    'phone':     d['telephone'] ?? '',
    'deliveries':d['totalLivraisons'] ?? 0,
    'rating':    (d['noteMoyenne'] ?? 0.0).toDouble(),
  };
  Future<void> _fetchTracking() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final res = await http
          .get(
        Uri.parse('${ApiService.baseUrl}/api/commandes/${widget.commandeId}/track'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer ${ApiService.token}',
        },
      )
          .timeout(const Duration(seconds: 8));

      // ── Handle 429 — back off and retry later
      if (res.statusCode == 429) {
        _errorCount++;
        _scheduleBackoff();
        return;
      }

      if (res.statusCode == 404) {
        await _fetchCommandeStatus();
        return;
      }

      if (res.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error   = 'Erreur serveur (${res.statusCode})';
            _loading = false;
          });
        }
        return;
      }

      // Success — reset error count
      _errorCount = 0;
      final data = jsonDecode(res.body);
      await _applyTrackingData(data);

    } on TimeoutException {
      _errorCount++;
      _scheduleBackoff();
      if (mounted) setState(() => _error = 'Délai dépassé, nouvelle tentative...');
    } catch (e) {
      _errorCount++;
      await _fetchCommandeStatus();
    } finally {
      _isFetching = false;
    }
  }



  void _scheduleBackoff() {
    _timer?.cancel();
    final backoff = Duration(
      seconds: (_pollInterval.inSeconds * (1 << _errorCount.clamp(0, 3))).clamp(8, 60),
    );
    if (mounted) setState(() => _error = 'Trop de requêtes, reprise dans ${backoff.inSeconds}s...');
    _timer = Timer(backoff, () {
      if (!mounted) return;
      _errorCount = 0;      // ← reset error count so backoff resets
      _fetchTracking();
      _timer?.cancel();     // ← cancel the one-shot before creating periodic
      _timer = Timer.periodic(_pollInterval, (_) => _fetchTracking());
    });
  }
  Future<void> _fetchCommandeStatus() async {
    try {
      final commandes = await ApiService.getMyCommandes();
      final commande  = commandes.firstWhere(
            (c) => (c['_id'] ?? c['id']).toString() == widget.commandeId,
        orElse: () => {},
      );

      if (!mounted) return;

      if (commande.isNotEmpty) {
        final raw = commande['status'] ?? commande['statut'] ?? 'en attente';
        debugPrint('[CLIENT] fetchCommandeStatus raw: "$raw"');
        final normalized = _normalizeStatus(
            commande['status'] ?? commande['statut'] ?? 'en attente');
        setState(() {
          _statut  = normalized;
          _loading = false;
          _error   = null;
        });
        if (normalized == 'refusee' || normalized == 'livree') {
          _timer?.cancel();
          if (normalized == 'livree') _showDeliveryConfirmDialog();
        }
      } else {
        setState(() {
          _loading = false;
          _statut  = 'en_attente';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = 'Connexion impossible';
        _loading = false;
      });
    }
  }

  // Returns true if the new position is far enough to justify an
  // OSRM API call. The marker itself always updates regardless.
  bool _shouldReroute(LatLng newPos) {
    if (_lastReroutedPos == null) return true;
    const Distance d = Distance();
    return d.as(LengthUnit.Meter, _lastReroutedPos!, newPos) >=
        _rerouteThresholdMeters;
  }

  Future<void> _applyTrackingData(Map<String, dynamic> data) async {
    final rawStatus = (data['statut'] ?? data['status'] ?? 'en attente').toString();
    final statut    = _normalizeStatus(rawStatus);
    debugPrint('[CLIENT] raw status from server: "$rawStatus"');
    debugPrint('[CLIENT] normalized status: "$statut"');
    debugPrint('[CLIENT] full data: $data');
    debugPrint('[FOURNISSEUR] raw object: ${data['fournisseur']}');
    // ── Parse driver position ─────────────────────────────────
    LatLng? driverPos;
    if (data['driver_lat'] != null && data['driver_lon'] != null) {
      driverPos = LatLng(
        (data['driver_lat'] as num).toDouble(),
        (data['driver_lon'] as num).toDouble(),
      );
      _lastDriverUpdate = data['lastUpdate'] != null
          ? DateTime.tryParse(data['lastUpdate'].toString())
          : null;
    }

    // ── Parse destination ─────────────────────────────────────
    LatLng? destination;
    final dest = data['destination'];
    if (dest != null && dest['lat'] != null && dest['lon'] != null) {
      destination = LatLng(
        (dest['lat'] as num).toDouble(),
        (dest['lon'] as num).toDouble(),
      );
    }

    // ── FIX 2 & 3: Always update _driverPos (marker moves every poll).
    // Only call OSRM when the driver has moved more than the threshold.
    List<LatLng> routePoints = _routePoints;
    double?      distanceKm  = _distanceKm;
    double?      durationMin = _durationMin;

    if (driverPos != null) {
      if (destination != null && _shouldReroute(driverPos)) {
        // Driver moved enough — fetch fresh road route from OSRM
        try {
          final result =
          await OsrmService.getRouteWithMetrics(driverPos, destination);
          routePoints          = result['points']      as List<LatLng>;
          distanceKm           = result['distanceKm']  as double?;
          durationMin          = result['durationMin'] as double?;
          _lastReroutedPos     = driverPos;
        } catch (_) {
          // OSRM failed — draw a straight line fallback
          routePoints      = [driverPos, destination];
          _lastReroutedPos = driverPos;
        }
      } else if (destination != null && routePoints.isNotEmpty) {
        // Driver hasn't moved enough for a full re-route.
        // Trim the polyline: drop all points behind the driver so the
        // rendered route shrinks as the truck advances.
        final trimmed = _trimRouteToDriver(driverPos, routePoints);
        if (trimmed.length >= 2) routePoints = trimmed;
      }
      // If destination is null, just show the driver dot with no route.
    }

    // ── Parse driver / supplier name ──────────────────────────
    String? driverName;
    String? driverPhone;
    final chauffeur   = data['chauffeur'];
    final fournisseur = data['fournisseur'];

    if (chauffeur != null && chauffeur['nom'] != null) {
      driverName    = chauffeur['nom'];
      driverPhone   = chauffeur['telephone'] ?? chauffeur['phone'] ?? widget.driverPhone;
      _chauffeurId  = (chauffeur['_id'] ?? chauffeur['id'])?.toString();
      _driverRating = (chauffeur['noteMoyenne'] ?? 0.0).toDouble(); // ← add this
    } else if (fournisseur != null) {
      driverName =
          '${fournisseur['prenom'] ?? ''} ${fournisseur['nom'] ?? ''}'.trim();
      if (driverName!.isEmpty) driverName = null;
      _chauffeurId  ??= (fournisseur['_id'] ?? fournisseur['id'])?.toString();
      driverPhone     = fournisseur['telephone']?.toString();         // ← add
      _driverRating   = (fournisseur['noteMoyenne'] ?? 0.0).toDouble(); // ← add
    }

    if (!mounted) return;

    // ── FIX 3: Always update _driverPos so marker redraws every poll ──
    setState(() {
      _error        = null;
      _loading      = false;
      _statut       = statut;
      _driverPos    = driverPos;
      _destination  = destination;
      _routePoints  = routePoints;
      _distanceKm   = distanceKm;
      _durationMin  = durationMin;
      _driverName   = driverName;
      _driverPhone  = driverPhone;
      _driverRating = _driverRating;
    });

    debugPrint('[CHAUFFEUR] name=$driverName phone=$driverPhone rating=$_driverRating');
    debugPrint('[CHAUFFEUR] raw object: $chauffeur');
    if (statut == 'livree' || statut == 'refusee') {
      _timer?.cancel();
      if (statut == 'livree' && !_deliveryDialogShown) {
        _deliveryDialogShown = true;
        _showDeliveryConfirmDialog();
      }
      return;
    }
    // Auto-fit bounds only on the very first update
    if (!_hasAutoFitted) {
      _hasAutoFitted = true;
      if (driverPos != null && destination != null) {
        _mapController.fitBounds(
          LatLngBounds.fromPoints([driverPos, destination]),
          options: const FitBoundsOptions(padding: EdgeInsets.all(80)),
        );
      } else if (driverPos != null) {
        _mapController.move(driverPos, 15);
      } else if (destination != null) {
        _mapController.move(destination, 14);
      }
    }
  }

  // Trim all polyline points that are "behind" the driver's current
  // position so the drawn route shrinks as the truck moves forward.
  List<LatLng> _trimRouteToDriver(
      LatLng driverPos, List<LatLng> points) {
    if (points.isEmpty) return points;

    const Distance d = Distance();
    int closestIdx = 0;
    double closestDist = double.infinity;

    for (int i = 0; i < points.length; i++) {
      final dist = d.as(LengthUnit.Meter, driverPos, points[i]);
      if (dist < closestDist) {
        closestDist = dist;
        closestIdx  = i;
      }
    }
    // Return from the closest point onwards, prepending actual driver pos
    return [driverPos, ...points.sublist(closestIdx)];
  }

  void _showDeliveryConfirmDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.local_shipping, color: Color(0xFF0B3C49), size: 28),
          SizedBox(width: 10),
          Text('Confirmer la livraison',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'Avez-vous bien reçu votre commande ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Not received yet — resume polling
              _timer = Timer.periodic(_pollInterval, (_) => _fetchTracking());
            },
            child: const Text('Non, pas encore',
                style: TextStyle(color: Colors.grey)),
          ),
    ElevatedButton.icon(
    onPressed: () async {
    Navigator.pop(ctx, true); // close dialog first
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
    // ← await the review screen so simulation resumes AFTER returning
    await Navigator.push(context, MaterialPageRoute(
    builder: (_) => ClientReviewScreen(
    commandeId:   widget.commandeId,
    chauffeurNom: _driverName ?? 'Livreur',
    volumeLivre:  widget.volumeLivre,
    prixFinal:    0.0, // replace with actual price if available
    ),
    ));
    }
    },
    icon:  const Icon(Icons.check_circle_outline),
    label: const Text('Confirmer la livraison'),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    ),
        ],

      ),
    );
  }

  String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'en attente':
      case 'pending':        return 'en_attente';
      case 'acceptee':
      case 'acceptée':
      case 'accepted':       return 'acceptee';
      case 'en livraison':
      case 'assigned':
      case 'assignee':
      case 'assignée':       return 'assignee';
      case 'livrée':
      case 'livree':
      case 'delivered':
      case 'livré':          return 'livree';
      case 'annulée':
      case 'annulee':
      case 'cancelled':
      case 'refusee':
      case 'refusée':
      case 'refused':        return 'refusee';
      default:               return 'en_attente';
    }
  }

  Color get _statusColor {
    switch (_statut) {
      case 'en_attente': return Colors.orange;
      case 'acceptee':   return Colors.blue;
      case 'assignee':   return const Color(0xFF9C27B0);
      case 'livree':     return Colors.green;
      case 'refusee':    return Colors.red;
      default:           return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (_statut) {
      case 'en_attente': return '⏳ En attente de confirmation';
      case 'acceptee':   return '✅ Commande acceptée';
      case 'assignee':   return '🚚 Livreur en route';
      case 'livree':     return '🎉 Livraison effectuée !';
      case 'refusee':    return '❌ Commande refusée';
      default:           return _statut;
    }
  }

  String? _getLastUpdateText() {
    if (_lastDriverUpdate == null) return null;
    final diff = DateTime.now().difference(_lastDriverUpdate!);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return 'Il y a ${diff.inHours} h';
  }

  Widget _buildFinalScreen() {
    final isDelivered = _statut == 'livree';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: (isDelivered ? Colors.green : Colors.red)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDelivered ? Icons.check_circle : Icons.cancel,
                size:  80,
                color: isDelivered ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color: isDelivered ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isDelivered
                  ? 'Votre commande a été livrée avec succès.'
                  : 'Votre commande a été refusée par le fournisseur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            if (isDelivered)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChauffeurReviewScreen(
                        commandeId:  widget.commandeId,
                        clientNom:   widget.clientNom,
                        driverPhone:   widget.driverPhone,
                        volumeLivre: widget.volumeLivre,
                        adresse:     widget.adresse,
                      ),
                    ),
                  );
                },
                icon:  const Icon(Icons.star),
                label: const Text('Évaluer le livreur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon:  const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C49),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Commande #${widget.commandeId.length > 8 ? widget.commandeId.substring(0, 8) : widget.commandeId}...',
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        backgroundColor: const Color(0xFF0B3C49),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: _fetchTracking,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_statut == 'refusee' || _statut == 'livree')
          ? _buildFinalScreen()
          : Stack(
        children: [

          // ── Map ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverPos ??
                  _destination ??
                  const LatLng(36.7538, 3.0588),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.yourname.waterdelivery',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:            _routePoints,
                      color:             const Color(0xFF2979FF),
                      strokeWidth:       5,
                      borderStrokeWidth: 2,
                      borderColor:       Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // ── Truck marker — updates every 3 s ──
                  if (_driverPos != null)
                    Marker(
                      point:  _driverPos!,
                      width:  screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      child: Container(
                        decoration: BoxDecoration(
                          color:  Colors.red,
                          shape:  BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color:      Colors.black26,
                              blurRadius: 8,
                              offset:     Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.local_shipping,
                            color: Colors.white,
                            size:  screenWidth * 0.07),
                      ),
                    ),
                  // ── Destination pin ──────────────────
                  if (_destination != null)
                    Marker(
                      point:  _destination!,
                      width:  screenWidth * 0.13,
                      height: screenWidth * 0.15,
                      child: Icon(Icons.location_on,
                          color: Colors.green,
                          size:  screenWidth * 0.11),
                    ),
                ],
              ),
            ],
          ),

          // ── Status card ───────────────────────────────
          Positioned(
            top:   screenHeight * 0.02,
            left:  screenWidth  * 0.04,
            right: screenWidth  * 0.04,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding:
                EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  mainAxisSize:       MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width:  screenWidth * 0.03,
                        height: screenWidth * 0.03,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Expanded(
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:   screenWidth * 0.035,
                          ),
                        ),
                      ),
                      if (_statut == 'assignee')
                        SizedBox(
                          width:  screenWidth * 0.04,
                          height: screenWidth * 0.04,
                          child:
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                    ]),

                    if (_driverName != null) ...[
                      SizedBox(height: screenHeight * 0.015),
                      Row(children: [
                        // ── Avatar ──────────────────────────────────
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: screenWidth * 0.045,
                          child: Icon(Icons.local_shipping,
                              color: Colors.green.shade700,
                              size:  screenWidth * 0.05),
                        ),
                        SizedBox(width: screenWidth * 0.03),

                        // ── Name + Phone + Rating ────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                _driverName!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize:   screenWidth * 0.035,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.004),

                              // Phone
                              if (_driverPhone != null)
                                Row(children: [
                                  Icon(Icons.phone_outlined,
                                      size:  screenWidth * 0.03,
                                      color: Colors.grey.shade500),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    _driverPhone!,
                                    style: TextStyle(
                                      color:    Colors.grey.shade600,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ]),

                              SizedBox(height: screenHeight * 0.004),

                              // Rating stars
                              if (_driverRating != null)
                                Row(children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < _driverRating!.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size:  screenWidth * 0.035,
                                    color: Colors.amber,
                                  )),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    _driverRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize:   screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                      color:      Colors.amber.shade700,
                                    ),
                                  ),
                                ]),
                            ],
                          ),
                        ),

                        // ── Call button ──────────────────────────────
                        if (_driverPhone != null)
                          IconButton(
                            icon: Icon(Icons.phone,
                                color: Colors.green,
                                size:  screenWidth * 0.055),
                            onPressed: () {},
                          ),
                      ]),
                    ],

                    if (_distanceKm != null &&
                        _durationMin != null) ...[
                      SizedBox(
                          height: screenHeight * 0.015),
                      const Divider(height: 1),
                      SizedBox(
                          height: screenHeight * 0.015),
                      Row(children: [
                        Expanded(
                          child: _buildMetricTile(
                            icon:       Icons.route,
                            value:
                            '${_distanceKm!.toStringAsFixed(1)} km',
                            label:      'Distance',
                            screenWidth: screenWidth,
                          ),
                        ),
                        Container(
                            height: 30,
                            width:  1,
                            color:
                            Colors.grey.shade300),
                        Expanded(
                          child: _buildMetricTile(
                            icon:       Icons.access_time,
                            value:
                            '${_durationMin!.round()} min',
                            label:      'Temps estimé',
                            screenWidth: screenWidth,
                          ),
                        ),
                        if (_getLastUpdateText() !=
                            null) ...[
                          Container(
                              height: 30,
                              width:  1,
                              color:
                              Colors.grey.shade300),
                          Expanded(
                            child: _buildMetricTile(
                              icon:      Icons.update,
                              value:
                              _getLastUpdateText()!,
                              label:     'Mise à jour',
                              iconColor: Colors.orange,
                              screenWidth: screenWidth,
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Waiting overlay ──────────────────────────
          if (_statut == 'en_attente')
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08),
                padding:
                EdgeInsets.all(screenWidth * 0.06),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color:      Colors.black12,
                        blurRadius: 12)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top,
                        size:  screenWidth * 0.13,
                        color: _statusColor),
                    SizedBox(
                        height: screenHeight * 0.015),
                    Text(
                      'En attente d\'acceptation\npar le fournisseur',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.038),
                    ),
                  ],
                ),
              ),
            ),

          // ── In delivery, no GPS yet ──────────────────
          if (_statut == 'assignee' && _driverPos == null)
            Positioned(
              bottom: screenHeight * 0.22,
              left:   screenWidth  * 0.04,
              right:  screenWidth  * 0.04,
              child: Container(
                padding:
                EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color:      Colors.black12,
                        blurRadius: 8)
                  ],
                ),
                child: Row(children: [
                  Icon(Icons.local_shipping,
                      color:
                      const Color(0xFF9C27B0),
                      size: screenWidth * 0.06),
                  SizedBox(
                      width: screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      'Votre commande est en livraison.\n'
                          'Localisation du livreur en cours...',
                      style: TextStyle(
                          fontSize:
                          screenWidth * 0.033),
                    ),
                  ),
                  SizedBox(
                    width:  screenWidth * 0.05,
                    height: screenWidth * 0.05,
                    child:
                    const CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Color(0xFF9C27B0)),
                  ),
                ]),
              ),
            ),

          // ── Control FABs ─────────────────────────────
          Positioned(
            bottom: screenHeight * 0.12,
            right:  screenWidth  * 0.04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_driverPos != null)
                  FloatingActionButton.small(
                    heroTag:         'center_driver',
                    backgroundColor: Colors.white,
                    onPressed: () => _mapController
                        .move(_driverPos!, 16),
                    child: Icon(Icons.local_shipping,
                        color: Colors.red,
                        size:  screenWidth * 0.05),
                  ),
                if (_driverPos != null)
                  SizedBox(
                      height: screenHeight * 0.01),
                if (_destination != null)
                  FloatingActionButton.small(
                    heroTag:         'center_dest',
                    backgroundColor: Colors.white,
                    onPressed: () => _mapController
                        .move(_destination!, 16),
                    child: Icon(Icons.location_on,
                        color: Colors.green,
                        size:  screenWidth * 0.05),
                  ),
                if (_destination != null)
                  SizedBox(
                      height: screenHeight * 0.01),
                FloatingActionButton(
                  heroTag:         'fit_bounds',
                  backgroundColor:
                  const Color(0xFF0B3C49),
                  onPressed: () {
                    if (_driverPos != null &&
                        _destination != null) {
                      _mapController.fitBounds(
                        LatLngBounds.fromPoints(
                            [_driverPos!, _destination!]),
                        options:
                        const FitBoundsOptions(
                            padding:
                            EdgeInsets.all(100)),
                      );
                    } else if (_destination != null) {
                      _mapController.move(
                          _destination!, 14);
                    }
                  },
                  child: Icon(
                      Icons.center_focus_strong,
                      size: screenWidth * 0.06),
                ),
              ],
            ),
          ),

          // ── Error banner ─────────────────────────────
          if (_error != null)
            Positioned(
              bottom: screenHeight * 0.025,
              left:   screenWidth  * 0.04,
              right:  screenWidth  * 0.04,
              child: Container(
                padding:
                EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color:        Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.wifi_off,
                      color: Colors.deepOrange,
                      size:  screenWidth * 0.045),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color:    Colors.deepOrange,
                        fontSize: screenWidth * 0.033,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchTracking,
                    child: Text('Réessayer',
                        style: TextStyle(
                            fontSize:
                            screenWidth * 0.03)),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String   value,
    required String   label,
    required double   screenWidth,
    Color?            iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            size:  screenWidth * 0.04,
            color: iconColor ?? Colors.grey.shade600),
        SizedBox(width: screenWidth * 0.015),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   screenWidth * 0.033,
                )),
            Text(label,
                style: TextStyle(
                  color:    Colors.grey.shade600,
                  fontSize: screenWidth * 0.025,
                )),
          ],
        ),
      ],
    );
  }
}