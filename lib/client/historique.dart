import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test2/client/profile.dart';
import '../services/api_service.dart';
import 'commandes.dart';
import 'package:test2/client/suivi.dart';

class historique extends StatefulWidget {
  const historique({super.key});

  @override
  State<historique> createState() => _historiqueState();
}

class _historiqueState extends State<historique> {
  bool _isLoading = false;
  String? _apiError;

  // ── Hardcoded examples (untouched) ──────────────────────────────
  final List<Map<String, String>> _hardcodedOrders = [
    {'volume': '500L',  'date': '25 Décembre 2025',  'fournisseur': 'Ramzy Naoui',    'prix': '6000 DA'},
    {'volume': '400L',  'date': '02 Janvier 2025',   'fournisseur': 'Rezik Rabah',    'prix': '5000 DA'},
    {'volume': '200L',  'date': '02 Décembre 2024',  'fournisseur': 'Loucif Rafik',   'prix': '3000 DA'},
    {'volume': '800L',  'date': '22 Avril 2024',     'fournisseur': 'Mohammed Ali',   'prix': '7500 DA'},
    {'volume': '500L',  'date': '15 Novembre 2023',  'fournisseur': 'Hichem Khelifi', 'prix': '5500 DA'},
    {'volume': '1000L', 'date': '03 Janvier 2023',   'fournisseur': 'Islam Madani',   'prix': '8000 DA'},
  ];

  // ── API orders fetched from backend ─────────────────────────────
  List<Map<String, String>> _apiOrders = [];

  // ── Merged list ──────────────────────────────────────────────────
  List<Map<String, String>> get _orders => [
    ..._apiOrders,       // API results first (newest)
    ..._hardcodedOrders, // then hardcoded below
  ];

  @override
  void initState() {
    super.initState();
    _loadDeliveredCommandes();
  }

  Future<void> _loadDeliveredCommandes() async {
    setState(() {
      _isLoading = true;
      _apiError = null;
    });

    try {
      // ✅ Use /my endpoint (client has access) then filter locally
      final List<dynamic> rawList = await ApiService.getMyCommandes();

      print('[historique] total commandes: ${rawList.length}');
      if (rawList.isNotEmpty) print('[historique] sample: ${rawList[0]}');

      // ✅ Filter only delivered ones (check all possible status values)
      final delivered = rawList.where((cmd) {
        final status = (cmd['status'] ?? cmd['statut'] ?? '').toString().toLowerCase();
        return status == 'livrée' ||
            status == 'livree' ||
            status == 'livrée' ||
            status == 'delivered' ||
            status == 'terminée' ||
            status == 'completed';
      }).toList();

      print('[historique] delivered: ${delivered.length}');

      final List<Map<String, String>> mapped = delivered.map<Map<String, String>>((cmd) {
        String dateLabel = '—';
        try {
          final dt = DateTime.parse(cmd['createdAt'].toString()).toLocal();
          const months = [
            '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
            'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
          ];
          dateLabel = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
        } catch (_) {}

        final capacite = (cmd['capacite'] as num?)?.toInt() ?? 0;
        final prix     = (cmd['prix']     as num?)?.toInt() ?? 0;
        final fournisseurNom =
            cmd['fournisseur']?['nom']  ??
                cmd['fournisseurNom']       ??
                cmd['chauffeur']?['nom']    ??
                'Fournisseur';

        return {
          'volume':      '${capacite}L',
          'date':        dateLabel,
          'fournisseur': fournisseurNom.toString(),
          'prix':        '$prix DA',
        };
      }).toList();

      setState(() {
        _apiOrders = mapped;
        _isLoading = false;
      });

    } catch (e) {
      print('[historique] error: $e');
      setState(() {
        _apiError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2A34),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Historique',
          style: TextStyle(color: Color(0xFFEAFBFF), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1a5a6a),
              radius: 18,
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF4ECDC4).withOpacity(0.2)),
        ),
      ),

      body: Column(
        children: [
          // ── Stats summary ──────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B3C49), Color(0xFF0D4D5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('${_orders.length}', 'Commandes'),
                _buildStatDivider(),
                _buildStat('35 000 DA', 'Total dépensé'),
                _buildStatDivider(),
                _buildStat('3 400L', 'Volume total'),
              ],
            ),
          ),

          // ── Subtitle ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(CupertinoIcons.clock_fill, size: 13, color: Color(0xFF4ECDC4)),
                const SizedBox(width: 6),
                Text(
                  'Toutes les commandes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                // ✅ Loading indicator next to title
                if (_isLoading)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4ECDC4)),
                  ),
              ],
            ),
          ),

          // ✅ API error banner
          if (_apiError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Erreur API : $_apiError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Orders list ─────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDeliveredCommandes, // ✅ Pull to refresh
              color: const Color(0xFF4ECDC4),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _OrderCard(order: _orders[index], index: index),
              ),
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomAppBar(
      color: Theme.of(context).cardColor,
      notchMargin: 8,
      height: 75,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: CupertinoIcons.map, label: 'Suivi', isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => suivi()))),
          _NavItem(icon: CupertinoIcons.cube_box_fill, label: 'Commandes', isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => commandes(clientId: int.tryParse(ApiService.userId ?? '0') ?? 0)))),
          const SizedBox(width: 40),
          _NavItem(icon: CupertinoIcons.clock, label: 'Historique', isActive: true, isDark: isDark, onTap: () {}),
          _NavItem(icon: CupertinoIcons.profile_circled, label: 'Profil', isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => profile()))),
        ],
      ),
    );
  }
}

// ── Order card (unchanged) ───────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, String> order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B3C49) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF4ECDC4).withOpacity(0.12) : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF4ECDC4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 citerne × ${order['volume']}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14, fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(order['date']!, style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  order['fournisseur']!,
                  style: TextStyle(
                    color: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade400,
                    fontSize: 10, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['prix']!,
                style: TextStyle(
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.green, size: 11),
                    SizedBox(width: 3),
                    Text('Payé', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav item (unchanged) ─────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF4ECDC4)
        : (isDark ? Colors.white54 : const Color(0xFF0B3C49).withOpacity(0.55));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}