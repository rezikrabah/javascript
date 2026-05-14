import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/createaccpage.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0C2A34),
      body: Stack(
        children: [

          // ── Background image ──────────────────────────────
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl:
              'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0',
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ── Dark overlay ──────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x660C2A34),
                    Color(0xCC0C2A34),
                    Color(0xFF0C2A34),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [

                // ── Top bar ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.015,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Se connecter',
                        style: TextStyle(
                          color: const Color(0xFF4ECDC4),
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.water_drop,
                          color: const Color(0xFF4ECDC4),
                          size: screenWidth * 0.065),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Logo ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: screenWidth * 0.1,
                    backgroundImage: const AssetImage('assets/app.png'),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // ── Subtitle ──────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Text(
                    'Bienvenue dans la première application de livraison d\'eau',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFB8E3F0),
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                // ── Buttons ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                  child: Column(
                    children: [
                      _GlassButton(
                        label: 'Se connecter',
                        icon: Icons.login_rounded,
                        filled: true,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Loginpage())),
                      ),
                      SizedBox(height: screenHeight * 0.018),
                      _GlassButton(
                        label: 'Créer un compte',
                        icon: Icons.person_add_outlined,
                        filled: false,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => createaccpage())),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final double screenWidth;
  final double screenHeight;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.07,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF4ECDC4)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled
                ? Colors.transparent
                : const Color(0xFF4ECDC4).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenWidth * 0.05,
              color: filled
                  ? const Color(0xFF0C2A34)
                  : const Color(0xFF4ECDC4),
            ),
            SizedBox(width: screenWidth * 0.025),
            Text(
              label,
              style: TextStyle(
                color: filled
                    ? const Color(0xFF0C2A34)
                    : const Color(0xFF4ECDC4),
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}