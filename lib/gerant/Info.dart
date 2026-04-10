// ================================================================
// FICHIER : profile_screen.dart
// MODE SOMBRE : Toutes les couleurs utilisent Theme.of(context)
//   → Theme.of(context).cardColor          = blanc / gris foncé
//   → Theme.of(context).scaffoldBackgroundColor = fond général
//   → Theme.of(context).colorScheme.onSurface  = couleur du texte
//   → Theme.of(context).dividerColor           = séparateurs
// ================================================================

import 'package:flutter/material.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/main.dart';



// ================================================================
// 1. ÉCRAN PRINCIPAL DU PROFIL
// ================================================================
class gerantinfos extends StatefulWidget {
  const gerantinfos({Key? key}) : super(key: key);

  @override
  State<gerantinfos> createState() => _gerantinfosState();
}

class _gerantinfosState extends State<gerantinfos> {

  final Map<String, dynamic> providerData = {
    'name': 'Ahmed Transport Eau',
    'phone': '+213 555 123 456',
    'email': 'ahmed@transporteau.dz',
    'rating': 4.8,
    'totalDeliveries': 245,
    'trucks': 2,
    'totalCapacity': 10800,
    'memberSince': 'Janvier 2024',
  };



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // scaffoldBackgroundColor s'adapte automatiquement au thème
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil gerant'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Naviguer vers paramètres avancés
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildSettingsMenu(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Le header garde son dégradé bleu dans les deux modes
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.person, size: 50, color: Color(0xFF1E3A8A)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(providerData['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${providerData['rating']} / 5.0', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          // onSurface.withOpacity = texte gris adapté aux deux modes
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Paramètres',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ),

          _buildMenuItem(icon: Icons.person_outline, title: 'Informations personnelles',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()))),
          _buildDivider(),

          _buildMenuItem(icon: Icons.local_shipping_outlined, title: 'Mes camions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCamionsScreen()))),
          _buildDivider(),

          _buildMenuItem(icon: Icons.payment_outlined, title: 'Paiements & Facturation',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()))),
          _buildDivider(),

          _buildMenuItem(icon: Icons.notifications_outlined, title: 'Notifications',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()))),
          _buildDivider(),

          _buildMenuItem(icon: Icons.language_outlined, title: 'Langue', subtitle: 'Français',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()))),
          _buildDivider(),

          _buildMenuItem(icon: Icons.help_outline, title: 'Aide & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
          _buildDivider(),

          // Bouton Mode Sombre
          ValueListenableBuilder<bool>(
            valueListenable: themeNotifier,
            builder: (context, isDark, child) {
              return _buildMenuItem(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: isDark ? 'Mode sombre' : 'Mode clair',
                subtitle: isDark ? 'Appuyer pour mode clair' : 'Appuyer pour mode sombre',
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

  Widget _buildMenuItem({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24), // placeholder, overridden below
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    // dividerColor s'adapte au thème (gris clair / gris foncé)
    return Divider(height: 1, indent: 76, endIndent: 20, color: Theme.of(context).dividerColor);
  }


}

// ================================================================
// 2. ÉCRAN : INFORMATIONS PERSONNELLES
// ================================================================
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {

  bool _isEditing = false;

  final _nameController = TextEditingController(text: 'Ahmed Transport Eau');
  final _phoneController = TextEditingController(text: '+213 555 123 456');
  final _emailController = TextEditingController(text: 'ahmed@transporteau.dz');
  final _addressController = TextEditingController(text: 'Alger, Algérie');
  final _registrationController = TextEditingController(text: 'RC-2024-00123');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations mises à jour avec succès'), backgroundColor: Colors.green),
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
          TextButton(
            onPressed: () {
              if (_isEditing) _saveChanges();
              else setState(() => _isEditing = true);
            },
            child: Text(_isEditing ? 'Enregistrer' : 'Modifier',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header bleu (identique dans les deux modes)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: const Icon(Icons.person, size: 50, color: Color(0xFF1E3A8A)),
                      ),
                      if (_isEditing)
                        Positioned(bottom: 0, right: 0,
                          child: GestureDetector(onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulaire Infos de base
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations de base', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  _buildField(icon: Icons.person_outline, label: 'Nom complet / Entreprise', controller: _nameController, enabled: _isEditing),
                  const SizedBox(height: 16),
                  _buildField(icon: Icons.phone_outlined, label: 'Téléphone', controller: _phoneController, enabled: _isEditing, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(icon: Icons.email_outlined, label: 'Email', controller: _emailController, enabled: _isEditing, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(icon: Icons.location_on_outlined, label: 'Adresse', controller: _addressController, enabled: _isEditing),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Formulaire Documents légaux
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Documents légaux', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  _buildField(icon: Icons.business_outlined, label: 'Numéro de registre commercial', controller: _registrationController, enabled: _isEditing),
                  const SizedBox(height: 16),
                  _buildDocumentButton(icon: Icons.upload_file, label: 'Registre commercial', status: 'Vérifié', statusColor: Colors.green),
                  const SizedBox(height: 12),
                  _buildDocumentButton(icon: Icons.upload_file, label: 'Carte nationale', status: 'Vérifié', statusColor: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Conteneur carte adapté au thème
  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildField({required IconData icon, required String label, required TextEditingController controller, bool enabled = false, TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        // Fond différent selon mode édition ET thème
        fillColor: enabled
            ? (isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : Colors.blue[50])
            : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
      ),
    );
  }

  Widget _buildDocumentButton({required IconData icon, required String label, required String status, required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 3. ÉCRAN : MES CAMIONS
// ================================================================
class MyCamionsScreen extends StatefulWidget {
  const MyCamionsScreen({Key? key}) : super(key: key);

  @override
  State<MyCamionsScreen> createState() => _MyCamionsScreenState();
}

class _MyCamionsScreenState extends State<MyCamionsScreen> {

  final List<Map<String, dynamic>> trucks = [
    {'id': '1', 'name': 'Camion 1', 'plate': '16-001-231', 'capacity': 5400, 'status': 'Actif', 'model': 'Mercedes Actros', 'year': '2021', 'lastService': '15/01/2025', 'nextService': '15/07/2025'},
    {'id': '2', 'name': 'Camion 2', 'plate': '16-002-418', 'capacity': 5400, 'status': 'En maintenance', 'model': 'MAN TGS', 'year': '2019', 'lastService': '10/02/2025', 'nextService': '10/08/2025'},
  ];

  void _showAddTruckDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddTruckBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mes camions'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTruckDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un camion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Résumé (dégradé bleu, identique dans les deux modes)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('${trucks.length}', 'Camions', Icons.local_shipping),
                  _buildSummaryItem('${trucks.where((t) => t['status'] == 'Actif').length}', 'Actifs', Icons.check_circle_outline),
                  _buildSummaryItem('${trucks.fold(0, (sum, t) => sum + (t['capacity'] as int))} L', 'Capacité totale', Icons.water_drop_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...trucks.map((truck) => _buildTruckCard(truck)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTruckCard(Map<String, dynamic> truck) {
    final isActive = truck['status'] == 'Actif';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_shipping, color: Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truck['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      Text(truck['model'], style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(truck['status'], style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTruckDetail(Icons.pin_outlined, 'Immatriculation', truck['plate']),
                const SizedBox(height: 12),
                _buildTruckDetail(Icons.water_drop_outlined, 'Capacité', '${truck['capacity']} L'),
                const SizedBox(height: 12),
                _buildTruckDetail(Icons.calendar_today_outlined, 'Année', truck['year']),
                const SizedBox(height: 12),
                _buildTruckDetail(Icons.build_outlined, 'Dernier entretien', truck['lastService']),
                const SizedBox(height: 12),
                _buildTruckDetail(Icons.event_outlined, 'Prochain entretien', truck['nextService']),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Historique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
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
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

// ================================================================
// 4. FORMULAIRE AJOUT CAMION
// ================================================================
class AddTruckBottomSheet extends StatelessWidget {
  const AddTruckBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajouter un camion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 20),
          _buildInput(context, 'Nom du camion', Icons.local_shipping_outlined),
          const SizedBox(height: 12),
          _buildInput(context, 'Immatriculation', Icons.pin_outlined),
          const SizedBox(height: 12),
          _buildInput(context, 'Capacité (litres)', Icons.water_drop_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildInput(context, 'Modèle', Icons.directions_car_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Ajouter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, String label, IconData icon, {TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
      ),
    );
  }
}

// ================================================================
// 5. ÉCRAN : PAIEMENTS & FACTURATION
// ================================================================
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final List<Map<String, dynamic>> transactions = [
    {'id': 'TXN-001', 'date': '15/03/2025', 'amount': 12500, 'type': 'credit', 'description': 'Livraison #LV-2341', 'status': 'Complété'},
    {'id': 'TXN-002', 'date': '14/03/2025', 'amount': 8200, 'type': 'credit', 'description': 'Livraison #LV-2338', 'status': 'Complété'},
    {'id': 'TXN-003', 'date': '13/03/2025', 'amount': 2000, 'type': 'debit', 'description': 'Commission plateforme', 'status': 'Prélevé'},
    {'id': 'TXN-004', 'date': '12/03/2025', 'amount': 9750, 'type': 'credit', 'description': 'Livraison #LV-2330', 'status': 'Complété'},
    {'id': 'TXN-005', 'date': '10/03/2025', 'amount': 15000, 'type': 'withdrawal', 'description': 'Virement bancaire', 'status': 'Traité'},
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          tabs: const [Tab(text: 'Transactions'), Tab(text: 'Facturation')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildTransactionsTab(), _buildBillingTab()]),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Solde (dégradé bleu, identique dans les deux modes)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('28 450 DZD', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_downward, size: 18), label: const Text('Retirer'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.receipt_outlined, size: 18), label: const Text('Relevé'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildQuickStat('Ce mois', '30 450 DZD', Icons.trending_up, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickStat('Commission', '2 000 DZD', Icons.percent, Colors.red)),
            ],
          ),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft,
              child: Text('Historique des transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ])),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    Color color; IconData icon; String sign;
    switch (t['type']) {
      case 'credit':  color = Colors.green; icon = Icons.arrow_downward; sign = '+'; break;
      case 'debit':   color = Colors.red;   icon = Icons.arrow_upward;   sign = '-'; break;
      default:        color = Colors.blue;  icon = Icons.swap_horiz;     sign = '-';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['description'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            Text(t['date'], style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$sign${t['amount']} DZD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(t['status'], style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))),
          ]),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Compte bancaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  TextButton(onPressed: () {}, child: const Text('Modifier')),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CCP', style: TextStyle(color: Colors.white, fontSize: 14)), Icon(Icons.account_balance, color: Colors.white70)]),
                    SizedBox(height: 16),
                    Text('0021 4568 9012 3456', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    SizedBox(height: 8),
                    Text('Ahmed Transport Eau', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Factures récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(id, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            Text(period, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Payée', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(width: 8),
          IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined, color: Color(0xFF1E3A8A), size: 20), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}

// ================================================================
// 6. ÉCRAN : PARAMÈTRES NOTIFICATIONS
// ================================================================
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {

  Map<String, bool> notifSettings = {
    'new_order': true, 'order_cancelled': true, 'payment_received': true,
    'maintenance_reminder': true, 'rating_received': false,
    'promotions': false, 'system_updates': true, 'weekly_report': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Notifications activées', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Personnalisez vos préférences ci-dessous', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                  Switch(
                    value: notifSettings.values.any((v) => v),
                    onChanged: (val) => setState(() => notifSettings.updateAll((k, v) => val)),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNotifCategory('Commandes', Icons.delivery_dining, [
              _buildNotifItem('new_order', 'Nouvelle commande', 'Quand vous recevez une commande'),
              _buildNotifItem('order_cancelled', 'Annulation de commande', 'Quand une commande est annulée'),
            ]),
            const SizedBox(height: 16),
            _buildNotifCategory('Paiements', Icons.payment, [
              _buildNotifItem('payment_received', 'Paiement reçu', 'Confirmation de paiement'),
            ]),
            const SizedBox(height: 16),
            _buildNotifCategory('Véhicules', Icons.local_shipping, [
              _buildNotifItem('maintenance_reminder', 'Rappel entretien', "Rappel avant la date d'entretien"),
            ]),
            const SizedBox(height: 16),
            _buildNotifCategory('Autres', Icons.more_horiz, [
              _buildNotifItem('rating_received', 'Nouvelle évaluation', 'Quand un client vous évalue'),
              _buildNotifItem('promotions', 'Promotions & Offres', 'Offres spéciales de la plateforme'),
              _buildNotifItem('system_updates', 'Mises à jour système', 'Annonces importantes'),
              _buildNotifItem('weekly_report', 'Rapport hebdomadaire', 'Résumé de votre activité'),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCategory(String title, IconData icon, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ])),
          Divider(height: 1, color: Theme.of(context).dividerColor),
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ])),
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

// ================================================================
// 7. ÉCRAN : CHOIX DE LA LANGUE
// ================================================================
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Langue'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.language, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 12),
                Expanded(child: Text("Choisissez la langue de l'application",
                    style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF1E3A8A)))),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
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
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(lang['name']!, style: TextStyle(fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1E3A8A) : Theme.of(context).colorScheme.onSurface)),
                                Text(lang['native']!, style: TextStyle(fontSize: 13,
                                    color: isSelected ? const Color(0xFF2563EB) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              ])),
                              if (isSelected)
                                Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 18))
                              else
                                Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).dividerColor))),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Langue mise à jour'), backgroundColor: Colors.green));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('Appliquer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 8. ÉCRAN : AIDE & SUPPORT
// ================================================================
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {

  final List<Map<String, dynamic>> faqs = [
    {'question': 'Comment ajouter un nouveau camion ?', 'answer': 'Allez dans "Mes camions" puis cliquez sur le bouton "Ajouter un camion". Remplissez les informations requises et validez.', 'isOpen': false},
    {'question': 'Comment recevoir mes paiements ?', 'answer': 'Les paiements sont versés automatiquement sur votre compte CCP après chaque livraison confirmée. Les délais sont de 24 à 48h ouvrables.', 'isOpen': false},
    {'question': 'Comment annuler une livraison ?', 'answer': "Vous pouvez annuler depuis l'écran de détail de la commande. Une annulation fréquente peut affecter votre note.", 'isOpen': false},
    {'question': 'Que faire en cas de panne du camion ?', 'answer': "Contactez immédiatement le support via le bouton d'urgence. Informez aussi le client via l'application.", 'isOpen': false},
    {'question': 'Comment améliorer ma note ?', 'answer': "Livrez dans les délais, maintenez la qualité de l'eau, soyez professionnel et répondez rapidement aux commandes.", 'isOpen': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Aide & Support'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Contacts rapides (dégradé bleu)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text("Besoin d'aide ?", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Notre équipe est disponible 7j/7 de 8h à 20h', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _buildContactBtn(Icons.phone, 'Appeler', () {})),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContactBtn(Icons.chat_bubble_outline, 'Chat', () {})),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContactBtn(Icons.email_outlined, 'Email', () {})),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton urgence (rouge, identique dans les deux modes)
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.emergency, color: Colors.red, size: 24)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Assistance d'urgence", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text('Panne, accident ou problème critique', style: TextStyle(fontSize: 13, color: Colors.red)),
                    ])),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Questions fréquentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  ...faqs.asMap().entries.map((entry) => _buildFaqItem(entry.key, entry.value)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ticket support
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signaler un problème', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLines: 4,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre problème...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: const Text('Envoyer le ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white30)),
        child: Column(children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]),
      ),
    );
  }

  Widget _buildFaqItem(int index, Map<String, dynamic> faq) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => faqs[index]['isOpen'] = !faqs[index]['isOpen']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.help_outline, color: Color(0xFF1E3A8A), size: 16)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(faq['question'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  if (faq['isOpen']) ...[
                    const SizedBox(height: 8),
                    Text(faq['answer'], style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5)),
                  ],
                ])),
                Icon(faq['isOpen'] ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
          ),
        ),
        if (index < faqs.length - 1) Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}