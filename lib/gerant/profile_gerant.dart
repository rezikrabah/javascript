import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test2/gerant/Info.dart';
import 'package:test2/gerant/gerant_history.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/main.dart';
import '../fournisseur/provider_home_screen_FINAL.dart';
import '../services/api_service.dart';


class ProfileGerantScreen extends StatefulWidget {
  const ProfileGerantScreen({super.key});

  @override
  State<ProfileGerantScreen> createState() => _ProfileGerantScreenState();
}

class _ProfileGerantScreenState extends State<ProfileGerantScreen> {
  static const Color kPrimaryDark = Color(0xFF0B3C49);
  static const Color kAccent = Color(0xFF1E88E5);
  static const Color kLogout = Color(0xFFE53935);

  bool _notifEnabled = true;
  String? _gerantCode;
  String _nom = '';
  String _email = '';
  int _chauffeurCount = 0;
  bool _loadingInfo = true;
  String? _secondaryRole;

  @override
  void initState() {
    super.initState();
    _loadGerantInfo();
  }

  Future<void> _loadGerantInfo() async {
    final data = await ApiService.getGerantInfo();
    if (mounted) {
      setState(() {
        _gerantCode = data['gerantInfo']?['code'] ?? 'N/A';
        _nom = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
        _email = data['email'] ?? '';
        _chauffeurCount = (data['gerantInfo']?['chauffeurs'] as List?)?.length ?? 0;
        _loadingInfo = false;
        _secondaryRole = data['secondaryRole'];
      });
    }
  }
  Future<void> _activateChauffeurRole() async {
    // Confirm dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Devenir Chauffeur'),
        content: const Text('Voulez-vous activer le rôle chauffeur sur ce compte ? Vous pourrez accéder aux deux tableaux de bord.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3C49)),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.addSecondaryRole();

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
      return;
    }

    // Save new token if returned
    if (result['token'] != null) {
      ApiService.token = result['token']; // ✅ matches how your ApiService works
    }

    setState(() => _secondaryRole = 'chauffeur');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rôle chauffeur activé !'), backgroundColor: Colors.green),
    );

    // In ProfileGerantScreen, change both navigation calls to:
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProviderHomeScreen(isGerant: true)));
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryDark,
        elevation: 0,
        title: const Text('Tableau de Bord Gérant',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingInfo
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: kPrimaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.business, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                Text(_nom.isEmpty ? 'Gérant' : _nom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(_email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),

                // GERANT CODE
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _gerantCode ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Code copié !'),
                        ]),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Code: ${_gerantCode ?? '...'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Appuyez pour copier et partager',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),

            const SizedBox(height: 20),

            // CHIFFRE D'AFFAIRES + HISTORIQUE
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kPrimaryDark, kAccent]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: kAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chiffre d\'affaires (Aujourd\'hui)',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                          SizedBox(height: 8),
                          Text('45 000 DZD',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Basé sur les livraisons terminées',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        ]),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const geranthistory())),
                  child: _buildStatCard(
                      'Voir', 'Historique', Icons.history, context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // STATS FLOTTE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                _buildStatCard('$_chauffeurCount', 'Chauffeurs',
                    Icons.people, context),
                const SizedBox(width: 10),
                _buildStatCard(
                    '$_chauffeurCount', 'Camions', Icons.local_shipping, context),
              ]),
            ),

            const SizedBox(height: 25),

            // PARAMÈTRES
            _buildSectionLabel('ADMINISTRATION'),
            _buildSettingsBox([
              _buildTile(
                  Icons.notifications_active,
                  'Notifications',
                  'Gérer les Notifications',
                  context,
                  trailing: Switch(
                      value: _notifEnabled,
                      onChanged: (v) =>
                          setState(() => _notifEnabled = v),
                      activeColor: kAccent)),
              ValueListenableBuilder<bool>(
                valueListenable: themeNotifier,
                builder: (_, isDarkTheme, __) => _buildTile(
                    isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                    'Thème',
                    isDarkTheme ? 'Sombre' : 'Clair',
                    context,
                    onTap: () =>
                    themeNotifier.value = !themeNotifier.value),
              ),
            ], context),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const gerantinfos())),
              icon: const Icon(Icons.person),
              label: const Text('INFORMATIONS PERSONNELLES'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),

            _secondaryRole == 'chauffeur'
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProviderHomeScreen(isGerant: true))),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: const Text('ACCÉDER AU MODE CHAUFFEUR',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _activateChauffeurRole,
                  icon: const Icon(Icons.local_shipping, color: Color(0xFF1E88E5)),
                  label: const Text('DEVENIR CHAUFFEUR AUSSI',
                      style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => Loginpage())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kLogout,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text('DÉCONNEXION',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(left: 25, bottom: 10),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey))));

  Widget _buildStatCard(
      String val, String label, IconData icon, BuildContext ctx) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
          child: Column(children: [
            Icon(icon, color: kAccent),
            const SizedBox(height: 5),
            Text(val,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style:
                const TextStyle(fontSize: 11, color: Colors.grey))
          ]),
        ),
      );

  Widget _buildSettingsBox(List<Widget> children, BuildContext ctx) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(children: children),
      );

  Widget _buildTile(IconData icon, String title, String sub, BuildContext ctx,
      {Widget? trailing, VoidCallback? onTap}) =>
      ListTile(
        onTap: onTap,
        leading: Icon(icon, color: kAccent),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle:
        Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 16),
      );
}