import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test2/pages/Homepage.dart';
import 'package:test2/pages/Login.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/createaccpage.dart';
import 'package:test2/pages/forgotpassword.dart';
import 'package:test2/pages/RoleSelectionScreen.dart';
import 'package:test2/pages/fournisseurinfos.dart';
import 'package:test2/pages/splashed_screen.dart';

const String _backendUrl = 'http://10.0.2.2:8000';
 const String baseUrl = 'https://pfe-backend-nwmy.onrender.com';
// ================================================================
// MODE SOMBRE : ValueNotifier
// ================================================================
// ValueNotifier = une variable "observable" :
//   → quand sa valeur change, tous les widgets qui l'écoutent
//     se reconstruisent automatiquement.
//
// On le déclare ici (global) pour y accéder depuis N'IMPORTE
// quel écran de l'application avec : themeNotifier.value
//
// Utilisation :
//   Lire  : themeNotifier.value  (true = sombre, false = clair)
//   Changer : themeNotifier.value = !themeNotifier.value
// ================================================================
final ValueNotifier<bool> themeNotifier = ValueNotifier(false);
// false = Mode clair par défaut
// TODO: Sauvegarder la préférence avec SharedPreferences :
//   final prefs = await SharedPreferences.getInstance();
//   themeNotifier = ValueNotifier(prefs.getBool('darkMode') ?? false);


Future<void> initBackend() async {
  try {
    // 1. Vérifier si déjà initialisé
    final health = await http
        .get(Uri.parse('$_backendUrl/health'))
        .timeout(const Duration(seconds: 5));

    if (health.statusCode == 200) {
      final data = jsonDecode(health.body);

      // Si solution déjà disponible → rien à faire
      if (data['solution_available'] == true && data['commandes_acceptees'] == 5) {
        debugPrint('[Backend] Solution déjà disponible ✓');
        return;
      }

      // Si conducteurs déjà enregistrés mais pas de solution → juste optimiser
      if (data['conducteurs'] > 0 && data['commandes_acceptees'] > 0) {
        debugPrint('[Backend] Lancement optimisation...');
        await http.post(Uri.parse('$_backendUrl/optimize'))
            .timeout(const Duration(seconds: 60));
        return;
      }
    }

    // 2. Enregistrer les conducteurs
    debugPrint('[Backend] Initialisation conducteurs...');
    await http.post(
      Uri.parse('$_backendUrl/setup/conducteurs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode([
        {"id": 1, "capacity": 5000, "lat": 36.7600, "lon": 3.0500, "nom": "Conducteur A"},
        {"id": 2, "capacity": 5000, "lat": 36.7450, "lon": 3.0700, "nom": "Conducteur B"},
        {"id": 3, "capacity": 5000, "lat": 36.7580, "lon": 3.0800, "nom": "Conducteur C"},
      ]),
    ).timeout(const Duration(seconds: 10));

    // 3. Ajouter et accepter les commandes
    debugPrint('[Backend] Ajout des commandes...');
    final commandes = [
      {"id": 1, "lat": 36.7620, "lon": 3.0450, "demand": 80,  "description": "Client Bab El Oued"},
      {"id": 2, "lat": 36.7480, "lon": 3.0600, "demand": 120, "description": "Client Hussein Dey"},
      {"id": 3, "lat": 36.7550, "lon": 3.0750, "demand": 90,  "description": "Client El Harrach"},
      {"id": 4, "lat": 36.7700, "lon": 3.0650, "demand": 60,  "description": "Client Rouiba"},
      {"id": 5, "lat": 36.7400, "lon": 3.0850, "demand": 110, "description": "Client Baraki"},
    ];

    for (final cmd in commandes) {
      await http.post(
        Uri.parse('$_backendUrl/commandes/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cmd),
      ).timeout(const Duration(seconds: 5));

      await http.post(
        Uri.parse('$_backendUrl/commandes/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"commande_id": cmd['id']}),
      ).timeout(const Duration(seconds: 5));
    }

    // 4. Lancer l'optimisation NSGA-II
    debugPrint('[Backend] Lancement NSGA-II...');
    await http.post(Uri.parse('$_backendUrl/optimize'))
        .timeout(const Duration(seconds: 60));

    debugPrint('[Backend] Initialisation terminée ✓');

  } catch (e) {
    debugPrint('[Backend] Erreur init: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initBackend();

  runApp(const MyApp());
}

// ================================================================
// MyApp : Racine de l'application
// ================================================================
// On sépare MyApp dans sa propre classe pour pouvoir utiliser
// ValueListenableBuilder qui écoute themeNotifier.
//
// ValueListenableBuilder se reconstruit automatiquement
// chaque fois que themeNotifier.value change.
// ================================================================
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder écoute themeNotifier
    // Quand themeNotifier.value change → rebuild automatique
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier, // Ce qu'on écoute
      builder: (context, isDark, child) {
        // isDark = valeur actuelle de themeNotifier (true ou false)
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // ── Thème clair ──────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1E3A8A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: Colors.white,
            useMaterial3: true,
          ),

          // ── Thème sombre ─────────────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1E3A8A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
            canvasColor: const Color(0xFF1E1E1E),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: const Color(0xFF2A2A2A),
              labelStyle: const TextStyle(color: Colors.white70),
            ),
            dividerColor: Colors.white12,
            useMaterial3: true,
          ),

          // ── Mode actif ───────────────────────────────────
          // isDark = true  → themeMode: ThemeMode.dark  (mode sombre)
          // isDark = false → themeMode: ThemeMode.light (mode clair)
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          home: const AnimatedSplashScreen(),
          routes: {
            '/Homepage': (context) => Homepage(),
            '/Login': (context) => Login(),
            '/Loginpage': (context) => Loginpage(),
            '/createaccpage': (context) => createaccpage(),
            '/forgotpassword': (context) => forgotpassword(),
            '/RoleSelectionScreen': (context) => RoleSelectionScreen(),
            '/fournisseurinfos': (context) => fournisseurinfos(),
          },
        );
      },
    );
  }
}