// ================================================================
// FICHIER : profile_screen.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/main.dart';

import '../gerant/Info.dart';
import '../services/api_service.dart';


// ================================================================
// 1. ÉCRAN PRINCIPAL DU PROFIL
// ================================================================
class gerantinfos extends StatefulWidget {
  const gerantinfos({Key? key}) : super(key: key);

  @override
  State<gerantinfos> createState() => _gerantinfosState();
}

class _gerantinfosState extends State<gerantinfos> {

  // ── State ──────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  // Real data from DB
  String _name       = '';
  String _phone      = '';
  String _email      = '';
  double _rating     = 0.0;
  int    _totalDeliveries = 0;
  int    _trucks     = 0;
  int    _totalCapacity = 0;
  String _memberSince = '';
  String _role       = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();

  }
  // ── Load from DB ───────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      // Use getGerantInfo() → GET /api/auth/me  (works for all roles)
      final data = await ApiService.getGerantInfo();

      if (data['error'] != null) {
        setState(() { _error = data['error']; _isLoading = false; });
        return;
      }

      // The response shape from /api/auth/me:
      // { nom, prenom, email, telephone, role, createdAt,
      //   fournisseurInfo: { quantiteEau, wilayas, ... } }
      final String nom    = data['nom']    ?? '';
      final String prenom = data['prenom'] ?? '';

      // For fournisseurs, also fetch /api/fournisseurs/me for richer data
      Map<String, dynamic> fournisseurData = {};
      if (ApiService.userRole == 'fournisseur' ||
          ApiService.userRole == 'gerant') {
        fournisseurData = await ApiService.getMyInfo();
      }

      // Parse member-since date
      String memberSince = '';
      if (data['createdAt'] != null) {
        try {
          final dt = DateTime.parse(data['createdAt'].toString());
          const months = [
            '', 'Janvier','Février','Mars','Avril','Mai','Juin',
            'Juillet','Août','Septembre','Octobre','Novembre','Décembre'
          ];
          memberSince = '${months[dt.month]} ${dt.year}';
        } catch (_) {}
      }

      setState(() {
        _name   = '$nom $prenom'.trim();
        _phone  = data['telephone'] ?? '';
        _email  = data['email']     ?? '';
        _role   = data['role']      ?? ApiService.userRole ?? '';
        _memberSince = memberSince;

        // Fournisseur-specific fields
        if (fournisseurData['error'] == null) {
          _rating    = (fournisseurData['rating']   as num?)?.toDouble() ?? 0.0;
          _totalDeliveries = (fournisseurData['totalLivraisons'] as num?)?.toInt() ?? 0;
          // capaciteCamion comes as a number (litres)
          _totalCapacity   = (fournisseurData['quantiteEau'] as num?)?.toInt() ?? 0;
          // chauffeurs list length if gerant
          final chauffeurs = fournisseurData['chauffeurs'];
          _trucks = (chauffeurs is List) ? chauffeurs.length : 0;
        }

        _isLoading = false;
      });

    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Logout ─────────────────────────────────────────────────────
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Se déconnecter',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => Loginpage())),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Clear stored session
              ApiService.token    = null;
              ApiService.userId   = null;
              ApiService.userRole = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => Loginpage()),
                    (route) => false,
              );
            },
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF1E3A8A),

        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),

        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : _error != null
          ? _buildErrorState()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildSettingsMenu(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Impossible de charger le profil',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.person,
                    size: 50, color: Color(0xFF1E3A8A)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      size: 20, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_name.isNotEmpty ? _name : 'Utilisateur',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // Role badge
          if (_role.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _role.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.2),
              ),
            ),
          if (_rating > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('${_rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          // Member since
          if (_memberSince.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Membre depuis $_memberSince',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _buildStatCard(
      {required IconData icon,
        required String label,
        required String value,
        required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Paramètres',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),

          _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Informations personnelles',
              subtitle: _email,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PersonalInfoScreen(
                        name: _name,
                        phone: _phone,
                        email: _email,
                      )))),
          _buildDivider(),

          _buildMenuItem(
              icon: Icons.local_shipping_outlined,
              title: 'Mes camions',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MyCamionsScreen(token: ApiService.token ?? '')))),
          _buildDivider(),

          _buildMenuItem(
              icon: Icons.payment_outlined,
              title: 'Paiements & Facturation',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()))),
          _buildDivider(),

          _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                      const NotificationsSettingsScreen()))),
          _buildDivider(),

          _buildMenuItem(
              icon: Icons.language_outlined,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()))),
          _buildDivider(),

          _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen()))),
          _buildDivider(),

          ValueListenableBuilder<bool>(
            valueListenable: themeNotifier,
            builder: (context, isDark, child) {
              return _buildMenuItem(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: isDark ? 'Mode sombre' : 'Mode clair',
                subtitle: isDark
                    ? 'Appuyer pour mode clair'
                    : 'Appuyer pour mode sombre',
                onTap: () {
                  themeNotifier.value = !themeNotifier.value;
                },
              );
            },
          ),





        ],
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5))),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        indent: 76,
        endIndent: 20,
        color: Theme.of(context).dividerColor);
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter',
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 2. ÉCRAN : INFORMATIONS PERSONNELLES  (now accepts real data)
// ================================================================
class PersonalInfoScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String email;

  const PersonalInfoScreen({
    Key? key,
    this.name  = '',
    this.phone = '',
    this.email = '',
  }) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {

  bool _isEditing = false;
  bool _isSaving  = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _addressController        = TextEditingController(text: '');
  final _registrationController   = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    // TODO: wire to a real update endpoint when available
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() { _isEditing = false; _isSaving = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Informations mises à jour avec succès'),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Informations personnelles'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
          )
              : TextButton(
            onPressed: () {
              if (_isEditing) _saveChanges();
              else setState(() => _isEditing = true);
            },
            child: Text(_isEditing ? 'Enregistrer' : 'Modifier',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: const Icon(Icons.person,
                            size: 50, color: Color(0xFF1E3A8A)),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_nameController.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations de base',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  _buildField(
                      icon: Icons.person_outline,
                      label: 'Nom complet / Entreprise',
                      controller: _nameController,
                      enabled: _isEditing),
                  const SizedBox(height: 16),
                  _buildField(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      controller: _addressController,
                      enabled: _isEditing),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Documents légaux',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  _buildField(
                      icon: Icons.business_outlined,
                      label: 'Numéro de registre commercial',
                      controller: _registrationController,
                      enabled: _isEditing),
                  const SizedBox(height: 16),
                  _buildDocumentButton(
                      icon: Icons.upload_file,
                      label: 'Registre commercial',
                      status: 'Vérifié',
                      statusColor: Colors.green),
                  const SizedBox(height: 12),
                  _buildDocumentButton(
                      icon: Icons.upload_file,
                      label: 'Carte nationale',
                      status: 'Vérifié',
                      statusColor: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _buildField(
      {required IconData icon,
        required String label,
        required TextEditingController controller,
        bool enabled = false,
        TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: enabled
            ? (isDark
            ? const Color(0xFF1E3A8A).withOpacity(0.2)
            : Colors.blue[50])
            : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
                width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
      ),
    );
  }

  Widget _buildDocumentButton(
      {required IconData icon,
        required String label,
        required String status,
        required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface))),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}




// ============================================================
// CAMION MODEL
// ============================================================
class Camion {
  final String id;
  final String name;
  final String plate;
  final int capacity;
  final String status;
  final String model;
  final String year;
  final String lastService;
  final String nextService;

  Camion({
    required this.id,
    required this.name,
    required this.plate,
    required this.capacity,
    required this.status,
    required this.model,
    required this.year,
    required this.lastService,
    required this.nextService,
  });

  factory Camion.fromJson(Map<String, dynamic> json) => Camion(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    plate: json['plate'] ?? '',
    capacity: (json['capacity'] ?? 0) is int
        ? json['capacity']
        : int.tryParse(json['capacity'].toString()) ?? 0,
    status: json['status'] ?? 'Actif',
    model: json['model'] ?? '',
    year: json['year'] ?? '',
    lastService: json['lastService'] ?? '',
    nextService: json['nextService'] ?? '',
  );
}

// ============================================================
// MES CAMIONS SCREEN
// ============================================================
class MyCamionsScreen extends StatefulWidget {
  final String token;

  const MyCamionsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MyCamionsScreen> createState() => _MyCamionsScreenState();
}

class _MyCamionsScreenState extends State<MyCamionsScreen> {
  List<Camion> trucks = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  Future<void> _loadTrucks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final data = await ApiService.getMyCamions();
    if (!mounted) return;

    setState(() {
      isLoading = false;
      trucks = data.map((e) => Camion.fromJson(e)).toList();
    });
  }

  void _showAddTruckDialog({Camion? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddTruckBottomSheet(
        token: widget.token,
        existing: existing,
        onAdded: _loadTrucks, // refresh list after add/edit
      ),
    );
  }

  Future<void> _confirmDelete(Camion truck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le camion'),
        content: Text('Voulez-vous vraiment supprimer "${truck.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await ApiService.deleteCamion(truck.id);
    if (!mounted) return;

    if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${res['error']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camion supprimé avec succès')),
      );
      _loadTrucks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes camions'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTruckDialog(),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un camion'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTrucks,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadTrucks,
        color: const Color(0xFF1E3A8A),
        child: trucks.isEmpty
            ? ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun camion enregistré',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),
              ...trucks
                  .map((truck) => _buildTruckCard(truck))
                  .toList(),
              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalCapacity = trucks.fold(0, (sum, t) => sum + t.capacity);
    final activeCount = trucks.where((t) => t.status == 'Actif').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${trucks.length}', 'Camions', Icons.local_shipping),
          _buildSummaryItem('$activeCount', 'Actifs', Icons.check_circle_outline),
          _buildSummaryItem('$totalCapacity L', 'Capacité totale', Icons.water_drop_outlined),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTruckCard(Camion truck) {
    final isActive = truck.status == 'Actif';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping,
                      color: Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truck.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(truck.model,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    truck.status,
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTruckDetail(Icons.pin_outlined, 'Immatriculation', truck.plate),
                const SizedBox(height: 12),
                _buildTruckDetail(
                    Icons.water_drop_outlined, 'Capacité', '${truck.capacity} L'),
                const SizedBox(height: 12),
                _buildTruckDetail(Icons.calendar_today_outlined, 'Année', truck.year),
                const SizedBox(height: 12),
                _buildTruckDetail(
                    Icons.build_outlined, 'Dernier entretien', truck.lastService),
                const SizedBox(height: 12),
                _buildTruckDetail(
                    Icons.event_outlined, 'Prochain entretien', truck.nextService),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddTruckDialog(existing: truck),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Historique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: () => _confirmDelete(truck),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Supprimer',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AddTruckBottomSheet extends StatefulWidget {
  final String token;
  final Camion? existing;       // null = add mode, not null = edit mode
  final VoidCallback onAdded;

  const AddTruckBottomSheet({
    Key? key,
    required this.token,
    required this.onAdded,
    this.existing,
  }) : super(key: key);

  @override
  State<AddTruckBottomSheet> createState() => _AddTruckBottomSheetState();
}

class _AddTruckBottomSheetState extends State<AddTruckBottomSheet> {
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  bool isLoading = false;

  bool get isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Prefill if editing
    if (isEditMode) {
      _nameController.text = widget.existing!.name;
      _plateController.text = widget.existing!.plate;
      _capacityController.text = widget.existing!.capacity.toString();
      _modelController.text = widget.existing!.model;
      _yearController.text = widget.existing!.year;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _capacityController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        _plateController.text.isEmpty ||
        _capacityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic> res;

    if (isEditMode) {
      res = await ApiService.updateCamion(
        widget.existing!.id,
        name: _nameController.text.trim(),
        plate: _plateController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
      );
    } else {
      res = await ApiService.addCamion(
        name: _nameController.text.trim(),
        plate: _plateController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
      );
    }

    setState(() => isLoading = false);

    if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${res['error']}')),
      );
    } else {
      Navigator.pop(context);
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditMode ? 'Modifier le camion' : 'Ajouter un camion',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInput('Nom du camion *', Icons.local_shipping_outlined, _nameController),
          const SizedBox(height: 12),
          _buildInput('Immatriculation *', Icons.pin_outlined, _plateController),
          const SizedBox(height: 12),
          _buildInput('Capacité (litres) *', Icons.water_drop_outlined, _capacityController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildInput('Modèle', Icons.directions_car_outlined, _modelController),
          const SizedBox(height: 12),
          _buildInput('Année', Icons.calendar_today_outlined, _yearController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(
                  isEditMode ? 'Modifier' : 'Ajouter',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
      ),
    );
  }
}
// ============================================================
// 3. PAIEMENTS & FACTURATION
// ============================================================
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> transactions = [
    {
      'id': 'TXN-001',
      'date': '15/03/2025',
      'amount': 12500,
      'type': 'credit',
      'description': 'Livraison #LV-2341',
      'status': 'Complété',
    },
    {
      'id': 'TXN-002',
      'date': '14/03/2025',
      'amount': 8200,
      'type': 'credit',
      'description': 'Livraison #LV-2338',
      'status': 'Complété',
    },
    {
      'id': 'TXN-003',
      'date': '13/03/2025',
      'amount': 2000,
      'type': 'debit',
      'description': 'Commission plateforme',
      'status': 'Prélevé',
    },
    {
      'id': 'TXN-004',
      'date': '12/03/2025',
      'amount': 9750,
      'type': 'credit',
      'description': 'Livraison #LV-2330',
      'status': 'Complété',
    },
    {
      'id': 'TXN-005',
      'date': '10/03/2025',
      'amount': 15000,
      'type': 'withdrawal',
      'description': 'Virement bancaire',
      'status': 'Traité',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paiements & Facturation'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Facturation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildBillingTab(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Solde actuel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solde disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '28 450 DZD',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: const Text('Retirer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.receipt_outlined, size: 18),
                        label: const Text('Relevé'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats rapides
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Ce mois', '30 450 DZD', Icons.trending_up, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat('Commission', '2 000 DZD', Icons.percent, Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Transactions
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Historique des transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ...transactions.map((t) => _buildTransactionItem(t)).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    Color color;
    IconData icon;
    String sign;

    switch (t['type']) {
      case 'credit':
        color = Colors.green;
        icon = Icons.arrow_downward;
        sign = '+';
        break;
      case 'debit':
        color = Colors.red;
        icon = Icons.arrow_upward;
        sign = '-';
        break;
      default:
        color = Colors.blue;
        icon = Icons.swap_horiz;
        sign = '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['description'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(t['date'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${t['amount']} DZD',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t['status'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informations de compte bancaire
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Compte bancaire',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CCP', style: TextStyle(color: Colors.white, fontSize: 14)),
                          Icon(Icons.account_balance, color: Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '0021 4568 9012 3456',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ahmed Transport Eau',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Factures récentes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factures récentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInvoiceItem('FAC-2025-03', 'Mars 2025', '30 450 DZD', 'Payée'),
                _buildInvoiceItem('FAC-2025-02', 'Février 2025', '25 200 DZD', 'Payée'),
                _buildInvoiceItem('FAC-2025-01', 'Janvier 2025', '18 750 DZD', 'Payée'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(String id, String period, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(period, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, color: Color(0xFF1E3A8A), size: 20),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. NOTIFICATIONS
// ============================================================
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  Map<String, bool> notifSettings = {
    'new_order': true,
    'order_cancelled': true,
    'payment_received': true,
    'maintenance_reminder': true,
    'rating_received': false,
    'promotions': false,
    'system_updates': true,
    'weekly_report': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Activer tout
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications activées',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Personnalisez vos préférences ci-dessous',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notifSettings.values.any((v) => v),
                    onChanged: (val) {
                      setState(() {
                        notifSettings.updateAll((k, v) => val);
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white30,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildNotifCategory(
              'Commandes',
              Icons.delivery_dining,
              [
                _buildNotifItem('new_order', 'Nouvelle commande', 'Quand vous recevez une commande'),
                _buildNotifItem('order_cancelled', 'Annulation de commande', 'Quand une commande est annulée'),
              ],
            ),

            const SizedBox(height: 16),

            _buildNotifCategory(
              'Paiements',
              Icons.payment,
              [
                _buildNotifItem('payment_received', 'Paiement reçu', 'Confirmation de paiement'),
              ],
            ),

            const SizedBox(height: 16),

            _buildNotifCategory(
              'Véhicules',
              Icons.local_shipping,
              [
                _buildNotifItem('maintenance_reminder', 'Rappel entretien', 'Rappel avant la date d\'entretien'),
              ],
            ),

            const SizedBox(height: 16),

            _buildNotifCategory(
              'Autres',
              Icons.more_horiz,
              [
                _buildNotifItem('rating_received', 'Nouvelle évaluation', 'Quand un client vous évalue'),
                _buildNotifItem('promotions', 'Promotions & Offres', 'Offres spéciales de la plateforme'),
                _buildNotifItem('system_updates', 'Mises à jour système', 'Annonces importantes'),
                _buildNotifItem('weekly_report', 'Rapport hebdomadaire', 'Résumé de votre activité'),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCategory(String title, IconData icon, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildNotifItem(String key, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          Switch(
            value: notifSettings[key] ?? false,
            onChanged: (val) => setState(() => notifSettings[key] = val),
            activeColor: const Color(0xFF1E3A8A),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. LANGUE
// ============================================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'fr';

  final List<Map<String, String>> languages = [
    {'code': 'fr', 'name': 'Français', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'Arabe', 'native': 'العربية', 'flag': '🇩🇿'},
    {'code': 'en', 'name': 'Anglais', 'native': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Langue'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choisissez la langue de l\'application',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: languages.asMap().entries.map((entry) {
                  final lang = entry.value;
                  final isLast = entry.key == languages.length - 1;
                  final isSelected = _selectedLanguage == lang['code'];

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedLanguage = lang['code']!),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['name']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      lang['native']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E3A8A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                                )
                              else
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, indent: 72, color: Colors.grey[200]),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Appliquer le changement de langue
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Langue mise à jour'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Appliquer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. AIDE & SUPPORT
// ============================================================
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'Comment ajouter un nouveau camion ?',
      'answer':
      'Allez dans "Mes camions" puis cliquez sur le bouton "Ajouter un camion". Remplissez les informations requises et validez.',
      'isOpen': false,
    },
    {
      'question': 'Comment recevoir mes paiements ?',
      'answer':
      'Les paiements sont versés automatiquement sur votre compte CCP après chaque livraison confirmée. Les délais sont de 24 à 48h ouvrables.',
      'isOpen': false,
    },
    {
      'question': 'Comment annuler une livraison ?',
      'answer':
      'Vous pouvez annuler une livraison depuis l\'écran de détail de la commande. Notez qu\'une annulation fréquente peut affecter votre note.',
      'isOpen': false,
    },
    {
      'question': 'Que faire en cas de panne du camion ?',
      'answer':
      'Contactez immédiatement le support via le bouton d\'urgence. Informez aussi le client via l\'application. Notre équipe vous assistera.',
      'isOpen': false,
    },
    {
      'question': 'Comment améliorer ma note ?',
      'answer':
      'Livrez dans les délais, maintenez la qualité de l\'eau, soyez professionnel avec les clients et répondez rapidement aux commandes.',
      'isOpen': false,
    },
  ];
  final TextEditingController _ticketController = TextEditingController();

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Contact rapide
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notre équipe est disponible 7j/7 de 8h à 20h',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactBtn(
                          Icons.phone,
                          'Appeler',
                              () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactBtn(
                          Icons.chat_bubble_outline,
                          'Chat',
                              () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactBtn(
                          Icons.email_outlined,
                          'Email',
                              () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Urgence
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assistance d\'urgence',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                          Text(
                            'Panne, accident ou problème critique',
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.red),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FAQ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions fréquentes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...faqs.asMap().entries.map((entry) {
                    return _buildFaqItem(entry.key, entry.value);
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Envoyer un ticket
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signaler un problème',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ticketController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre problème...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = _ticketController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez décrire votre problème'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        final result = await ApiService.submitTicket(
                          sujet:   'Support client',
                          message: text,
                        );

                        if (!mounted) return;
                        Navigator.pop(context); // close loading dialog

                        if (result['error'] != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['error']),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        _ticketController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Réclamation envoyée avec succès !'),
                            ]),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Envoyer le ticket',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index, Map<String, dynamic> faq) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              faqs[index]['isOpen'] = !faqs[index]['isOpen'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF1E3A8A),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq['question'],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (faq['isOpen']) ...[
                        const SizedBox(height: 8),
                        Text(
                          faq['answer'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  faq['isOpen'] ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (index < faqs.length - 1)
          Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}