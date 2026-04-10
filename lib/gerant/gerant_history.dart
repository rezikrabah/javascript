import 'package:flutter/material.dart';

class geranthistory extends StatefulWidget {
  const geranthistory({Key? key}) : super(key: key);

  @override
  State<geranthistory> createState() => _geranthistoryState();
}

class _geranthistoryState extends State<geranthistory> {
  String selectedPeriod = 'Jour';

  // Données simulées - À remplacer par de vraies données du backend
  final Map<String, Map<String, dynamic>> stats = {
    'Jour': {
      'revenue': 15500,
      'deliveries': 6,
      'totalLiters': 12000,

    },
    'Semaine': {
      'revenue': 87000,
      'deliveries': 34,
      'totalLiters': 68000,
    },
    'Mois': {
      'revenue': 345000,
      'deliveries': 142,
      'totalLiters': 284000,
    },
  };

  final List<Map<String, dynamic>> deliveries = [
    {
      'id': '1',
      'date': 'Aujourd\'hui',
      'time': '14:30',
      'chauffeur':' rezik rabah',
      'from': 'Hydra',
      'to': 'Bab Ezzouar',
      'quantity': 2000,
      'price': 3500,
      'status': 'completed',
    },
    {
      'id': '2',
      'date': 'Aujourd\'hui',
      'time': '11:15',
      'chauffeur':'ramzy',
      'from': 'Centre-ville',
      'to': 'Kouba',
      'quantity': 1500,
      'price': 2800,
      'status': 'completed',
    },
    {
      'id': '3',
      'date': 'Aujourd\'hui',
      'time': '09:00',
      'chauffeur':'rafik',
      'from': 'Alger Centre',
      'to': 'Rouiba',
      'quantity': 2500,
      'price': 4200,
      'status': 'completed',
    },
    {
      'id': '4',
      'date': 'Hier',
      'time': '16:45',
      'chauffeur':'wabel',
      'from': 'Birkhadem',
      'to': 'El Biar',
      'quantity': 3000,
      'price': 5200,
      'status': 'completed',
    },
    {
      'id': '5',
      'date': 'Hier',
      'time': '13:20',
      'chauffeur':'rezik rabah',
      'from': 'Ain Benian',
      'to': 'Cheraga',
      'quantity': 1800,
      'price': 3100,
      'status': 'completed',
    },
  ];

  Map<String, dynamic> get currentStats => stats[selectedPeriod]!;

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération du thème courant
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // ✅ Fond général : Theme.of(context).scaffoldBackgroundColor
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Sélecteur de date personnalisé
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Menu d'options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Rafraîchir les données
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Carte des statistiques
            _buildStatsCard(),

            const SizedBox(height: 16),

            // Filtres de période
            _buildPeriodFilters(isDark),

            const SizedBox(height: 24),

            // Liste des livraisons
            _buildDeliveriesList(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistiques du $selectedPeriod',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Revenus
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenus',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentStats['revenue']} DA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Livraisons et litres
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_shipping,
                  label: 'Livraisons',
                  value: '${currentStats['deliveries']}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.water_drop,
                  label: 'Total',
                  value: '${currentStats['totalLiters']} L',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters(bool isDark) {
    return Row(
      children: [
        _buildPeriodChip('Jour', isDark),
        const SizedBox(width: 8),
        _buildPeriodChip('Semaine', isDark),
        const SizedBox(width: 8),
        _buildPeriodChip('Mois', isDark),
      ],
    );
  }

  Widget _buildPeriodChip(String period, bool isDark) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // ✅ Barre filtres : Theme.of(context).cardColor
            // ✅ Chips non sélectionnés en sombre : Colors.white12
            color: isSelected
                ? const Color(0xFF1E3A8A)
                : isDark
                ? Colors.white12
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : isDark
                  ? Colors.white24
                  : Colors.grey[300]!,
            ),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              // ✅ Textes : Theme.of(context).colorScheme.onSurface
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white70
                  : Colors.grey[700],
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveriesList(ThemeData theme, bool isDark) {
    String? currentDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: deliveries.map((delivery) {
        final showDateHeader = currentDate != delivery['date'];
        currentDate = delivery['date'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  delivery['date'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    // ✅ Textes : Theme.of(context).colorScheme.onSurface
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            _buildDeliveryCard(delivery, theme, isDark),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryCard(
      Map<String, dynamic> delivery, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Cartes commandes : Theme.of(context).cardColor
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ✅ Badges statut en sombre : Colors.green.withOpacity(0.2)
              color: isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16,
                        // ✅ Textes secondaires : onSurface avec opacité
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      delivery['time'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        // ✅ Textes : Theme.of(context).colorScheme.onSurface
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 4,),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // ✅ Badges statut en sombre : Colors.green.withOpacity(0.2)
                        color: isDark
                            ? Colors.green.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Terminée',
                        style: TextStyle(
                          color: Colors.green[isDark ? 300 : 700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      delivery['chauffeur'] ?? 'Chauffeur inconnu',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${delivery['from']} → ${delivery['to']}',
                        style: TextStyle(
                          fontSize: 14,
                          // ✅ Textes : Theme.of(context).colorScheme.onSurface
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.water_drop,
                        size: 16, color: Colors.blue[isDark ? 300 : 600]),
                    const SizedBox(width: 4),
                    Text(
                      '${delivery['quantity']} L',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.payments,
                        size: 16, color: Colors.green[isDark ? 300 : 600]),
                    const SizedBox(width: 4),
                    Text(
                      '${delivery['price']} DA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}