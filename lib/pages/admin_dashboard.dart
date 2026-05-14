import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Loginpage.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveauAdmin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== TOKEN STORE ====================
// Call AdminToken.set(token) from Loginpage after login succeeds
class AdminToken {
  static String? _token;
  static void set(String t) => _token = t;
  static String? get value => _token;
  static void clear() => _token = null;
}

// ==================== ADMIN API ====================
class AdminApi {
  static const String _base = 'https://pfe-backend-nwmy.onrender.com';

  static Map<String, String> get _h => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AdminToken.value ?? ""}',
  };
  static Future<bool> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await http
          .post(Uri.parse('$_base$path'),
          headers: _h,
          body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 15));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSignalement({
    required String targetName,
    required String targetType,
    required String raison,
    String message = '',
  }) => _post('/api/admin/signalement', body: {
    'targetName': targetName,
    'targetType': targetType,
    'raison':     raison,
    'message':    message,
  });
  // ── helper: safe GET that returns List ──
  static Future<List<dynamic>> _getList(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$_base$path'), headers: _h)
          .timeout(const Duration(seconds: 15));

      debugPrint('[API] GET $path → ${r.statusCode}');
      debugPrint('[API] body: ${r.body}');  // ← add this

      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        if (body is List) return body;
        for (final key in ['data', 'users', 'chauffeurs', 'commandes',
          'reclamations', 'avis', 'logs', 'warnings']) {
          if (body[key] is List) return body[key];
        }
      }
    } catch (_) {}
    return [];
  }

  // ── helper: safe PUT/DELETE that returns bool ──
  static Future<bool> _put(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await http
          .put(Uri.parse('$_base$path'),
          headers: _h,
          body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _delete(String path) async {
    try {
      final r = await http
          .delete(Uri.parse('$_base$path'), headers: _h)
          .timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── USERS ──
  static Future<List<dynamic>> getUsers() => _getList('/api/admin/users');
  static Future<bool> suspendUser(String id)   => _put('/api/admin/users/$id/suspend');
  static Future<bool> unsuspendUser(String id) => _put('/api/admin/users/$id/unsuspend');
  static Future<bool> deleteUser(String id)    => _delete('/api/admin/users/$id');

  // ── CHAUFFEURS ──
  static Future<List<dynamic>> getChauffeurs() => _getList('/api/admin/chauffeurs');
  static Future<bool> updateChauffeurStatus(String id, String status) =>
      _put('/api/admin/chauffeurs/$id/status', body: {'status': status});

  // ── COMMANDES ──
  static Future<List<dynamic>> getAllCommandes() => _getList('/api/admin/commandes');
  static Future<bool> cancelCommande(String id) => _put('/api/admin/commandes/$id/cancel');
  static Future<bool> reassignChauffeur(String commandeId, String chauffeurId) =>
      _put('/api/admin/commandes/$commandeId/assign/$chauffeurId');

  // ── RÉCLAMATIONS ──
  static Future<List<dynamic>> getClaims() => _getList('/api/admin/reclamations');
  static Future<bool> updateClaimStatus(String id, String status) =>
      _put('/api/admin/reclamations/$id', body: {'status': status});

  // ── AVIS ──
  static Future<List<dynamic>> getReviews() => _getList('/api/admin/avis');
  static Future<bool> hideReview(String id, bool hidden) =>
      _put('/api/admin/avis/$id', body: {'hidden': hidden});

  // ── LOGS ──
  static Future<List<dynamic>> getLogs() => _getList('/api/admin/logs');

  // ── WARNINGS ──
  static Future<List<dynamic>> getWarnings() => _getList('/api/admin/warnings');
  static Future<bool> markWarningTreated(String id) =>
      _put('/api/admin/warnings/$id/treat');
}

// ==================== SHARED WIDGETS ====================
AppBar buildAppBar(String title) => AppBar(
  title: Text(title),
  backgroundColor: const Color(0xFF1E3A8A),
  foregroundColor: Colors.white,
  leading: Builder(
    builder: (ctx) => IconButton(
      icon: const Icon(Icons.arrow_back_ios_new),
      onPressed: () => Navigator.pop(ctx),
    ),
  ),
);

Widget buildLoading() =>
    const Center(child: CircularProgressIndicator());

Widget buildEmpty(String msg) =>
    Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));

Widget buildError(String msg, VoidCallback onRetry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off_outlined, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(msg,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    ]),
  ),
);

// ==================== SIGNALEMENT DIALOG ====================
const List<String> kRaisonsSignalement = [
  'Comportement inapproprié',
  'Retard répété',
  'Fraude / impayé',
  'Contenu abusif',
  'Non-respect des règles',
  'Autre',
];

void showSignalementDialog(BuildContext context, {String? defaultTarget}) {
  final messageCtrl = TextEditingController();
  final targetCtrl  = TextEditingController(text: defaultTarget ?? '');
  String? selectedRaison;
  String targetType = 'Client';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.flag_outlined, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text('Envoyer un signalement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),
              const Text('Envoyer à :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Client', 'Chauffeur'].map((t) {
                  final sel = targetType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: sel,
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle:
                      TextStyle(color: sel ? Colors.white : Colors.black),
                      onSelected: (_) => set(() => targetType = t),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom du $targetType',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Raison :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: kRaisonsSignalement.map((r) {
                  final sel = selectedRaison == r;
                  return ChoiceChip(
                    label: Text(r, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: Colors.red.shade100,
                    labelStyle: TextStyle(
                        color: sel ? Colors.red.shade800 : Colors.black),
                    onSelected: (_) => set(() {
                      selectedRaison = sel ? null : r;
                      if (!sel) messageCtrl.text = r;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message (optionnel)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedRaison == null && messageCtrl.text.trim().isEmpty) return;

                    Navigator.pop(ctx);

                    final ok = await AdminApi.sendSignalement(
                      targetName: targetCtrl.text.isNotEmpty ? targetCtrl.text : targetType,
                      targetType: targetType,
                      raison:     selectedRaison ?? 'Autre',
                      message:    messageCtrl.text.trim(),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Signalement envoyé à ${targetCtrl.text.isNotEmpty ? targetCtrl.text : targetType}'
                            : 'Erreur lors de l\'envoi'),
                        backgroundColor: ok ? Colors.red.shade700 : Colors.grey,
                      ));
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer le signalement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> _sections = [
    {'title': 'Comptes utilisateurs', 'icon': Icons.people_outline,        'color': Colors.blue,   'screen': 'users'},
    {'title': 'Chauffeurs',           'icon': Icons.local_shipping_outlined,'color': Colors.green,  'screen': 'drivers'},
    {'title': 'Commandes',            'icon': Icons.receipt_long_outlined,  'color': Colors.orange, 'screen': 'orders'},
    {'title': 'Avertissements',       'icon': Icons.notifications_outlined, 'color': Colors.red,    'screen': 'warnings'},
    {'title': 'Réclamations',         'icon': Icons.message_outlined,       'color': Colors.purple, 'screen': 'claims'},
    {'title': 'Notes & avis',         'icon': Icons.star_outline,           'color': Colors.amber,  'screen': 'reviews'},
    {'title': "Journal d'activité",   'icon': Icons.history_outlined,       'color': Colors.teal,   'screen': 'logs'},
    {'title': 'Paramètres',           'icon': Icons.settings_outlined,      'color': Colors.grey,   'screen': 'settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdminWaveau'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bienvenue,',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            const Text('Administrateur',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            const Text('Choisissez une section pour continuer',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: _sections.length,
                itemBuilder: (ctx, i) {
                  final s = _sections[i];
                  return _buildCard(
                      ctx, s['title'], s['icon'], s['color'], s['screen']);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, String title, IconData icon,
      Color color, String screen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => _buildScreen(screen, title))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(String screen, String title) {
    switch (screen) {
      case 'users':    return const UsersScreen();
      case 'drivers':  return const DriversScreen();
      case 'orders':   return const OrdersScreen();
      case 'warnings': return const WarningsScreen();
      case 'claims':   return const ClaimsScreen();
      case 'reviews':  return const ReviewsScreen();
      case 'logs':     return const LogsScreen();
      case 'settings': return const SettingsScreen();
      default:         return SectionScreen(title: title);
    }
  }
}

// ==================== USERS SCREEN ====================
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _hasError = false;
  String _filter = 'Tous';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    final data = await AdminApi.getUsers();
    if (!mounted) return;
    if (data.isEmpty) {
      setState(() { _hasError = true; _loading = false; });
      return;
    }
    setState(() {
      _users   = data.map((u) => _map(u)).toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic u) => {
    '_id':    u['_id'] ?? u['id'] ?? '',
    'name':   '${u['nom'] ?? ''} ${u['prenom'] ?? ''}'.trim(),
    'email':  u['email'] ?? '',
    'phone':  u['telephone'] ?? '',
    'address':u['adresse'] ?? '',
    'status': _mapStatus(u['status'] ?? u['statut'] ?? 'actif'),
    'orders': u['commandesCount'] ?? 0,
    'balance':u['solde'] ?? 0,
  };

  String _mapStatus(dynamic s) {
    switch (s.toString().toLowerCase()) {
      case 'suspended': case 'suspendu': return 'Suspendu';
      case 'inactive':  case 'inactif':  return 'Inactif';
      default:                           return 'Actif';
    }
  }

  Color _statusColor(String s) =>
      s == 'Actif' ? Colors.green : s == 'Suspendu' ? Colors.red : Colors.grey;

  Future<void> _toggleSuspend(Map<String, dynamic> user) async {
    final isSuspended = user['status'] == 'Suspendu';
    final ok = isSuspended
        ? await AdminApi.unsuspendUser(user['_id'])
        : await AdminApi.suspendUser(user['_id']);
    if (!mounted) return;
    if (ok) {
      setState(() => user['status'] = isSuspended ? 'Actif' : 'Suspendu');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final ok = await AdminApi.deleteUser(user['_id']);
    if (!mounted) return;
    if (ok) {
      setState(() => _users.remove(user));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user['name']} supprimé'),
          backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')));
    }
  }

  void _showProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── header ──
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (user['name'] as String).isNotEmpty ? user['name'][0] : '?',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _statusBadge(user['status']),
                    ]),
                  ),
                ]),
                const Divider(height: 28),
                // ── info ──
                _infoRow(Icons.email_outlined,                    user['email']),
                _infoRow(Icons.phone_outlined,                    user['phone']),
                _infoRow(Icons.location_on_outlined,              user['address']),
                _infoRow(Icons.receipt_long_outlined,             '${user['orders']} commandes'),
                _infoRow(Icons.account_balance_wallet_outlined,   'Solde : ${user['balance']} DA'),
                const SizedBox(height: 20),
                // ── actions ──
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _actionBtn(
                    user['status'] == 'Suspendu' ? 'Débloquer' : 'Suspendre',
                    user['status'] == 'Suspendu' ? Icons.lock_open : Icons.block,
                    user['status'] == 'Suspendu' ? Colors.green : Colors.orange,
                        () async {
                      Navigator.pop(ctx);
                      await _toggleSuspend(user);
                    },
                  ),
                  _actionBtn('Signalement', Icons.flag_outlined, Colors.red, () {
                    Navigator.pop(ctx);
                    showSignalementDialog(context, defaultTarget: user['name']);
                  }),
                  _actionBtn('Supprimer', Icons.delete_outline, Colors.red.shade900, () {
                    Navigator.pop(ctx);
                    _confirmDelete(user);
                  }),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
    ]),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.4))),
      );

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le compte de ${user['name']} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(user);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'Tous'
        ? _users
        : _users.where((u) => u['status'] == _filter).toList();

    return Scaffold(
      appBar: buildAppBar('Comptes utilisateurs'),
      body: _loading
          ? buildLoading()
          : _hasError
          ? buildError('Impossible de charger les utilisateurs.', _load)
          : Column(children: [
        // ── filter chips ──
        _filterBar(['Tous', 'Actif', 'Suspendu', 'Inactif'],
            const Color(0xFF1E3A8A)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? buildEmpty('Aucun utilisateur trouvé')
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = filtered[i];
                final color = _statusColor(u['status']);
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        (u['name'] as String).isNotEmpty
                            ? u['name'][0]
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ),
                    title: Text(u['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(u['email']),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusBadge(u['status']),
                        const SizedBox(height: 4),
                        Text('${u['orders']} commandes',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    onTap: () => _showProfile(u),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filterBar(List<String> options, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((f) {
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: sel,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: color.withOpacity(0.15),
              checkmarkColor: color,
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// ==================== DRIVERS SCREEN ====================
class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});
  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  bool _hasError = false;
  String _filter = 'Tous';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });

    // Fetch both in parallel
    final results = await Future.wait([
      AdminApi.getChauffeurs(),
      AdminApi.getReviews(),
    ]);

    final data    = results[0];
    final reviews = results[1];

    if (!mounted) return;
    if (data.isEmpty) {
      setState(() { _hasError = true; _loading = false; });
      return;
    }

    // Build map: chauffeur nom → list of notes given by clients
    final Map<String, List<int>> ratingMap = {};

// Step 1: build commande → chauffeur nom from chauffeur reviews
    final Map<String, String> commandeToDriver = {};
    for (final r in reviews) {
      if (r['reviewerRole'] != 'chauffeur') continue;
      final commande = r['commande'] ?? '';
      final nom      = r['chauffeur']?['nom'] ?? '';
      if (commande.isNotEmpty && nom.isNotEmpty) {
        commandeToDriver[commande] = nom;
      }
    }

// Step 2: for each client review, find the driver via commande
    for (final r in reviews) {
      if (r['reviewerRole'] != 'client') continue;
      final commande = r['commande'] ?? '';
      final nom      = commandeToDriver[commande] ?? '';
      if (nom.isEmpty) continue;
      ratingMap.putIfAbsent(nom, () => []).add((r['note'] ?? 0).toInt());
    }
    debugPrint('ratingMap: $ratingMap');
    debugPrint('driver noms: ${data.map((d) => d['nom']).toList()}');
    setState(() {
      _drivers = data.map((d) {
        final notes = ratingMap[d['nom']] ?? [];
        final avg   = notes.isEmpty
            ? 0.0
            : notes.reduce((a, b) => a + b) / notes.length;
        return _map(d, avg);
      }).toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic d, [double computedRating = 0.0]) => {
    '_id':       d['_id'] ?? d['id'] ?? '',
    'name':      '${d['nom'] ?? ''} ${d['prenom'] ?? ''}'.trim(),
    'phone':     d['telephone'] ?? '',
    'zone':      d['zone'] ?? d['wilaya'] ?? 'N/A',
    'deliveries':d['totalLivraisons'] ?? 0,
    'rating':    computedRating,   // ← real rating: avg of what clients gave him
    'monthly':   d['livraisonsMois'] ?? 0,
    'status':    _mapStatus(d['status'] ?? d['statut'] ?? 'actif'),
    'available': d['disponible'] ?? false,
  };

  String _mapStatus(dynamic s) {
    switch (s.toString().toLowerCase()) {
      case 'suspended': case 'suspendu': return 'Suspendu';
      case 'inactive':  case 'inactif':  return 'Inactif';
      default:                           return 'Actif';
    }
  }

  Color _statusColor(String s) =>
      s == 'Actif' ? Colors.green : s == 'Suspendu' ? Colors.red : Colors.grey;

  void _showDetail(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── header ──
                Row(children: [
                  Stack(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.local_shipping,
                          color: Colors.green.shade700, size: 28),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: d['available'] ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['name'],
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(d['phone'],
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: _statusColor(d['status']).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(d['status'],
                            style: TextStyle(
                                color: _statusColor(d['status']),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ]),
                  ),
                ]),
                const Divider(height: 28),
                // ── stats ──
                Row(children: [
                  _statBox('Total livr.', '${d['deliveries']}', Colors.blue),
                  const SizedBox(width: 10),
                  _statBox('Ce mois', '${d['monthly']}', Colors.teal),
                  const SizedBox(width: 10),
                  // ✅ real rating: avg of notes clients gave this chauffeur
                  _statBox('Note moy.',
                      '${(d['rating'] as double).toStringAsFixed(1)}★',
                      Colors.amber),
                ]),
                const SizedBox(height: 16),
                Text('Zone : ${d['zone']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 16),
                // ── actions ──
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final newStatus =
                      d['status'] == 'Suspendu' ? 'actif' : 'suspendu';
                      final ok = await AdminApi.updateChauffeurStatus(
                          d['_id'], newStatus);
                      if (ok) {
                        setState(() {
                          d['status'] =
                          d['status'] == 'Suspendu' ? 'Actif' : 'Suspendu';
                          d['available'] = d['status'] == 'Actif';
                        });
                      }
                      if (mounted) Navigator.pop(ctx);
                    },
                    icon: Icon(
                      d['status'] == 'Suspendu' ? Icons.lock_open : Icons.block,
                      size: 16,
                      color: d['status'] == 'Suspendu'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    label: Text(
                      d['status'] == 'Suspendu' ? 'Réactiver' : 'Suspendre',
                      style: TextStyle(
                          color: d['status'] == 'Suspendu'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.withOpacity(0.4))),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showSignalementDialog(context, defaultTarget: d['name']);
                    },
                    icon: const Icon(Icons.flag_outlined,
                        size: 16, color: Colors.red),
                    label: const Text('Signalement',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.4))),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'Tous'
        ? _drivers
        : _drivers.where((d) => d['status'] == _filter).toList();

    return Scaffold(
      appBar: buildAppBar('Chauffeurs'),
      body: _loading
          ? buildLoading()
          : _hasError
          ? buildError('Impossible de charger les chauffeurs.', _load)
          : Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'Actif', 'Suspendu', 'Inactif'].map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? buildEmpty('Aucun chauffeur trouvé')
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final d  = filtered[i];
                final sc = _statusColor(d['status']);
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Stack(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(Icons.local_shipping,
                            color: Colors.green.shade700),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: d['available'] ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ]),
                    title: Text(d['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['phone'],
                              style: const TextStyle(fontSize: 12)),
                          Text('Zone : ${d['zone']}',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                    trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: sc.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(d['status'],
                                style: TextStyle(
                                    color: sc,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 4),
                          // ✅ real rating from clients
                          Text(
                            '${(d['rating'] as double).toStringAsFixed(1)}★',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                    onTap: () => _showDetail(d),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
// ==================== ORDERS SCREEN ====================
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders  = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String _filter = 'Tous';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([

      AdminApi.getAllCommandes(),
      AdminApi.getChauffeurs(),
    ]);

    if (!mounted) return;

    setState(() {
      _orders  = results[0].map((o) => _mapOrder(o)).toList();
      _drivers = results[1].map((d) => {
        '_id':  d['_id'] ?? d['id'] ?? '',
        'name': '${d['nom'] ?? ''} ${d['prenom'] ?? ''}'.trim(),
      }).toList();

      _loading = false;
    });
  }

  Map<String, dynamic> _mapOrder(dynamic o) {
    // safely get _id and shorten it for display
    final rawId = (o['_id'] ?? o['id'] ?? '').toString();
    final shortId = rawId.length >= 6 ? rawId.substring(rawId.length - 6).toUpperCase() : rawId.toUpperCase();
    final date = DateTime.tryParse(o['createdAt'] ?? '') ?? DateTime.now();
    return {
      '_id':      rawId,
      'id':       '#CMD-$shortId',
      'client':   o['client']?['nom'] ?? o['clientNom'] ?? 'Client',
      'address':  o['adresse'] ?? '',
      'qty':      '${o['capacite'] ?? 0} L',
      'driver':   o['chauffeur']?['nom'] ?? 'Non assigné',
      'driverId': o['chauffeur']?['_id'] ?? '',
      'status':   _mapStatus(o['status'] ?? 'en attente'),
      'date':     '${date.day}/${date.month}/${date.year}',
      'time':     '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}',
    };
  }

  String _mapStatus(dynamic s) {
    switch (s.toString().toLowerCase()) {
      case 'en cours':  case 'in_progress':            return 'En cours';
      case 'livrée':    case 'livree':    case 'done':  return 'Livré';
      case 'annulée':   case 'annulee':   case 'cancelled': return 'Annulé';
      default:                                          return 'En attente';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Livré':    return Colors.green;
      case 'En cours': return Colors.blue;
      case 'Annulé':   return Colors.red;
      default:         return Colors.orange;
    }
  }

  void _showDetail(Map<String, dynamic> order) {
    String selDriverId   = order['driverId'] as String;
    String selDriverName = order['driver']   as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(order['id'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E3A8A))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _statusColor(order['status']).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(order['status'],
                        style: TextStyle(
                            color: _statusColor(order['status']),
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const Divider(height: 24),
                _row(Icons.person_outline,      'Client',   order['client']),
                _row(Icons.location_on_outlined,'Adresse',  order['address']),
                _row(Icons.water_drop_outlined, 'Quantité', order['qty']),
                _row(Icons.calendar_today_outlined, 'Date',
                    '${order['date']} à ${order['time']}'),
                const SizedBox(height: 16),
                if (_drivers.isNotEmpty) ...[
                  const Text('Réassigner le chauffeur :',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selDriverId.isNotEmpty ? selDriverId : null,
                    hint: const Text('Choisir un chauffeur'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: _drivers
                        .map((d) => DropdownMenuItem<String>(
                      value: d['_id'] as String,
                      child: Text(d['name'] as String),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModal(() {
                        selDriverId   = v;
                        selDriverName = _drivers
                            .firstWhere((d) => d['_id'] == v,
                            orElse: () => {'name': ''})['name']
                        as String;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (order['status'] == 'Annulé' ||
                          order['status'] == 'Livré')
                          ? null
                          : () async {
                        final ok = await AdminApi.cancelCommande(
                            order['_id'] as String);
                        if (ok && mounted) {
                          setState(() => order['status'] = 'Annulé');
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Annuler',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selDriverId.isEmpty
                          ? null
                          : () async {
                        final ok = await AdminApi.reassignChauffeur(
                            order['_id'] as String, selDriverId);
                        if (ok && mounted) {
                          setState(() => order['driver'] = selDriverName);
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      Text('$label : ',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final statuses = ['Tous', 'En attente', 'En cours', 'Livré', 'Annulé'];
    final filtered = _filter == 'Tous'
        ? _orders
        : _orders.where((o) => o['status'] == _filter).toList();

    return Scaffold(
      appBar: buildAppBar('Commandes'),
      body: _loading
          ? buildLoading()
          : Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f,
                        style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.orange.withOpacity(0.15),
                    checkmarkColor: Colors.orange,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? buildEmpty('Aucune commande')
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final o = filtered[i];
                final color = _statusColor(o['status'] as String);
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long,
                          color: Colors.orange.shade700),
                    ),
                    title: Row(children: [
                      Text(o['id'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius:
                            BorderRadius.circular(20)),
                        child: Text(o['status'] as String,
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(o['client'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          Text(
                              '${o['qty']} · ${o['date']}',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12)),
                          Text('Chauffeur : ${o['driver']}',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12)),
                        ]),
                    onTap: () => _showDetail(o),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

// ==================== WARNINGS SCREEN ====================
class WarningsScreen extends StatefulWidget {
  const WarningsScreen({super.key});
  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  List<Map<String, dynamic>> _warnings = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdminApi.getWarnings();
    if (!mounted) return;
    setState(() {
      _warnings = data.isNotEmpty
          ? data.map((w) => _map(w)).toList()
          : _fallback();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _fallback() => [
    {'_id': '', 'title': 'Retard de livraison',   'user': 'Chauffeur', 'time': 'Récent', 'level': 'Moyen',  'treated': false},
    {'_id': '', 'title': 'Paiement non confirmé', 'user': 'Client',    'time': 'Récent', 'level': 'Urgent', 'treated': false},
  ];

  Map<String, dynamic> _map(dynamic w) => {
    '_id':     w['_id'] ?? '',
    'title':   w['title']  ?? w['titre'] ?? '',
    'user':    w['user']   ?? w['utilisateur'] ?? '',
    'time':    w['time']   ?? w['heure'] ?? (w['createdAt'] != null ? _fmtDate(w['createdAt']) : ''),
    'level':   _mapLevel(w['level'] ?? w['niveau'] ?? 'info'),
    'treated': w['treated'] ?? w['traite'] ?? false,
  };

  String _mapLevel(dynamic l) {
    switch (l.toString().toLowerCase()) {
      case 'urgent': case 'high':   return 'Urgent';
      case 'moyen':  case 'medium': return 'Moyen';
      case 'faible': case 'low':    return 'Faible';
      default:                      return 'Info';
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso) ?? DateTime.now();
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  Color _levelColor(String l) {
    switch (l) {
      case 'Urgent': return Colors.red;
      case 'Moyen':  return Colors.orange;
      case 'Faible': return Colors.blue;
      default:       return Colors.teal;
    }
  }

  IconData _levelIcon(String l) {
    switch (l) {
      case 'Urgent': return Icons.error_outline;
      case 'Moyen':  return Icons.warning_amber_outlined;
      case 'Faible': return Icons.info_outline;
      default:       return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Avertissements'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSignalementDialog(context),
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Envoyer signalement'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? buildLoading()
          : RefreshIndicator(
        onRefresh: _load,
        child: _warnings.isEmpty
            ? buildEmpty('Aucun avertissement')
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _warnings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final w = _warnings[i];
            final color   = _levelColor(w['level'] as String);
            final treated = w['treated'] as bool;
            return Opacity(
              opacity: treated ? 0.5 : 1.0,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_levelIcon(w['level'] as String),
                        color: color),
                  ),
                  title: Text(w['title'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: treated
                              ? TextDecoration.lineThrough
                              : null)),
                  subtitle: Text('${w['user']} · ${w['time']}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(20)),
                          child: Text(w['level'] as String,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final id = w['_id'] as String;
                            if (id.isNotEmpty) {
                              await AdminApi.markWarningTreated(id);
                            }
                            setState(() => w['treated'] = !treated);
                          },
                          child: Text(
                              treated
                                  ? 'Traité ✓'
                                  : 'Marquer traité',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: treated
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== CLAIMS SCREEN ====================
class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});
  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  List<Map<String, dynamic>> _claims = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdminApi.getClaims();
    debugPrint('[CLAIMS] count: ${data.length}');
    debugPrint('[CLAIMS] first item: ${data.isNotEmpty ? data.first : 'empty'}');
    if (!mounted) return;
    setState(() {
      _claims  = data.map((c) => _map(c)).toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic c) {
    final rawId   = (c['_id'] ?? c['id'] ?? '').toString();
    final shortId = rawId.length >= 6 ? rawId.substring(rawId.length - 6).toUpperCase() : rawId.toUpperCase();
    return {
      '_id':      rawId,
      'id':       '#REC-$shortId',
      'client':   c['clientNom'] ?? c['client']?['nom'] ?? 'Client', // ← reads clientNom
      'subject':  c['sujet']  ?? c['subject'] ?? '',
      'message':  c['message'] ?? '',
      'status':   _mapStatus(c['status'] ?? 'ouverte'),
      'date':     c['createdAt'] != null ? _fmtDate(c['createdAt']) : '',
      'priority': _mapPriority(c['priorite'] ?? 'normale'),          // ← your model uses 'priorite'
    };
  }

  String _mapStatus(dynamic s) {
    switch (s.toString().toLowerCase()) {
      case 'en traitement': case 'in_progress': return 'En traitement';
      case 'résolue':       case 'resolved':    return 'Résolue';
      case 'fermée':        case 'closed':      return 'Fermée';
      default:                                  return 'Ouverte';
    }
  }

  String _mapPriority(dynamic p) {
    switch (p.toString().toLowerCase()) {
      case 'haute': case 'high': return 'Haute';
      case 'basse': case 'low':  return 'Basse';
      default:                   return 'Normale';
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso) ?? DateTime.now();
    return '${d.day}/${d.month}/${d.year}';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Ouverte':       return Colors.red;
      case 'En traitement': return Colors.orange;
      case 'Résolue':       return Colors.green;
      default:              return Colors.grey;
    }
  }

  void _showDetail(Map<String, dynamic> c) {
    String currentStatus = c['status'] as String;
    const statuses = ['Ouverte', 'En traitement', 'Résolue', 'Fermée'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(c['id'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.purple)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _statusColor(currentStatus).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(currentStatus,
                        style: TextStyle(
                            color: _statusColor(currentStatus),
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Text(c['subject'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${c['client']} · ${c['date']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),

// ── Message ──────────────────────────────────────
                if ((c['message'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Message :',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          c['message'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
// ─────────────────────────────────────────────────

                const Divider(height: 24),
                const Text('Changer le statut :',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: statuses.map((s) {
                    final sel = currentStatus == s;
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: _statusColor(s).withOpacity(0.2),
                      labelStyle:
                      TextStyle(color: sel ? _statusColor(s) : Colors.black),
                      onSelected: (_) => setModal(() => currentStatus = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showSignalementDialog(context,
                            defaultTarget: c['client'] as String);
                      },
                      icon: const Icon(Icons.flag_outlined,
                          color: Colors.red, size: 16),
                      label: const Text('Signalement',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await AdminApi.updateClaimStatus(
                            c['_id'] as String, currentStatus);
                        if (ok && mounted) {
                          setState(() => c['status'] = currentStatus);
                        }
                        if (mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Enregistrer',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Réclamations'),
      body: _loading
          ? buildLoading()
          : RefreshIndicator(
        onRefresh: _load,
        child: _claims.isEmpty
            ? buildEmpty('Aucune réclamation')
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _claims.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c     = _claims[i];
            final color = _statusColor(c['status'] as String);
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(c['id'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c['priority'] == 'Haute'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(c['priority'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: c['priority'] == 'Haute'
                                      ? Colors.red
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(20)),
                          child: Text(c['status'] as String,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(c['subject'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${c['client']} · ${c['date']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      // ── Message content ──────────────────────────
                      if ((c['message'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Message :',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text(
                                c['message'].toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        OutlinedButton(
                            onPressed: () => _showDetail(c),
                            child: const Text('Voir & traiter')),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => showSignalementDialog(
                              context,
                              defaultTarget: c['client'] as String),
                          icon: const Icon(Icons.flag_outlined,
                              size: 14, color: Colors.red),
                          label: const Text('Signaler',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),
                      ]),
                    ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== REVIEWS SCREEN ====================
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews          = [];
  List<Map<String, dynamic>> _clientReviews    = [];
  List<Map<String, dynamic>> _chauffeurReviews = [];

  bool    _loading      = true;
  int?    _filterNote;
  String? _filterDriver;
  String? _filterClient;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdminApi.getReviews();
    if (!mounted) return;
    setState(() {
      _reviews          = data.map((r) => _map(r)).toList();
      _clientReviews    = _reviews.where((r) => r['reviewerRole'] == 'client').toList();
      _chauffeurReviews = _reviews.where((r) => r['reviewerRole'] == 'chauffeur').toList();

      // Fill missing driver name in client reviews using paired chauffeur review
      for (final cr in _clientReviews) {
        if (cr['driver'] == 'N/A') {
          final paired = _chauffeurReviews.firstWhere(
                (dr) => dr['commande'] == cr['commande'],
            orElse: () => {},
          );
          if (paired.isNotEmpty) cr['driver'] = paired['driver'];
        }
      }

      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic r) => {
    '_id':          r['_id'] ?? r['id'] ?? '',
    'commande':     r['commande'] ?? '',
    'client':       r['client']?['nom']    ?? 'Client',
    'driver':       r['chauffeur']?['nom'] ?? 'N/A',
    'note':         (r['note'] ?? 0).toInt(),
    'comment':      r['commentaire'] ?? r['comment'] ?? '',
    'hidden':       r['hidden'] ?? false,
    'reviewerRole': r['reviewerRole'] ?? '',
  };

  Widget _buildRatingRow({
    required String label,
    required String groupBy,
    required List<Map<String, dynamic>> reviews,
  }) {
    final Map<String, List<int>> groups = {};
    for (final r in reviews) {
      final key = r[groupBy] as String;
      if (key == 'N/A' || key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(r['note'] as int);
    }

    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final entry = groups.entries.elementAt(i);
              final avg   = entry.value.reduce((a, b) => a + b) / entry.value.length;
              final sel   = groupBy == 'driver'
                  ? _filterDriver == entry.key
                  : _filterClient == entry.key;

              return GestureDetector(
                onTap: () => setState(() {
                  if (groupBy == 'driver') {
                    _filterDriver = sel ? null : entry.key;
                  } else {
                    _filterClient = sel ? null : entry.key;
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? Colors.amber.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: sel ? Border.all(color: Colors.amber) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.key.split(' ').first,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${avg.toStringAsFixed(1)}★',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      Text('${entry.value.length} avis',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _reviews.where((r) {
      if (_filterNote != null && r['note'] != _filterNote) return false;

      // tapped a chauffeur card → show only reviews WHERE he was rated (by clients)
      if (_filterDriver != null) {
        if (r['reviewerRole'] != 'client') return false;
        if (r['driver'] != _filterDriver) return false;
      }

      // tapped a client card → show only reviews WHERE he was rated (by chauffeurs)
      if (_filterClient != null) {
        if (r['reviewerRole'] != 'chauffeur') return false;
        if (r['client'] != _filterClient) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: buildAppBar('Notes & avis'),
      body: _loading
          ? buildLoading()
          : Column(children: [

        // ── Chauffeurs rated by clients ──
        _buildRatingRow(
          label: '🚗 Chauffeurs',
          groupBy: 'driver',
          reviews: _clientReviews,
        ),

        // ── Clients rated by chauffeurs ──
        _buildRatingRow(
          label: '👤 Clients',
          groupBy: 'client',
          reviews: _chauffeurReviews,
        ),

        // ── note filter ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              FilterChip(
                  label: const Text('Tous'),
                  selected: _filterNote == null,
                  onSelected: (_) => setState(() => _filterNote = null)),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final n = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text('$n★'),
                    selected: _filterNote == n,
                    onSelected: (_) => setState(
                            () => _filterNote = _filterNote == n ? null : n),
                    selectedColor: Colors.amber.withOpacity(0.2),
                    checkmarkColor: Colors.amber,
                  ),
                );
              }),
            ]),
          ),
        ),

        // ── list ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? buildEmpty('Aucun avis')
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r      = filtered[i];
                final note   = r['note']   as int;
                final hidden = r['hidden'] as bool;
                final isClientReview = r['reviewerRole'] == 'client';

                return Opacity(
                  opacity: hidden ? 0.4 : 1.0,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.amber.shade100,
                              child: Text(
                                isClientReview
                                    ? ((r['client'] as String).isNotEmpty ? r['client'][0] as String : '?')
                                    : ((r['driver'] as String).isNotEmpty ? r['driver'][0] as String : '?'),
                                style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isClientReview
                                        ? r['client'] as String
                                        : r['driver'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    isClientReview
                                        ? 'Avis sur : ${r['driver']}'
                                        : 'Avis sur : ${r['client']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                    (j) => Icon(
                                  j < note ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Text(r['comment'] as String,
                              style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final ok = await AdminApi.hideReview(
                                    r['_id'] as String, !hidden);
                                if (ok && mounted) {
                                  setState(() => r['hidden'] = !hidden);
                                }
                              },
                              icon: Icon(
                                  hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 16),
                              label: Text(
                                  hidden ? 'Afficher' : 'Masquer',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

// ==================== LOGS SCREEN ====================
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = 'Tous';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdminApi.getLogs();
    if (!mounted) return;
    setState(() {
      _logs    = data.map((l) => _map(l)).toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic l) {
    final type = _mapType(l['type'] ?? l['category'] ?? 'autre');
    return {
      'action': l['action']  ?? l['message'] ?? '',
      'detail': l['detail']  ?? l['details'] ?? '',
      'time':   l['createdAt'] != null ? _fmtDate(l['createdAt'] as String) : '',
      'author': l['author']  ?? l['auteur']  ?? 'Système',
      'type':   type,
      'icon':   _typeIcon(type),
      'color':  _typeColor(type),
    };
  }

  String _mapType(dynamic t) {
    switch (t.toString().toLowerCase()) {
      case 'commande':    case 'order':       return 'Commande';
      case 'reclamation': case 'claim':       return 'Réclamation';
      case 'compte':      case 'account':     return 'Compte';
      case 'connexion':   case 'login':       return 'Connexion';
      case 'signalement': case 'report':      return 'Signalement';
      default:                                return 'Autre';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'Commande':    return Icons.receipt_long_outlined;
      case 'Réclamation': return Icons.report_problem_outlined;
      case 'Compte':      return Icons.person_outline;
      case 'Connexion':   return Icons.login_outlined;
      case 'Signalement': return Icons.flag_outlined;
      default:            return Icons.info_outline;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'Commande':    return Colors.blue;
      case 'Réclamation': return Colors.orange;
      case 'Compte':      return Colors.red;
      case 'Connexion':   return Colors.grey;
      case 'Signalement': return Colors.red;
      default:            return Colors.teal;
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso) ?? DateTime.now();
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    const types = ['Tous', 'Commande', 'Réclamation', 'Compte', 'Connexion', 'Signalement'];
    final filtered = _filter == 'Tous'
        ? _logs
        : _logs.where((l) => l['type'] == _filter).toList();

    return Scaffold(
      appBar: buildAppBar("Journal d'activité"),
      body: _loading
          ? buildLoading()
          : Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: types.map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f,
                        style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.teal.withOpacity(0.15),
                    checkmarkColor: Colors.teal,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? buildEmpty('Aucune activité enregistrée')
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final log    = filtered[i];
                final color  = log['color'] as Color;
                final isLast = i == filtered.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle),
                        child: Icon(log['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      if (!isLast)
                        Container(
                            width: 2,
                            height: 44,
                            color: Colors.grey.shade200),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding:
                        const EdgeInsets.only(bottom: 16),
                        child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        log['action'] as String,
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600))),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius:
                                      BorderRadius.circular(8)),
                                  child: Text(
                                      log['author'] as String,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey)),
                                ),
                              ]),
                              Text(log['detail'] as String,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13)),
                              Text(log['time'] as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey)),
                            ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool   _notifications = true;
  bool   _darkMode      = false;
  bool   _autoAssign    = true;
  String _selectedLang  = 'Français';
  final List<String> _zones = [
    'Alger Centre', 'Bab Ezzouar', 'Kouba', 'Hussein Dey', 'El Harrach'
  ];
  final _zoneCtrl = TextEditingController();

  @override
  void dispose() { _zoneCtrl.dispose(); super.dispose(); }

  void _showZonesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zones de livraison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._zones.map((z) => ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_outlined,
                    color: Color(0xFF1E3A8A)),
                title: Text(z),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() => _zones.remove(z));
                    setModal(() {});
                  },
                ),
              )),
              const Divider(),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _zoneCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nouvelle zone...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_zoneCtrl.text.trim().isNotEmpty) {
                      setState(() => _zones.add(_zoneCtrl.text.trim()));
                      setModal(() {});
                      _zoneCtrl.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white),
                  child: const Text('Ajouter'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Paramètres'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Général'),
          _toggleTile(Icons.dark_mode_outlined, 'Mode sombre', _darkMode,
                  (v) => setState(() => _darkMode = v)),
          _toggleTile(Icons.notifications_outlined, 'Notifications push',
              _notifications, (v) => setState(() => _notifications = v)),
          _dropdownTile(
              Icons.language_outlined, 'Langue', _selectedLang,
              ['Français', 'العربية', 'English'],
                  (v) => setState(() => _selectedLang = v!)),
          const SizedBox(height: 16),
          _sectionHeader('Livraison'),
          _toggleTile(Icons.autorenew_outlined, 'Assignation automatique',
              _autoAssign, (v) => setState(() => _autoAssign = v)),
          _actionTile(Icons.map_outlined,
              'Gérer les zones (${_zones.length} actives)', _showZonesDialog),
          const SizedBox(height: 16),
          _sectionHeader('Compte administrateur'),
          _actionTile(Icons.lock_outline, 'Changer le mot de passe', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')));
          }),
          _actionTile(Icons.logout, 'Se déconnecter', () {
            AdminToken.clear();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => Loginpage()),
                  (route) => false,
            );
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
            letterSpacing: 0.5)),
  );

  Widget _toggleTile(IconData icon, String title, bool value,
      Function(bool) onChanged) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SwitchListTile(
          secondary: Icon(icon, color: const Color(0xFF1E3A8A)),
          title: Text(title),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1E3A8A),
        ),
      );

  Widget _dropdownTile(IconData icon, String title, String value,
      List<String> items, Function(String?) onChanged) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF1E3A8A)),
          title: Text(title),
          trailing: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _actionTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: color ?? const Color(0xFF1E3A8A)),
          title: Text(title, style: TextStyle(color: color)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

// ==================== FALLBACK SCREEN ====================
class SectionScreen extends StatelessWidget {
  final String title;
  const SectionScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.dashboard_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text('Contenu à venir.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
        ]),
      ),
    );
  }
}