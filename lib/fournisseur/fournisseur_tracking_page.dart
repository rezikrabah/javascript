import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ ApiService import

class FournisseurOrdersPage extends StatefulWidget {
  final int fournisseurId;
  const FournisseurOrdersPage({super.key, required this.fournisseurId});

  @override
  State<FournisseurOrdersPage> createState() => _FournisseurOrdersPageState();
}

class _FournisseurOrdersPageState extends State<FournisseurOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 15), (_) => _fetchOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ✅ Use ApiService.getAllCommandes() instead of raw http
  Future<void> _fetchOrders() async {
    try {
      final data = await ApiService.getCommandes();

      setState(() {
        _orders = data.map<Map<String, dynamic>>((e) {
          final id      = (e['_id'] ?? e['id'] ?? '').toString();
          final status  = e['status'] ?? e['statut'] ?? 'en attente';
          final client  = e['client'];

          String clientName = 'Client';
          if (client is Map) {
            final nom    = client['nom']    ?? '';
            final prenom = client['prenom'] ?? '';
            clientName   = '$prenom $nom'.trim();
            if (clientName.isEmpty) clientName = client['email'] ?? 'Client';
          }

          return {
            'id':         id,
            'clientName': clientName,
            'statut':     status,
            'quantity':   (e['capacite'] as num?)?.toDouble() ?? 0.0,
            'prix':       (e['prix'] as num?)?.toDouble() ?? 0.0,
            'address':    e['adresse'] ?? 'Adresse non renseignée',
            'chauffeur':  e['chauffeur'],
          };
        }).toList();
        _loading = false;
        _error   = null;
      });
    } catch (e) {
      setState(() { _error = 'Connexion impossible'; _loading = false; });
    }
  }

  // ✅ Accept = assign first available chauffeur
  Future<void> _acceptOrder(String orderId) async {
    try {
      final chauffeurs = await ApiService.getMyChauffeurs();

      if (chauffeurs.isEmpty) {
        _showSnack('Aucun chauffeur disponible.', Colors.red);
        return;
      }

      final available = chauffeurs.where((c) =>
      c['disponible'] == true || c['disponible'] == 1).toList();

      if (available.isEmpty) {
        _showSnack('Tous vos chauffeurs sont occupés.', Colors.red);
        return;
      }

      final chauffeurId = (available.first['_id'] ?? available.first['id']).toString();

      final result = await ApiService.assignCommande(
        commandeId: orderId,
        chauffeurId: chauffeurId,
      );

      if (result['error'] != null) {
        _showSnack(result['error'], Colors.red);
      } else {
        _showSnack('✅ Commande acceptée — chauffeur assigné', Colors.green);
        _fetchOrders();
      }
    } catch (e) {
      _showSnack('Erreur réseau', Colors.red);
    }
  }

  // ✅ Refuse = cancel commande
  Future<void> _refuseOrder(String orderId) async {
    try {
      final result = await ApiService.cancelCommande(orderId);
      if (result['error'] != null) {
        _showSnack(result['error'], Colors.red);
      } else {
        _showSnack('❌ Commande refusée', Colors.red);
        _fetchOrders();
      }
    } catch (e) {
      _showSnack('Erreur réseau', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _statusColor(String statut) {
    switch (statut) {
      case 'en attente':   return Colors.orange;
      case 'en livraison': return const Color(0xFF9C27B0);
      case 'livrée':       return Colors.green;
      case 'annulée':      return Colors.red;
      default:             return Colors.grey;
    }
  }

  String _statusLabel(String statut) {
    switch (statut) {
      case 'en attente':   return 'En attente';
      case 'en livraison': return 'En livraison';
      case 'livrée':       return 'Livrée';
      case 'annulée':      return 'Annulée';
      default:             return statut;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final enAttente = _orders.where((o) => o['statut'] == 'en attente').toList();
    final autres    = _orders.where((o) => o['statut'] != 'en attente').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes reçues'),
        backgroundColor: const Color(0xFF0B3C49),
        foregroundColor: Colors.white,
        actions: [
          if (enAttente.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${enAttente.length} nouvelle(s)',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(_error!),
        TextButton(onPressed: _fetchOrders, child: const Text('Réessayer')),
      ]))
          : _orders.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text('Aucune commande pour l\'instant',
            style: TextStyle(color: Colors.grey)),
      ]))
          : RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (enAttente.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                child: Text('À traiter',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 13, color: Colors.orange)),
              ),
              ...enAttente.map((o) => _buildCard(o)),
              const SizedBox(height: 16),
            ],
            if (autres.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Historique',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 13, color: Colors.grey)),
              ),
              ...autres.map((o) => _buildCard(o)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> order) {
    final statut = order['statut'] as String;
    final color  = _statusColor(statut);
    final isPending = statut == 'en attente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.person, color: Color(0xFF0B3C49), size: 18),
              const SizedBox(width: 6),
              Text(order['clientName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(statut),
                  style: TextStyle(color: color,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),

          // Info
          Row(children: [
            const Icon(Icons.water_drop, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Text('${order['quantity']} L',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 16),
            const Icon(Icons.payments, color: Colors.green, size: 16),
            const SizedBox(width: 6),
            Text('${order['prix']} DA',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(order['address'],
                style: const TextStyle(color: Colors.grey, fontSize: 12))),
          ]),

          // Chauffeur info
          if (order['chauffeur'] != null && statut == 'en livraison')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.local_shipping, size: 16, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                Text('Chauffeur assigné',
                    style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 13)),
              ]),
            ),

          // Action buttons
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => _refuseOrder(order['id']),
                child: const Text('Refuser'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C49),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => _acceptOrder(order['id']),
                child: const Text('Accepter',
                    style: TextStyle(color: Colors.white)),
              )),
            ]),
          ],
        ]),
      ),
    );
  }
}