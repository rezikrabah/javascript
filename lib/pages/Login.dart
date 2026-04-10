import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/createaccpage.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Login(),
));

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0C2A34),
      body: Stack(
        children: [
          // ── Full screen background image ─────────────────
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl:
              'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0',
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ── Dark overlay ─────────────────────────────────
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

          // ── Content ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log in',
                        style: TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.water_drop,
                          color: Color(0xFF4ECDC4), size: 26),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Logo ─────────────────────────────────────
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
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/app.png'),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Welcome to the first\nwater delivery application',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB8E3F0),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // ── Buttons ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // Login button
                      _GlassButton(
                        label: 'Login',
                        icon: Icons.login_rounded,
                        filled: true,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Loginpage())),
                      ),
                      const SizedBox(height: 14),

                      // Create account button
                      _GlassButton(
                        label: 'Create an account',
                        icon: Icons.person_add_outlined,
                        filled: false,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => createaccpage())),
                      ),
                      const SizedBox(height: 40),
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

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
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
              size: 20,
              color: filled ? const Color(0xFF0C2A34) : const Color(0xFF4ECDC4),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled
                    ? const Color(0xFF0C2A34)
                    : const Color(0xFF4ECDC4),
                fontSize: 16,
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
