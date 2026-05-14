import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[

            // ── Background image ──────────────────────────
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0',
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

            // ── Logo ──────────────────────────────────────
            Positioned(
              top: screenHeight * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: screenWidth * 0.1,
                    backgroundImage: const AssetImage('assets/app.png'),
                  ),
                ),
              ),
            ),

            // ── Title + Subtitle ──────────────────────────
            Positioned(
              top: screenHeight * 0.28,
              left: screenWidth * 0.1,
              right: screenWidth * 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'WAV',
                          style: TextStyle(
                            fontSize: screenWidth * 0.09,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'eau',
                          style: TextStyle(
                            fontSize: screenWidth * 0.090,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0EA5E9),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.09),
                  Text(
                    'Eau pure, livrée.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.009),
                  Text(
                    'La première application de livraison d\'eau en Algérie.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.033,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.60),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Button ─────────────────────────────
            Positioned(
              bottom: screenHeight * 0.1,
              left: screenWidth * 0.05,
              right: screenWidth * 0.04,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // Get started text
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => Login())),
                      child: Text(
                        'commencer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    // Arrow button
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => Login())),
                      child: Container(
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.blue,
                              blurRadius: 50,
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),

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