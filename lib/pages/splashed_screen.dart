import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:test2/pages/Login.dart';
import 'Homepage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// ================== APP ==================
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AnimatedSplashScreen(),
    );
  }
}

// ================== SPLASH SCREEN ==================
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _truckController;
  late Animation<Offset> _truckAnimation;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _truckController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // 🚛 Camion : droite → centre
    _truckAnimation = Tween<Offset>(
      begin: const Offset(2.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _truckController,
        curve: Curves.easeInOut,
      ),
    );

    // ✨ Texte fade
    _textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _truckController,
        curve: const Interval(0.6, 1.0),
      ),
    );

    _truckController.forward();

    // ⏭️ Transition après animation
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    });
  }

  @override
  void dispose() {
    _truckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ fond blanc
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // 🚛 CAMION
            SlideTransition(
              position: _truckAnimation,
              child: Image.asset(
                'assets/photo_2026-02-08_20-40-18.jpg',
                width: 240,
              ),
            ),

            const SizedBox(height: 40),

            // ✨ TEXTE waveau (inchangé)
            FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
              RichText(
              text: TextSpan(
              children: [
                  TextSpan(
                text: 'WAV',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                  letterSpacing: 2,
                ),
              ),

              const TextSpan(
                text: 'eau',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0EA5E9),
                  letterSpacing: 3,
                ),
              ),
              ],
            ),
      ),
      ],
    ),
            ),
          ],
        ),
      ),
    );
  }
}