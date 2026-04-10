import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test2/client/profile.dart';
import '../services/api_service.dart';
import 'clientpage.dart';
import 'commandes.dart';
import 'package:test2/client/suivi.dart';


class historique extends StatefulWidget {
  const historique({super.key});

  @override
  State<historique> createState() => _historiqueState();
}

class _historiqueState extends State<historique> {

  final List<Map<String, String>> _orders = [
    {'volume': '500L',  'date': '25 Décembre 2025',  'fournisseur': 'Ramzy Naoui',    'prix': '6000 DA'},
    {'volume': '400L',  'date': '02 Janvier 2025',   'fournisseur': 'Rezik Rabah',    'prix': '5000 DA'},
    {'volume': '200L',  'date': '02 Décembre 2024',  'fournisseur': 'Loucif Rafik',   'prix': '3000 DA'},
    {'volume': '800L',  'date': '22 Avril 2024',     'fournisseur': 'Mohammed Ali',   'prix': '7500 DA'},
    {'volume': '500L',  'date': '15 Novembre 2023',  'fournisseur': 'Hichem Khelifi', 'prix': '5500 DA'},
    {'volume': '1000L', 'date': '03 Janvier 2023',   'fournisseur': 'Islam Madani',   'prix': '8000 DA'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ✅ Fond adapté au thème
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2A34), // Garde sa couleur dans les 2 modes
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
          // ── Résumé statistiques (garde le dégradé dans les 2 modes) ──
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
                _buildStat('6', 'Commandes'),
                _buildStatDivider(),
                _buildStat('35 000 DA', 'Total dépensé'),
                _buildStatDivider(),
                _buildStat('3 400L', 'Volume total'),
              ],
            ),
          ),

          // ── Sous-titre ───────────────────────────────────
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
                    // ✅ Couleur adaptée au thème
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Liste des commandes ──────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _OrderCard(order: _orders[index], index: index),
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4ECDC4),
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => clientpage())),
        child: const Icon(CupertinoIcons.home, color: Color(0xFF081E27), size: 22),
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
      // ✅ Fond adapté au thème
      color: Theme.of(context).cardColor,
      notchMargin: 8,
      height: 75,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: CupertinoIcons.map,
            label: 'Suivi',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => suivi()),
            ),
          ),
          _NavItem(
            icon: CupertinoIcons.cube_box_fill,
            label: 'Commandes',
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => commandes( clientId: int.tryParse(ApiService.userId ?? '0') ?? 0,))),
          ),
          const SizedBox(width: 40), // Espace FAB
          _NavItem(
            icon: CupertinoIcons.clock,
            label: 'Historique',
            isActive: true,
            isDark: isDark,
            onTap: () {},
          ),
          _NavItem(
            icon: CupertinoIcons.profile_circled,
            label: 'Profil',
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => profile())),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CARTE D'UNE COMMANDE
// ================================================================
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
        // ✅ En mode sombre → garde le fond sombre de la carte
        // ✅ En mode clair → fond blanc avec bordure subtile
        color: isDark
            ? const Color(0xFF0B3C49)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4ECDC4).withOpacity(0.12)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: isDark
            ? [] // Pas d'ombre en mode sombre (le fond foncé suffit)
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icône camion
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF4ECDC4), size: 22),
          ),
          const SizedBox(width: 12),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 citerne × ${order['volume']}',
                  style: TextStyle(
                    // ✅ Blanc en mode sombre, noir en mode clair
                    color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order['date']!,
                  style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  order['fournisseur']!,
                  style: TextStyle(
                    color: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Prix + badge Payé
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['prix']!,
                style: TextStyle(
                  // ✅ Blanc en mode sombre, noir en mode clair
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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

// ================================================================
// ITEM DE NAVIGATION BAS
// ================================================================
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
    // ✅ Couleur adaptée : actif = cyan, inactif = adapté au thème
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