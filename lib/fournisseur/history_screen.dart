import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ Add your correct import path

class HistoryScreen extends StatefulWidget {
  final String? chauffeurId;
  const HistoryScreen({Key? key, this.chauffeurId}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoadingDeliveries = false;

  String? _apiError;
  String selectedPeriod = 'Jour';

  // ── Hardcoded stats (untouched) ─────────────────────────────────
  final Map<String, Map<String, dynamic>> stats = {
    'Jour':    {'revenue': 15500,  'deliveries': 6,   'totalLiters': 12000},
    'Semaine': {'revenue': 87000,  'deliveries': 34,  'totalLiters': 68000},
    'Mois':    {'revenue': 345000, 'deliveries': 142, 'totalLiters': 284000},
  };

  // ── Hardcoded deliveries (untouched, renamed) ───────────────────
  final List<Map<String, dynamic>> _hardcodedDeliveries = [
    {
      'id': '1', 'date': 'Aujourd\'hui', 'time': '14:30',
      'from': 'Hydra', 'to': 'Bab Ezzouar',
      'quantity': 2000, 'price': 3500, 'status': 'completed',
    },
    {
      'id': '2', 'date': 'Aujourd\'hui', 'time': '11:15',
      'from': 'Centre-ville', 'to': 'Kouba',
      'quantity': 1500, 'price': 2800, 'status': 'completed',
    },
    {
      'id': '3', 'date': 'Aujourd\'hui', 'time': '09:00',
      'from': 'Alger Centre', 'to': 'Rouiba',
      'quantity': 2500, 'price': 4200, 'status': 'completed',
    },
    {
      'id': '4', 'date': 'Hier', 'time': '16:45',
      'from': 'Birkhadem', 'to': 'El Biar',
      'quantity': 3000, 'price': 5200, 'status': 'completed',
    },
    {
      'id': '5', 'date': 'Hier', 'time': '13:20',
      'from': 'Ain Benian', 'to': 'Cheraga',
      'quantity': 1800, 'price': 3100, 'status': 'completed',
    },
  ];

  // ── API deliveries ──────────────────────────────────────────────
  List<Map<String, dynamic>> _apiDeliveries = [];

  // ── Merged getter ───────────────────────────────────────────────
  List<Map<String, dynamic>> get deliveries => [
    ..._hardcodedDeliveries,
    ..._apiDeliveries,
  ];

  Map<String, dynamic> get currentStats => stats[selectedPeriod]!;

  // ── Lifecycle ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadDeliveredCommands(); // ✅ Correctly called here, defined below
  }

  // ── API fetch (now a proper class method, NOT inside initState) ──
  Future<void> _loadDeliveredCommands() async {
    setState(() {
      _isLoadingDeliveries = true;
      _apiError = null;

    });

    try {
      final result = await ApiService.getCommandesByStatus(
        'livrée',
        chauffeurId: widget.chauffeurId,
      );
      if (result['error'] != null) {
        setState(() {
          _apiError = result['error'];
          _isLoadingDeliveries = false;
        });
        return;
      }

      final List<dynamic> rawList = result['data'] ?? [];

      final List<Map<String, dynamic>> mapped = rawList.map((cmd) {
        String dateLabel = '';
        String timeLabel = '';
        try {
          final dt = DateTime.parse(cmd['createdAt'].toString()).toLocal();
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));

          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            dateLabel = 'Aujourd\'hui';
          } else if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
            dateLabel = 'Hier';
          } else {
            dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          }
          timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}

        // ✅ Correct field names matching your backend (addCommande uses these)
        return {
          'id':       (cmd['_id'] ?? cmd['id'])?.toString() ?? '',
          'date':     dateLabel,
          'time':     timeLabel,
          'from':     cmd['wilaya']   ?? cmd['adresse'] ?? '—',  // ✅ wilaya is stored
          'to':       cmd['adresse']  ?? '—',
          'quantity': (cmd['capacite'] as num?)?.toInt() ?? 0,   // ✅ your field is 'capacite'
          'price':    (cmd['prix'] as num?)?.toInt()     ?? 0,   // ✅ your field is 'prix'
          'status':   'completed',
        };
      }).toList();

      setState(() {
        _apiDeliveries = mapped;
        _isLoadingDeliveries = false;
      });

    } catch (e) {
      setState(() {
        _apiError = e.toString();
        _isLoadingDeliveries = false;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historique'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeliveredCommands, // ✅ Wired to real fetch
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildPeriodFilters(isDark),
            const SizedBox(height: 16),

            // ✅ Loading indicator
            if (_isLoadingDeliveries)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ✅ Error message
            if (_apiError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Erreur API : $_apiError',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 8),
            _buildDeliveriesList(theme, isDark),
          ],
        ),
      ),
    );
  }

  // ── Widgets (all unchanged below) ──────────────────────────────
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
          BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statistiques du $selectedPeriod',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.payments, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenus', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${currentStats['revenue']} DA',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem(icon: Icons.local_shipping, label: 'Livraisons', value: '${currentStats['deliveries']}')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem(icon: Icons.water_drop, label: 'Total', value: '${currentStats['totalLiters']} L')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        onTap: () => setState(() => selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : isDark ? Colors.white12 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : isDark ? Colors.white24 : Colors.grey[300]!),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(delivery['date'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ),
            _buildDeliveryCard(delivery, theme, isDark),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, color: Colors.green[600], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(delivery['time'],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Terminée',
                          style: TextStyle(color: Colors.green[isDark ? 300 : 700], fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${delivery['from']} → ${delivery['to']}',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 16, color: Colors.blue[isDark ? 300 : 600]),
                    const SizedBox(width: 4),
                    Text('${delivery['quantity']} L',
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                    const SizedBox(width: 16),
                    Icon(Icons.payments, size: 16, color: Colors.green[isDark ? 300 : 600]),
                    const SizedBox(width: 4),
                    Text('${delivery['price']} DA',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
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