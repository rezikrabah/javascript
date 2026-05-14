import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test2/pages/createaccpage.dart';
import '../client/suivi.dart';
import '../fournisseur/ChauffeurScreen.dart';
import '../fournisseur/provider_home_screen_FINAL.dart';
import 'forgotpassword.dart';
import 'RoleSelectionScreen.dart';
import '../services/api_service.dart';
import 'fournisseurinfos.dart';
import 'admin_dashboard.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  static const String _base = 'https://pfe-backend-nwmy.onrender.com';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    // ── STEP 1: try admin login on backend ──────────────────────
    // In Loginpage.dart _login() method
    try {
      final adminRes = await http.post(
        Uri.parse('$_base/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      print('[Admin] status: ${adminRes.statusCode}');
      print('[Admin] body: ${adminRes.body}');

      if (adminRes.statusCode == 200) {
        final data = jsonDecode(adminRes.body);
        AdminToken.set(data['token']);
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminApp()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenue Administrateur'), backgroundColor: Colors.purple),
        );
        return;
      } else if (adminRes.statusCode == 401) {
        // Wrong admin password — don't fall through, just show error
        // Remove this block if you want non-admins to still try normal login
      }
    } catch (e) {
      print('[Admin] exception: $e');
      // network error — fall through to normal login
    }

    // ── STEP 2: normal user login ────────────────────────────────
    final result = await ApiService.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
      return;
    }

    if (result['token'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      final String? role = result['user']?['role'];

      if (!mounted) return;

      if (role == 'client') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => suivi()));
      } else if (role == 'chauffeur') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ProviderHomeScreen()));
      } else if (role == 'gerant') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ChauffeurScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => RoleSelectionScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['msg'] ?? 'La connexion a échoué'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0C2A34),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'SE CONNECTER',
          style: TextStyle(
            color: const Color(0xFFEAFBFF),
            fontSize: screenWidth * 0.033,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF0B3C49),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: Icon(Icons.water_drop,
                size: screenWidth * 0.065, color: const Color(0xFF1E88E5)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0',
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget:  (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Color(0x880C2A34),
                      Color(0xDD0C2A34),
                      Color(0xFF0C2A34),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.04),
                    // Logo
                    Container(
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
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Content de vous revoir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Ajoutez vos coordonnées pour vous connecter',
                      style: TextStyle(
                        color: const Color(0xFFB8E3F0),
                        fontSize: screenWidth * 0.033,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.035),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                          color: Colors.white, fontSize: screenWidth * 0.035),
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint:  'john@example.com',
                        icon:  Icons.email_outlined,
                        screenWidth:  screenWidth,
                        screenHeight: screenHeight,
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Veuillez entrer votre email';
                        if (!v.contains('@')) return 'Entrez un email valide';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.018),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                          color: Colors.white, fontSize: screenWidth * 0.035),
                      decoration: _inputDecoration(
                        label: 'Mot de passe',
                        hint:  '••••••••',
                        icon:  Icons.lock_outline,
                        screenWidth:  screenWidth,
                        screenHeight: screenHeight,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9EC7CF),
                            size: screenWidth * 0.05,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Veuillez entrer votre mot de passe';
                        if (v.length < 6) return 'Au moins 6 caractères';
                        return null;
                      },
                    ),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => forgotpassword())),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 0, vertical: screenHeight * 0.01),
                        ),
                        child: Text(
                          'Mot de passe oublié?',
                          style: TextStyle(
                            color: const Color(0xFF00C8F0),
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // Login button
                    SizedBox(
                      width:  double.infinity,
                      height: screenHeight * 0.065,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0099CC),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF0099CC).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                          width:  screenWidth * 0.055,
                          height: screenWidth * 0.055,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "j'ai pas de compte? ",
                          style: TextStyle(
                            color: const Color(0xFF9EC7CF),
                            fontSize: screenWidth * 0.033,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => createaccpage())),
                          child: Text(
                            "S'inscrire",
                            style: TextStyle(
                              color: const Color(0xFF00C8F0),
                              fontSize: screenWidth * 0.033,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: const Color(0xFF9EC7CF),
        fontSize: screenWidth * 0.033,
        fontWeight: FontWeight.w500,
      ),
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: screenWidth * 0.03,
          color: Colors.white.withOpacity(0.25)),
      prefixIcon: Icon(icon,
          color: const Color(0xFF00C8F0), size: screenWidth * 0.05),
      suffixIcon: suffixIcon,
      filled:    true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0099CC), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00C8F0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical:   screenHeight * 0.018,
      ),
    );
  }
}