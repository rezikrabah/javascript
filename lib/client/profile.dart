import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test2/client/historique.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/main.dart'; // Pour themeNotifier
import 'clientpage.dart';
import 'commandes.dart';
import 'package:test2/client/suivi.dart';
import '../services/api_service.dart';

class profile extends StatefulWidget {
  const profile({super.key});

  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {

  // --- Palette de couleurs fixes (header, accent) ---
  static const Color kPrimaryDark   = Color(0xFF0B3C49);
  static const Color kAccent        = Color(0xFF1E88E5);
  static const Color kAccentLight   = Color(0xFF6FB6C3);
  static const Color kLogout        = Color(0xFFE53935);

  final String userName    = 'rezik rabah';
  final String userEmail   = 'rezikrabah1@gmail.com';
  final String userPhone   = '+213 555 123 456';
  final String memberSince = 'Membre depuis 2023';

  // Switch notifications local
  bool _notifEnabled = true;

  @override
  Widget build(BuildContext context) {
    // isDark = true si mode sombre activé
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Fond adapté au thème
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,

      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: kPrimaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26, color: Colors.white),
            onPressed: () {
              // TODO: Naviguer vers paramètres avancés
            },
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [

            // ── Header avatar (garde le fond sombre dans les 2 modes) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                color: kPrimaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: kAccentLight,
                        child: const Icon(Icons.person, color: Colors.white, size: 48),
                      ),
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: kAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.edit, color: Colors.white, size: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: kAccentLight.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                    child: Text(memberSince, style: const TextStyle(color: kAccentLight, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats rapides ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard('12', 'Commandes', Icons.indeterminate_check_box_rounded),
                  const SizedBox(width: 12),
                  _buildStatCard('9', 'Livrées', Icons.check_circle_outline),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Section PARAMÈTRES ───────────────────────────
            _buildSectionLabel('PARAMÈTRES'),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [

                    // Informations personnelles
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: kAccent,
                      title: 'Informations personnelles',
                      subtitle: 'Nom, email, téléphone',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoClientScreen())),
                      isFirst: true,
                    ),
                    _buildDivider(),

                    // Paiements & Facturation
                    _buildSettingsTile(
                      icon: Icons.credit_card_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF43A047),
                      title: 'Paiements & Facturation',
                      subtitle: 'Méthodes de paiement, factures',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsClientScreen())),
                    ),
                    _buildDivider(),

                    // Notifications (avec switch)
                    _buildSettingsTile(
                      icon: Icons.notifications_none_outlined,
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFFF8F00),
                      title: 'Notifications',
                      subtitle: 'Alertes, rappels, promotions',
                      onTap: () {},
                      trailing: Switch(
                        value: _notifEnabled,
                        onChanged: (v) => setState(() => _notifEnabled = v),
                        activeColor: kAccent,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    _buildDivider(),

                    // Langue
                    _buildSettingsTile(
                      icon: Icons.language_outlined,
                      iconBg: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF8E24AA),
                      title: 'Langue',
                      subtitle: 'Français',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageClientScreen())),
                    ),
                    _buildDivider(),

                    // ── Bouton Mode Sombre ──────────────────────
                    // ValueListenableBuilder écoute themeNotifier depuis main.dart
                    // Se reconstruit automatiquement quand le thème change
                    ValueListenableBuilder<bool>(
                      valueListenable: themeNotifier,
                      builder: (context, isDarkMode, child) {
                        return _buildSettingsTile(
                          icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          iconBg: isDarkMode
                              ? const Color(0xFF263238)
                              : const Color(0xFFE3F2FD),
                          iconColor: isDarkMode ? Colors.white70 : kAccent,
                          title: isDarkMode ? 'Mode sombre' : 'Mode clair',
                          subtitle: isDarkMode ? 'Appuyer pour mode clair' : 'Appuyer pour mode sombre',
                          onTap: () {
                            // Inverse le thème → toute l'app change instantanément
                            themeNotifier.value = !themeNotifier.value;
                          },
                          isLast: true,
                        );
                      },
                    ),
                    // ───────────────────────────────────────────

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section SUPPORT ──────────────────────────────
            _buildSectionLabel('SUPPORT'),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: kAccent,
                      title: 'Aide & Support',
                      subtitle: 'FAQ, contacter le support',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpClientScreen())),
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF43A047),
                      title: 'Confidentialité',
                      subtitle: 'Politique de confidentialité',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyClientScreen())),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Bouton déconnexion ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Loginpage()),
                          (route) => false, // Supprime tout l'historique de navigation
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  label: const Text('SE DÉCONNECTER',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLogout,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: kLogout.withOpacity(0.4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── FAB (Home) ───────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryDark,
        shape: const CircleBorder(),
        mini: true,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => clientpage())),
        child: const Icon(CupertinoIcons.home, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom Navigation ────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        // Fond adapté au thème
        color: Theme.of(context).cardColor,
        elevation: 12,
        notchMargin: 8,
        height: 72,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Suivi désactivé (fichier manquant)
            _buildNavItem(CupertinoIcons.map, 'Suivi', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => suivi()));
            }),
            _buildNavItem(CupertinoIcons.cube_box_fill, 'Commandes', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => commandes(clientId: int.tryParse(ApiService.userId ?? '0') ?? 0,)));
            }),
            const SizedBox(width: 40), // Espace pour le FAB
            _buildNavItem(CupertinoIcons.clock, 'Historique', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => historique()));
            }),
            _buildNavItem(CupertinoIcons.profile_circled, 'Profil', () {}, isActive: true),
          ],
        ),
      ),
    );
  }

  // ── Titre de section (PARAMÈTRES, SUPPORT...) ────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }

  // ── Carte de statistique ─────────────────────────────────
  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kAccent, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Élément du menu paramètres ───────────────────────────
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              trailing ?? Icon(CupertinoIcons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Séparateur ───────────────────────────────────────────
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }

  // ── Item de navigation bas ───────────────────────────────
  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    final color = isActive ? kAccent : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ================================================================
// ÉCRANS CONNECTÉS AU MENU
// ================================================================

// ── Informations personnelles ────────────────────────────────────
class PersonalInfoClientScreen extends StatefulWidget {
  const PersonalInfoClientScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoClientScreen> createState() => _PersonalInfoClientScreenState();
}

class _PersonalInfoClientScreenState extends State<PersonalInfoClientScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController(text: 'rezik rabah');
  final _emailController = TextEditingController(text: 'rezikrabah1@gmail.com');
  final _phoneController = TextEditingController(text: '+213 555 123 456');
  final _addressController = TextEditingController(text: 'Alger, Algérie');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Informations personnelles'),
        backgroundColor: const Color(0xFF0B3C49),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? 'Enregistrer' : 'Modifier',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildField(context, Icons.person_outline, 'Nom complet', _nameController, isDark),
                  const SizedBox(height: 16),
                  _buildField(context, Icons.email_outlined, 'Email', _emailController, isDark, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(context, Icons.phone_outlined, 'Téléphone', _phoneController, isDark, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(context, Icons.location_on_outlined, 'Adresse', _addressController, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, IconData icon, String label, TextEditingController controller, bool isDark, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        filled: true,
        fillColor: _isEditing ? (isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : Colors.blue[50]) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0B3C49), width: 2)),
      ),
    );
  }
}

// ── Paiements & Facturation ──────────────────────────────────────
class PaymentsClientScreen extends StatelessWidget {
  const PaymentsClientScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paiements & Facturation'),
        backgroundColor: const Color(0xFF0B3C49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Solde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0B3C49), Color(0xFF1E88E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('0 DZD', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  Text('Historique des paiements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  Center(child: Column(children: [
                    Icon(Icons.receipt_long_outlined, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('Aucun paiement pour l\'instant', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Langue ───────────────────────────────────────────────────────
class LanguageClientScreen extends StatefulWidget {
  const LanguageClientScreen({Key? key}) : super(key: key);

  @override
  State<LanguageClientScreen> createState() => _LanguageClientScreenState();
}

class _LanguageClientScreenState extends State<LanguageClientScreen> {
  String _selected = 'fr';
  final List<Map<String, String>> languages = [
    {'code': 'fr', 'name': 'Français', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'Arabe', 'native': 'العربية', 'flag': '🇩🇿'},
    {'code': 'en', 'name': 'Anglais', 'native': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Langue'), backgroundColor: const Color(0xFF0B3C49), foregroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                  final isSelected = _selected == lang['code'];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selected = lang['code']!),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(lang['name']!, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF1E88E5) : Theme.of(context).colorScheme.onSurface)),
                                Text(lang['native']!, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              ])),
                              if (isSelected)
                                Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF0B3C49), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 18))
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3C49), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('Appliquer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aide & Support ───────────────────────────────────────────────

class HelpClientScreen extends StatefulWidget {
  const HelpClientScreen({Key? key}) : super(key: key);

  @override
  State<HelpClientScreen> createState() => _HelpClientScreenState();
}

class _HelpClientScreenState extends State<HelpClientScreen> {

  // FAQ adaptée au côté CLIENT (pas fournisseur)
  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'Comment passer une commande d\'eau ?',
      'answer': 'Allez dans l\'onglet "Commandes", choisissez la quantité souhaitée et confirmez votre demande. Un fournisseur vous sera assigné automatiquement.',
      'isOpen': false,
    },
    {
      'question': 'Comment suivre ma livraison ?',
      'answer': 'Une fois votre commande acceptée, rendez-vous dans l\'onglet "Suivi" pour voir la position du camion en temps réel sur la carte.',
      'isOpen': false,
    },
    {
      'question': 'Comment annuler une commande ?',
      'answer': 'Vous pouvez annuler une commande depuis l\'écran de détail tant qu\'elle n\'est pas encore en cours de livraison.',
      'isOpen': false,
    },
    {
      'question': 'Comment payer ma livraison ?',
      'answer': 'Le paiement s\'effectue à la livraison en espèces ou via l\'application. Consultez la section "Paiements" pour plus d\'options.',
      'isOpen': false,
    },
    {
      'question': 'Comment évaluer un fournisseur ?',
      'answer': 'Après chaque livraison, une notification vous invite à laisser une évaluation. Votre avis aide à améliorer la qualité du service.',
      'isOpen': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: const Color(0xFF0B3C49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Contacts rapides ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B3C49), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Besoin d'aide ?",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Notre équipe est disponible 7j/7 de 8h à 20h',
                      style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _buildContactBtn(Icons.phone, 'Appeler', () {
                      // TODO: url_launcher → tel:+213...
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContactBtn(Icons.chat_bubble_outline, 'Chat', () {
                      // TODO: Ouvrir chat en direct
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContactBtn(Icons.email_outlined, 'Email', () {
                      // TODO: url_launcher → mailto:...
                    })),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Bouton urgence ───────────────────────────────
            GestureDetector(
              onTap: () {
                // TODO: Déclencher l'assistance d'urgence
              },
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.emergency, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assistance d'urgence",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                        Text('Problème avec votre livraison en cours',
                            style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    )),
                    const Icon(Icons.chevron_right, color: Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── FAQ accordéon ────────────────────────────────
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
                  Text('Questions fréquentes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  ...faqs.asMap().entries.map((entry) => _buildFaqItem(entry.key, entry.value)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Formulaire ticket ────────────────────────────
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
                  Text('Signaler un problème',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLines: 4,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre problème...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0B3C49), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: POST /api/support/tickets
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket envoyé !'), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3C49),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Envoyer le ticket',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // Bouton de contact (Appeler / Chat / Email)
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
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }

  // Élément FAQ accordéon (clic = ouvre/ferme la réponse)
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
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3C49).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.help_outline, color: Color(0xFF0B3C49), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(faq['question'],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    // Réponse visible uniquement si isOpen == true
                    if (faq['isOpen']) ...[
                      const SizedBox(height: 8),
                      Text(faq['answer'],
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5)),
                    ],
                  ]),
                ),
                Icon(
                  faq['isOpen'] ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (index < faqs.length - 1)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

// ── Confidentialité ──────────────────────────────────────────────
class PrivacyClientScreen extends StatelessWidget {
  const PrivacyClientScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Confidentialité'), backgroundColor: const Color(0xFF0B3C49), foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Politique de confidentialité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              Text(
                'Vos données personnelles sont collectées uniquement pour assurer le bon fonctionnement du service de livraison d\'eau. Elles ne sont jamais partagées avec des tiers sans votre consentement.\n\nVous pouvez demander la suppression de votre compte et de vos données à tout moment en contactant notre support.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}