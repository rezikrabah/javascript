import 'package:flutter/material.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────
//  MODÈLES
// ─────────────────────────────────────────
enum NiveauPenurie { legere, moderee, grave }

extension NiveauInfo on NiveauPenurie {
  String get label {
    switch (this) {
      case NiveauPenurie.legere:
        return 'Légère';
      case NiveauPenurie.moderee:
        return 'Modérée';
      case NiveauPenurie.grave:
        return 'Grave';
    }
  }

  Color get couleur {
    switch (this) {
      case NiveauPenurie.legere:
        return const Color(0xFF639922);
      case NiveauPenurie.moderee:
        return const Color(0xFFBA7517);
      case NiveauPenurie.grave:
        return const Color(0xFFA32D2D);
    }
  }

  Color get couleurFond {
    switch (this) {
      case NiveauPenurie.legere:
        return const Color(0xFFEAF3DE);
      case NiveauPenurie.moderee:
        return const Color(0xFFFAEEDA);
      case NiveauPenurie.grave:
        return const Color(0xFFFCEBEB);
    }
  }
}

class SignalementInfo {
  final String quartier;
  final String commune;
  final NiveauPenurie niveau;
  final int dureeNombre;
  final String dureeUnite;
  final String commentaire;
  final DateTime dateSignalement;
  final bool isNew;
  final int nbCommandes;

  const SignalementInfo({
    required this.quartier,
    required this.commune,
    required this.niveau,
    required this.dureeNombre,
    required this.dureeUnite,
    required this.commentaire,
    required this.dateSignalement,
    this.isNew = false,
    this.nbCommandes = 0,
  });
}

// ─────────────────────────────────────────
//  ÉCRAN CONDUCTEUR
// ─────────────────────────────────────────
class ConducteurInfoScreen extends StatefulWidget {
  const ConducteurInfoScreen({super.key});

  @override
  State<ConducteurInfoScreen> createState() => _ConducteurInfoScreenState();
}

class _ConducteurInfoScreenState extends State<ConducteurInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _communes = [
    'Toutes',
    '01 - Adrar', '02 - Chlef', '03 - Laghouat', '04 - Oum El Bouaghi',
    '05 - Batna', '06 - Béjaïa', '07 - Biskra', '08 - Béchar',
    '09 - Blida', '10 - Bouira', '11 - Tamanrasset', '12 - Tébessa',
    '13 - Tlemcen', '14 - Tiaret', '15 - Tizi Ouzou', '16 - Alger',
    '17 - Djelfa', '18 - Jijel', '19 - Sétif', '20 - Saïda',
    '21 - Skikda', '22 - Sidi Bel Abbès', '23 - Annaba', '24 - Guelma',
    '25 - Constantine', '26 - Médéa', '27 - Mostaganem', '28 - M\'Sila',
    '29 - Mascara', '30 - Ouargla', '31 - Oran', '32 - El Bayadh',
    '33 - Illizi', '34 - Bordj Bou Arréridj', '35 - Boumerdès', '36 - El Tarf',
    '37 - Tindouf', '38 - Tissemsilt', '39 - El Oued', '40 - Khenchela',
    '41 - Souk Ahras', '42 - Tipaza', '43 - Mila', '44 - Aïn Defla',
    '45 - Naâma', '46 - Aïn Témouchent', '47 - Ghardaïa', '48 - Relizane',
    '49 - Timimoun', '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal',
    '52 - Béni Abbès', '53 - In Salah', '54 - In Guezzam', '55 - Touggourt',
    '56 - Djanet', '57 - El M\'Ghair', '58 - El Meniaa',
  ];
  // Filtres
  String _filtreCommune = 'Toutes';
  NiveauPenurie? _filtreNiveau;
  String _filtreDate = 'Toutes';

  List<SignalementInfo> _signalements = [];
  bool _loading = true;

  final List<String> _dates = [
    'Toutes',
    'Dernière heure',
    'Aujourd\'hui',
    'Cette semaine',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    setState(() => _loading = true);

    Duration? depuis;
    if (_filtreDate == 'Dernière heure') depuis = const Duration(hours: 1);
    if (_filtreDate == 'Aujourd\'hui')   depuis = const Duration(hours: 24);
    if (_filtreDate == 'Cette semaine')  depuis = const Duration(days: 7);

    final raw = await ApiService.getSignalements(
      commune: _filtreCommune,
      niveau:  _filtreNiveau?.name,
      depuis:  depuis,
    );
    print('[SIGNALEMENTS] count: ${raw.length}');
    if (raw.isNotEmpty) print('[SIGNALEMENTS] first item: ${raw.first}');
    setState(() {
      _signalements = raw.map((json) => SignalementInfo(
        quartier:        json['quartier']    ?? '',
        commune:         json['commune']     ?? '',
        niveau:          _parseNiveau(json['niveau']),
        dureeNombre:     (json['dureeNombre'] as num?)?.toInt() ?? 1,
        dureeUnite:      json['dureeUnite']  ?? 'jours',
        commentaire:     json['commentaire'] ?? '',
        dateSignalement: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        isNew: DateTime.now().difference(
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now()
        ).inMinutes < 30,
        nbCommandes: (json['nbCommandes'] as num?)?.toInt() ?? 0,
      )).toList();
      _loading = false;
    });
  }

  NiveauPenurie _parseNiveau(String? s) {
    switch (s) {
      case 'moderee': return NiveauPenurie.moderee;
      case 'grave':   return NiveauPenurie.grave;
      default:        return NiveauPenurie.legere;
    }
  }

  // Use _signalements instead of _donneesFactices everywhere:
  List<SignalementInfo> get _signalementsFiltres => _signalements;
  int get _totalAlertes    => _signalements.length;
  int get _nouvellesAlertes => _signalements.where((s) => s.isNew).length;
  int get _totalCommandes  => _signalements.fold(0, (sum, s) => sum + s.nbCommandes);
  List<SignalementInfo> get _zonesTriees {
    final list = List<SignalementInfo>.from(_signalements);
    list.sort((a, b) => b.nbCommandes.compareTo(a.nbCommandes));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.local_shipping_outlined,
            color: Color(0xFF053981)),
        title: const Text(
          'Tableau de bord – Info',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_nouvellesAlertes > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA32D2D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_nouvellesAlertes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(color: const Color(0xFFE0E0E0), height: 0.5),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF185FA5),
                labelColor: const Color(0xFF185FA5),
                unselectedLabelColor: const Color(0xFF888888),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Signalements'),
                  Tab(text: 'Statistiques'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabController, children: [
        _buildSignalements(),
        _buildStatistiques(),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSignalements,
        backgroundColor: const Color(0xFF185FA5),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  // ── ONGLET SIGNALEMENTS ──────────────────
  Widget _buildSignalements() {
    final liste = _signalementsFiltres;
    return Column(
      children: [
        _buildFiltres(),
        Expanded(
          child: liste.isEmpty
              ? _buildEmpty()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: liste.length,
            itemBuilder: (_, i) => _SignalementCard(
              signalement: liste[i],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTRES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FiltreDropdown(
                  label: 'Commune',
                  value: _filtreCommune,
                  items: _communes,
                  onChanged: (v) {
                    setState(() => _filtreCommune = v!);
                    _loadSignalements();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FiltreDropdown(
                  label: 'Date',
                  value: _filtreDate,
                  items: _dates,
                  onChanged: (v) {
                    setState(() => _filtreDate = v!);
                    _loadSignalements();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FiltreChip(
                label: 'Tous',
                selected: _filtreNiveau == null,
                onTap: () {
                  setState(() => _filtreNiveau = null);
                  _loadSignalements();
                },
                color: const Color(0xFF444444),
                colorFond: const Color(0xFFF0F0F0),
              ),
              const SizedBox(width: 6),
              ...NiveauPenurie.values.map(
                    (n) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FiltreChip(
                    label: n.label,
                    selected: _filtreNiveau == n,
                    onTap: () {
                      setState(() => _filtreNiveau = n);
                      _loadSignalements();
                    },
                    color: n.couleur,
                    colorFond: n.couleurFond,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'Aucun signalement',
            style: TextStyle(color: Color(0xFF888888), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiques() {
    if (_signalements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'Aucun signalement reçu',
              style: TextStyle(color: Color(0xFF888888), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Signalements',
                value: '$_totalAlertes',
                icon: Icons.report_outlined,
                color: const Color(0xFF185FA5),
                colorFond: const Color(0xFFE6F1FB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Nouvelles alertes',
                value: '$_nouvellesAlertes',
                icon: Icons.new_releases_outlined,
                color: const Color(0xFFA32D2D),
                colorFond: const Color(0xFFFCEBEB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Commandes',
                value: '$_totalCommandes',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF0F6E56),
                colorFond: const Color(0xFFE1F5EE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Répartition par niveau'),
        const SizedBox(height: 8),
        _buildRepartitionNiveaux(),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Zones les plus demandées'),
        const SizedBox(height: 8),
        _buildZonesClassement(),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Alertes récentes'),
        const SizedBox(height: 8),

        // ── FIXED: use _signalements not _donneesFactices ──
        ..._signalements
            .where((s) => s.isNew)
            .map((s) => _AlerteRecente(signalement: s)),

        if (_signalements.where((s) => s.isNew).isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucune alerte récente',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRepartitionNiveaux() {
    // ── FIXED: use _signalements not _donneesFactices ──
    final total = _signalements.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: NiveauPenurie.values.map((n) {
          final count = _signalements.where((s) => s.niveau == n).length;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: n.couleur,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    n.label,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation(n.couleur),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: n.couleur,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildZonesClassement() {
    final zones = _zonesTriees;
    if (zones.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
        ),
      );
    }
    final max = zones.first.nbCommandes;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Column(
        children: zones.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final pct = max > 0 ? s.nbCommandes / max : 0.0;
          final isLast = i == zones.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                  bottom: BorderSide(
                      color: Color(0xFFF0F0F0), width: 0.5)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == 0
                          ? const Color(0xFFA32D2D)
                          : const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.quartier,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        s.commune,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.nbCommandes} cmd',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF185FA5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE6F1FB),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF185FA5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGETS RÉUTILISABLES
class _SignalementCard extends StatelessWidget {
  final SignalementInfo signalement;

  const _SignalementCard({required this.signalement});

  String _formatTemps(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final s = signalement;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias, // ← clips the inner accent to the radius
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Colored left accent bar ──
            Container(
              width: 4,
              color: s.niveau.couleur,
            ),
            // ── Card content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                s.quartier,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (s.isNew)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEBEB),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Nouveau',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFA32D2D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.niveau.couleurFond,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.niveau.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: s.niveau.couleur,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text(
                          s.commune,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888)),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time_outlined,
                            size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text(
                          _formatTemps(s.dateSignalement),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop_outlined,
                              size: 13, color: Color(0xFF185FA5)),
                          const SizedBox(width: 5),
                          Text(
                            'Sans eau depuis : ${s.dureeNombre} ${s.dureeUnite}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF185FA5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (s.commentaire.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        s.commentaire,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color colorFond;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorFond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorFond,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FiltreDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FiltreDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1A1A)),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color colorFond;

  const _FiltreChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.colorFond,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colorFond : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _AlerteRecente extends StatelessWidget {
  final SignalementInfo signalement;
  const _AlerteRecente({required this.signalement});

  @override
  Widget build(BuildContext context) {
    final s = signalement;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias, // ← key fix
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Colored left accent ──
            Container(width: 3, color: s.niveau.couleur),
            const SizedBox(width: 10),
            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.quartier} — ${s.commune}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.niveau.couleurFond,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.niveau.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: s.niveau.couleur,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}