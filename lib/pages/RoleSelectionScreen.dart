import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:test2/client/clientpage.dart';
import 'package:test2/pages/fournisseurinfos.dart';
import '../services/api_service.dart';
import 'package:test2/fournisseur/ChauffeurScreen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? userId;

  const RoleSelectionScreen({super.key, this.userId});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    if (widget.userId == null) {
      _navigate(role);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.chooseRole(
      userId: widget.userId!,
      role: role,
    );

    setState(() => _isLoading = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (result['msg'] == 'role already chosen') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role already set. Please login.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _navigate(role);
  }

  void _navigate(String role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (role == 'client') return clientpage();
          if (role == 'gerant') return const ChauffeurScreen();
          return const fournisseurinfos();
        },
      ),
    );
  }

  // --- Widget de la carte de rôle ---
  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String role,
    required double width,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _selectRole(role),
      child: Container(
        width: width,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 55, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0B3C49),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul pour avoir exactement 2 cartes par ligne avec espacement
    final double cardWidth = (MediaQuery.of(context).size.width - 56) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFEAFBFF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: const Text(
          "Choisissez votre rôle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B3C49),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B3C49)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    image: CachedNetworkImageProvider(
                      'https://img.freepik.com/premium-vector/water-vector-logo-design-white-background_1277164-15228.jpg',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Vous êtes ?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3C49),
                ),
              ),
              const SizedBox(height: 40),

              // --- Grille de sélection centrée ---
              Wrap(
                spacing: 16,     // Espace horizontal entre les cartes
                runSpacing: 20,  // Espace vertical entre les lignes
                alignment: WrapAlignment.center, // CENTRE LE BOUTON CHAUFFEUR
                children: [
                  _buildRoleCard(
                    icon: Icons.person,
                    title: "Client",
                    role: "client",
                    width: cardWidth,
                  ),
                  _buildRoleCard(
                    icon: Icons.local_shipping,
                    title: "chauffeur",
                    role: "chauffeur",
                    width: cardWidth,
                  ),
                  _buildRoleCard(
                    icon: Icons.admin_panel_settings,
                    title: "gerant",
                    role: "gerant",
                    width: cardWidth,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}