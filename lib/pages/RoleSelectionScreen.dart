import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:test2/client/suivi.dart';
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
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
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
      MaterialPageRoute(builder: (context) {
        if (role == 'client') return suivi();
        if (role == 'gerant') return const ChauffeurScreen();
        return const fournisseurinfos();
      }),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String role,
    required double screenWidth,
    required double screenHeight,
  }) {
    final cardWidth = (screenWidth - screenWidth * 0.14) / 2;

    return GestureDetector(
      onTap: _isLoading ? null : () => _selectRole(role),
      child: Container(
        width: cardWidth,
        height: screenHeight * 0.2,
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
            Icon(icon, size: screenWidth * 0.14, color: Colors.blue),
            SizedBox(height: screenHeight * 0.015),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF0B3C49),
                fontSize: screenWidth * 0.043,
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
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFEAFBFF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Choisissez votre rôle",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
        backgroundColor: const Color(0xFF0B3C49),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF0B3C49)),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            children: [

              SizedBox(height: screenHeight * 0.05),

              // ── Logo ──────────────────────────────
              CircleAvatar(
                radius: screenWidth * 0.1,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: const Image(
                    image: CachedNetworkImageProvider(
                      'https://img.freepik.com/premium-vector/water-vector-logo-design-white-background_1277164-15228.jpg',
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // ── Title ─────────────────────────────
              Text(
                "Vous êtes ?",
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B3C49),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // ── Role cards grid ───────────────────
              Wrap(
                spacing: screenWidth * 0.04,
                runSpacing: screenHeight * 0.025,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleCard(
                    icon: Icons.person,
                    title: "Client",
                    role: "client",
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  _buildRoleCard(
                    icon: Icons.local_shipping,
                    title: "Chauffeur",
                    role: "chauffeur",
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  _buildRoleCard(
                    icon: Icons.admin_panel_settings,
                    title: "Gérant",
                    role: "gerant",
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}