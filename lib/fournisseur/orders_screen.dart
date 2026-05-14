import 'dart:math';
import 'package:flutter/material.dart';
import 'package:test2/fournisseur/provider_home_screen_FINAL.dart';
import '../services/api_service.dart';
import 'dart:async';
class OrdersScreen extends StatefulWidget {
  final VoidCallback? onOrdersRegenerated;
  const OrdersScreen(Future<List<dynamic>> pendingCommandes, {Key? key, this.onOrdersRegenerated}) : super(key: key);


  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  String selectedFilter = 'Toutes';
  List<Map<String, dynamic>> orders = [];
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _testOrders = [];
  String? _acceptingOrderId;
  bool _acceptingAll = false;
  DateTime? _lastFetch;
  // ── Algerian cities with real coordinates ──────────────────────
  static const List<Map<String, dynamic>> _algerianCities = [
    {'city': 'Alger Centre',     'lat': 36.7372, 'lon': 3.0865},
    {'city': 'Bir Mourad Raïs',  'lat': 36.7167, 'lon': 3.0583},
    {'city': 'Birtouta',         'lat': 36.6725, 'lon': 2.9972},
    {'city': 'Draria',           'lat': 36.7050, 'lon': 3.0100},
    {'city': 'Bab El Oued',      'lat': 36.7870, 'lon': 3.0600},
    {'city': 'Hussein Dey',      'lat': 36.7419, 'lon': 3.1058},
    {'city': 'Kouba',            'lat': 36.7272, 'lon': 3.1017},
    {'city': 'El Harrach',       'lat': 36.7211, 'lon': 3.1344},
    {'city': 'Birkhadem',        'lat': 36.7100, 'lon': 3.0500},
    {'city': 'Cheraga',          'lat': 36.7683, 'lon': 2.9581},
    {'city': 'Hydra',            'lat': 36.7472, 'lon': 3.0361},
    {'city': 'El Biar',          'lat': 36.7644, 'lon': 3.0258},
    {'city': 'Staoueli',         'lat': 36.7481, 'lon': 2.8928},
    {'city': 'Ouled Fayet',      'lat': 36.7208, 'lon': 2.9178},
    {'city': 'Zeralda',          'lat': 36.6983, 'lon': 2.8561},
    {'city': 'Réghaia',          'lat': 36.7239, 'lon': 3.3433},
    {'city': 'Bordj El Kiffan',  'lat': 36.7469, 'lon': 3.1897},
    {'city': 'Dar El Beïda',     'lat': 36.7161, 'lon': 3.2125},
    {'city': 'Rouiba',           'lat': 36.7231, 'lon': 3.2822},
    {'city': 'Ain Taya',         'lat': 36.7900, 'lon': 3.2989},
    {'city': 'Blida',            'lat': 36.4722, 'lon': 2.8278},
    {'city': 'Médéa',            'lat': 36.2642, 'lon': 2.7522},
    {'city': 'Tizi Ouzou',       'lat': 36.7169, 'lon': 4.0497},
    {'city': 'Boumerdès',        'lat': 36.7650, 'lon': 3.4772},
    {'city': 'Tipaza',           'lat': 36.5892, 'lon': 2.4456},
  ];

  static const List<String> _firstNames = [
    'Karim', 'Amina', 'Youcef', 'Fatima', 'Mohamed', 'Nadia',
    'Omar', 'Samira', 'Rachid', 'Houria', 'Bilal', 'Meriem',
    'Sofiane', 'Asma', 'Hamza', 'Lina', 'Abdelkader', 'Sabrina',
    'Mehdi', 'Zineb', 'Walid', 'Rania', 'Tarek', 'Imane',
  ];

  static const List<String> _lastNames = [
    'Boudjemaa', 'Cherif', 'Mansouri', 'Ait Oumeziane', 'Bensalem',
    'Hadj Ali', 'Meziane', 'Khelifa', 'Belkacem', 'Boukhalfa',
    'Amrani', 'Ferhat', 'Ouali', 'Rahmani', 'Mabrouk',
    'Bouzidi', 'Saidi', 'Benali', 'Ould Ahmed', 'Zerrouki',
  ];

  static const List<String> _streetTypes = [
    'Rue', 'Avenue', 'Boulevard', 'Cité', 'Lotissement',
    'Résidence', 'Impasse', 'Quartier',
  ];
  Timer? _timer;
  static const List<String> _streetNames = [
    'des Martyrs', 'de l\'Indépendance', 'Larbi Ben M\'hidi',
    'Didouche Mourad', 'des Frères Bouadou', 'AADL',
    'des Oliviers', 'Ben Boulaid', 'du 1er Novembre',
    'Hassiba Ben Bouali', 'de la Paix', 'des Roses',
    'du Progrès', 'Mohamed V', 'de la République',
  ];

  @override
  void initState() {
    super.initState();
    _loadPending();
    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadPending());
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  DateTime? _lastPendingFetch;
  Future<void> _loadPending() async {
    final now = DateTime.now();
    if (_lastPendingFetch != null &&
        now.difference(_lastPendingFetch!) < const Duration(seconds: 18)) {
      return;
    }
    _lastPendingFetch = now;

    try {
      final result = await ApiService.getPendingCommandes();
      if (!mounted) return;

      // Add debug log so you can see what's coming back
      debugPrint('[ORDERS] getPendingCommandes returned ${result.length} items');
      for (final e in result) {
        debugPrint('  → id=${e['_id'] ?? e['id']}  status=${e['status']}  client=${e['client']}');
      }

      if (result.isEmpty) return;

      setState(() {
        for (final e in result) {
          final id = (e['_id'] ?? e['id'] ?? '').toString();

          // Skip if already exists with a non-pending status (accepted/refused)
          final existing = orders.firstWhere(
                (o) => o['id'] == id,
            orElse: () => {},
          );
          if (existing.isNotEmpty && existing['status'] != 'pending') continue;

          final capacite  = (e['capacite'] as num?)?.toDouble() ?? 0.0;
          final prix      = (e['prix'] as num?)?.toDouble() ?? 0.0;
          final rawStatus = (e['status'] ?? 'en attente').toString();
          final client    = e['client'];

          String clientName = 'Client';
          if (client is Map) {
            final nom    = client['nom']    ?? '';
            final prenom = client['prenom'] ?? '';
            clientName   = '$nom $prenom'.trim();
            if (clientName.isEmpty) clientName = client['email'] ?? 'Client';
          }

          final posMap      = e['position'];
          final double? lat = (posMap?['lat'] as num?)?.toDouble();
          final double? lon = (posMap?['lon'] as num?)?.toDouble();

          final newOrder = {
            'id':         id,
            'clientName': clientName,
            'address':    e['adresse'] ?? e['address'] ?? e['wilaya'] ?? 'Adresse non renseignée',
            'quantity':   capacite,
            'price':      prix > 0 ? prix : capacite * 1.5,
            'distance':   0.0,
            'duration':   0,
            'status':     'pending',
            'rawStatus':  rawStatus,
            'lat':        lat,
            'lon':        lon,
          };

          if (existing.isEmpty) {
            // Brand new order — add it
            orders = [...orders, newOrder];
          } else {
            // Exists as pending — update it in place
            final idx = orders.indexWhere((o) => o['id'] == id);
            if (idx != -1) orders[idx] = newOrder;
          }
        }
      });
    } catch (e) {
      debugPrint('[ORDERS] _loadPending error: $e');
    }
  }

  // ── GENERATE random orders ────────────────────────────────────
  void _generateRandomOrders() {
    final int nbChauffeurs = 5 + Random().nextInt(3); // 5–7 fake drivers
    final rng   = Random();
    final count = 60 + rng.nextInt(11); // 20–30 orders
    final newOrders = <Map<String, dynamic>>[];

    final existing = orders.where((o) => o['status'] != 'pending').toList();

    for (int i = 0; i < count; i++) {
      final city      = _algerianCities[rng.nextInt(_algerianCities.length)];
      final street    = '${_streetTypes[rng.nextInt(_streetTypes.length)]} '
          '${_streetNames[rng.nextInt(_streetNames.length)]}';
      final firstName = _firstNames[rng.nextInt(_firstNames.length)];
      final lastName  = _lastNames[rng.nextInt(_lastNames.length)];

      final latJitter = (rng.nextDouble() - 0.5) * 0.02;
      final lonJitter = (rng.nextDouble() - 0.5) * 0.02;

      final quantity = (200 + rng.nextInt(801)).toDouble(); // 200–1000L, more varied
      final distance = double.parse(
          (1.0 + rng.nextDouble() * 29).toStringAsFixed(1));
      final duration = (distance * 3).round() + rng.nextInt(10);

      newOrders.add({
        'id':         'gen_${DateTime.now().millisecondsSinceEpoch}_$i',
        'clientName': '$firstName $lastName',
        'address':    '$street, ${city['city']}',
        'quantity':   quantity,
        'price':      double.parse((quantity * 1.5).toStringAsFixed(0)),
        'distance':   distance,
        'duration':   duration,
        'status':     'pending',
        'rawStatus':  'en attente',
        'lat':        (city['lat'] as double) + latJitter,
        'lon':        (city['lon'] as double) + lonJitter,
        'demand':   quantity,
        'gain':     quantity * 2,
      });
    }

    setState(() {
      orders = [...existing, ...newOrders];
      selectedFilter = 'En attente';

    });
    widget.onOrdersRegenerated?.call();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ ${newOrders.length} commandes générées — optimisation en cours...'),
      backgroundColor: const Color(0xFF1E3A8A),
      duration: const Duration(seconds: 6),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _triggerOptimizationPreview();
    });
  }

  // ── Send all pending orders to the map for route preview ──────
  void _triggerOptimizationPreview() {
    final pendingOrders = orders.where((o) => o['status'] == 'pending').toList();
    if (pendingOrders.isEmpty) return;

    final rng          = Random();
    final nbChauffeurs = 2 + rng.nextInt(3); // 2–4 random drivers

    final providerState =
    context.findAncestorStateOfType<ProviderHomeScreenState>();

    if (providerState != null) {
      providerState.previewRouteForOrders(
        pendingOrders,
        nbVehicules: nbChauffeurs, // ← pass here
      );
    }
  }

  // ── ACCEPT ALL pending orders ─────────────────────────────────
  Future<void> _acceptAllOrders() async {
    final pending = orders.where((o) => o['status'] == 'pending').toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune commande en attente'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tout accepter'),
        content: Text('Accepter les ${pending.length} commandes en attente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _acceptingAll = true);

    for (final order in pending) {
      if (!mounted) break;
      await _acceptOrderSilent(order['id']);
      await Future.delayed(const Duration(milliseconds: 80));
    }

    if (mounted) {
      setState(() => _acceptingAll = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${pending.length} commandes acceptées'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ));

      // Recompute route for all accepted orders, then switch to map tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final providerState =
        context.findAncestorStateOfType<ProviderHomeScreenState>();
        if (providerState != null) {
          final acceptedOrders =
          orders.where((o) => o['status'] == 'accepted').toList();
          providerState.previewRouteForOrders(acceptedOrders);
          providerState.switchToMapTab();
        }
      });
    }
  }

  // Silent version (no navigation) used by accept-all
  Future<void> _acceptOrderSilent(String orderId) async {
    setState(() {
      final idx = orders.indexWhere((o) => o['id'] == orderId);
      if (idx != -1) {
        orders[idx]['status']    = 'accepted';
        orders[idx]['rawStatus'] = 'en livraison';
      }
    });

    if (!orderId.startsWith('test_') && !orderId.startsWith('gen_')) {
      try {
        await ApiService.acceptCommande(orderId);
      } catch (_) {}
    }
  }

  // ── REAL load from backend ────────────────────────────────────
  Future<void> _loadOrders() async {
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(seconds: 15)) {
      return;
    }
    _lastFetch = DateTime.now();

    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final data = await ApiService.getCommandes();
      if (!mounted) return;
      if (data.isEmpty) {
        setState(() {
          orders   = [];
          _loading = false;
        });
        return;
      }
      setState(() {
        orders = data.map<Map<String, dynamic>>((e) {
          final id        = (e['_id'] ?? e['id'] ?? '').toString();
          final capacite  = (e['capacite'] as num?)?.toDouble() ?? 0.0;
          final prix      = (e['prix'] as num?)?.toDouble() ?? 0.0;
          final rawStatus = (e['status'] ?? e['statut'] ?? 'en attente').toString();
          final status    = _mapStatut(rawStatus);

          final client = e['client'];
          String clientName = 'Client';
          if (client is Map) {
            final nom    = client['nom']    ?? '';
            final prenom = client['prenom'] ?? '';
            clientName   = '$nom $prenom'.trim();
            if (clientName.isEmpty) clientName = client['email'] ?? 'Client $id';
          }

          final posMap      = e['position'];
          final double? lat = (posMap?['lat'] as num?)?.toDouble()
              ?? (e['lat'] as num?)?.toDouble();
          final double? lon = (posMap?['lon'] as num?)?.toDouble()
              ?? (e['lon'] as num?)?.toDouble();

          return {
            'id':         id,
            'clientName': clientName,
            'address':    e['adresse'] ?? e['address'] ?? 'Adresse non renseignée',
            'quantity':   capacite,
            'price':      prix > 0 ? prix : capacite * 1.5,
            'distance':   (e['distanceKm'] as num?)?.toDouble() ?? 0.0,
            'duration':   (e['durationMin'] as num?)?.toInt()   ?? 0,
            'status':     status,
            'rawStatus':  rawStatus,
            'lat':        lat,
            'lon':        lon,
          };
        }).toList();
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerOptimizationPreview();
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = 'Impossible de contacter le serveur.';
        _loading = false;
      });
    }
  }

  String _mapStatut(String statut) {
    switch (statut) {
      case 'en livraison': return 'accepted';
      case 'livrée':       return 'delivered';
      case 'annulée':      return 'refused';
      default:             return 'pending';
    }
  }

  // ── ACCEPT single ORDER ───────────────────────────────────────
  Future<void> _acceptOrder(String orderId) async {
    if (orderId.startsWith('test_') || orderId.startsWith('gen_')) {
      setState(() {
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx != -1) {
          orders[idx]['status']    = 'accepted';
          orders[idx]['rawStatus'] = 'en livraison';

        }
      });
      // Replace your updateWaterQuantity call in BOTH modes with this:
      final order = orders.firstWhere((o) => o['id'] == orderId, orElse: () => {});
      if (order.isNotEmpty) {
        final quantity = (order['quantity'] as num?)?.toDouble() ?? 0.0;
        try {
          final info    = await ApiService.getMyInfo();
          final current = (info['fournisseurInfo']?['quantiteEau'] as num?)?.toDouble() ?? 0.0;
          final newQty  = (current - quantity).clamp(0.0, double.infinity);
          await ApiService.updateWaterQuantity(quantiteEau: newQty);
          debugPrint('[WATER] $current - $quantity = $newQty');
        } catch (e) {
          debugPrint('[ORDERS] water update failed: $e');
        }
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Commande acceptée — voir l\'itinéraire sur la carte'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ));

      // Recompute route for accepted orders only, then switch to map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final providerState =
        context.findAncestorStateOfType<ProviderHomeScreenState>();
        if (providerState != null) {
          final acceptedOrders =
          orders.where((o) => o['status'] == 'accepted').toList();
          providerState.previewRouteForOrders(acceptedOrders);
          providerState.switchToMapTab();
        }
      });
      return;
    }
// REAL mode
    setState(() => _acceptingOrderId = orderId);
    try {
      final result = await ApiService.acceptCommande(orderId);

      if (result['error'] != null) { _showError(result['error']); return; }

      setState(() {
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx != -1) {
          orders[idx]['status']    = 'accepted';
          orders[idx]['rawStatus'] = 'en livraison';
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Commande acceptée'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final providerState = context.findAncestorStateOfType<ProviderHomeScreenState>();
        if (providerState != null) {
          providerState.reloadRealRoutes();
          providerState.switchToMapTab();
        }
      });

      // ← DELETE everything after this line until the catch block
    } catch (e) {
      _showError('Erreur réseau: $e');
    } finally {
      if (mounted) setState(() => _acceptingOrderId = null);
    }
  }

  // ── REFUSE ORDER ──────────────────────────────────────────────
  Future<void> _refuseOrder(String orderId) async {
    if (orderId.startsWith('test_') || orderId.startsWith('gen_')) {
      setState(() {
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx != -1) orders[idx]['status'] = 'refused';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('[TEST] Commande refusée'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ));
      }

      // Re-preview with remaining accepted orders, or fall back to pending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final providerState =
        context.findAncestorStateOfType<ProviderHomeScreenState>();
        if (providerState != null) {
          final acceptedOrders =
          orders.where((o) => o['status'] == 'accepted').toList();
          if (acceptedOrders.isNotEmpty) {
            providerState.previewRouteForOrders(acceptedOrders);
          } else {
            // No accepted orders left — re-preview the pending ones
            _triggerOptimizationPreview();
          }
        }
      });
      return;
    }

    // REAL mode
    try {
      final result = await ApiService.cancelCommande(orderId);
      final errorMsg = result['error'] ??
          (result['msg'] != null &&
              result['msg'] != 'Commande annulée avec succès'
              ? result['msg']
              : null);

      if (errorMsg != null) { _showError(errorMsg); return; }

      setState(() {
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx != -1) orders[idx]['status'] = 'refused';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Commande refusée'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }

      // Re-preview with remaining accepted orders, or fall back to pending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final providerState =
        context.findAncestorStateOfType<ProviderHomeScreenState>();
        if (providerState != null) {
          final acceptedOrders =
          orders.where((o) => o['status'] == 'accepted').toList();
          if (acceptedOrders.isNotEmpty) {
            providerState.previewRouteForOrders(acceptedOrders);
          } else {
            _triggerOptimizationPreview();
          }
        }
      });
    } catch (e) {
      _showError('Erreur réseau: $e');
    }
  }

  Future<void> _runOptimization() async {
    setState(() => _loading = true);
    try {
      final initResult = await ApiService.initGraph();
      if (initResult['error'] != null) {
        _showError('Erreur init graphe: ${initResult['error']}');
        return;
      }
      final result = await ApiService.optimize();
      if (result['error'] != null) { _showError('Erreur: ${result['error']}'); return; }

      final dist  = (result['distance_totale_km'] as num?)?.toStringAsFixed(1) ?? '?';
      final valid = result['valide'] as bool? ?? false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ NSGA-II — $dist km${valid ? "" : " (invalide)"}'),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      _showError('Erreur optimisation: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedFilter == 'Toutes')     return orders;
    if (selectedFilter == 'En attente') return orders.where((o) => o['status'] == 'pending').toList();
    if (selectedFilter == 'Acceptées')  return orders.where((o) => o['status'] == 'accepted').toList();
    if (selectedFilter == 'Livrées')    return orders.where((o) => o['status'] == 'delivered').toList();
    if (selectedFilter == 'Annulées')   return orders.where((o) => o['status'] == 'refused').toList();
    return orders;
  }

  int get _pendingCount => orders.where((o) => o['status'] == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Commandes'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadOrders,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.alt_route),
            onPressed: _loading ? null : _runOptimization,
            tooltip: 'NSGA-II Optimiser',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.warning, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.deepOrange, fontSize: 13))),
                TextButton(onPressed: _loadOrders, child: const Text('Réessayer')),
              ]),
            ),

          if (_loading || _acceptingAll)
            LinearProgressIndicator(
              backgroundColor: const Color(0xFFBBDEFB),
              color: _acceptingAll ? Colors.green : const Color(0xFF1E3A8A),
            ),

          // ── Action buttons bar ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_loading || _acceptingAll) ? null : _generateRandomOrders,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Générer', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_loading || _acceptingAll || _pendingCount == 0)
                      ? null
                      : _acceptAllOrders,
                  icon: _acceptingAll
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.done_all, size: 18),
                  label: Text(
                    _acceptingAll
                        ? 'En cours...'
                        : 'Tout accepter ($_pendingCount)',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),

          // ── Filter chips ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _buildFilterChip('Toutes'),
                const SizedBox(width: 5),
                _buildFilterChip('En attente'),
                const SizedBox(width: 5),
                _buildFilterChip('Acceptées'),
                const SizedBox(width: 5),
                _buildFilterChip('Livrées'),
                const SizedBox(width: 5),
                _buildFilterChip('Annulées'),
              ]),
            ),
          ),

          // ── Summary badges ────────────────────────────────────
          if (orders.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryBadge('En attente',
                      orders.where((o) => o['status'] == 'pending').length,
                      Colors.orange),
                  _buildSummaryBadge('Acceptées',
                      orders.where((o) => o['status'] == 'accepted').length,
                      Colors.green),
                  _buildSummaryBadge('Livrées',
                      orders.where((o) => o['status'] == 'delivered').length,
                      Colors.blue),
                  _buildSummaryBadge('Annulées',
                      orders.where((o) => o['status'] == 'refused').length,
                      Colors.red),
                ],
              ),
            ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: filteredOrders.isEmpty && !_loading
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(filteredOrders[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String label, int count, Color color) {
    return Column(children: [
      Text('$count',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isPending   = order['status'] == 'pending';
    final isAccepted  = order['status'] == 'accepted';
    final isDelivered = order['status'] == 'delivered';
    final isRefused   = order['status'] == 'refused';
    final isAccepting = _acceptingOrderId == order['id'];

    Color    statusColor = Colors.orange;
    String   statusLabel = 'En attente';
    IconData statusIcon  = Icons.hourglass_empty;

    if (isAccepted)  { statusColor = Colors.green; statusLabel = 'Acceptée';  statusIcon = Icons.check_circle; }
    if (isDelivered) { statusColor = Colors.blue;  statusLabel = 'Livrée';    statusIcon = Icons.done_all; }
    if (isRefused)   { statusColor = Colors.red;   statusLabel = 'Annulée';   statusIcon = Icons.cancel; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.person, color: Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              Text(order['clientName'],
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),

          Row(children: [
            Icon(Icons.location_on, color: Colors.red[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(order['address'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
          ]),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _buildInfoChip(Icons.water_drop, '${order['quantity']} L', Colors.blue),
              const SizedBox(width: 6),
              _buildInfoChip(Icons.route, '${order['distance']} km', Colors.orange),
              const SizedBox(width: 6),
              _buildInfoChip(Icons.timer, '${order['duration']} min', Colors.purple),
              const SizedBox(width: 6),
              _buildInfoChip(Icons.payments, '${order['price']} DA', Colors.green),
            ]),
          ),

          if (isPending) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.map_outlined, size: 14, color: Colors.indigo[300]),
              const SizedBox(width: 4),
              Text(
                'Itinéraire optimisé disponible sur la carte',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.indigo[300],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
          ],

          if (isPending) ...[
            const SizedBox(height: 12),
            if (isAccepting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Traitement en cours...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
              )
            else
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acceptingAll ? null : () => _acceptOrder(order['id']),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acceptingAll ? null : () => _refuseOrder(order['id']),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
              ]),
          ],
        ]),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Aucune commande',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text('Les nouvelles demandes apparaîtront ici',
            style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _generateRandomOrders,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Générer des commandes test'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}