import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:test2/pages/Loginpage.dart';
import 'package:test2/pages/Verifyemailscreen.dart';
import '../services/api_service.dart';

class createaccpage extends StatefulWidget {
  const createaccpage({super.key});

  @override
  State<createaccpage> createState() => _createaccpageState();
}

class _createaccpageState extends State<createaccpage> {
  final _formKey                                          = GlobalKey<FormState>();
  final TextEditingController _nomController             = TextEditingController();
  final TextEditingController _prenomController          = TextEditingController();
  final TextEditingController _emailController           = TextEditingController();
  final TextEditingController _phoneController           = TextEditingController();
  final TextEditingController _passwordController        = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _adresseController         = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await ApiService.register(
      nom:       _nomController.text.trim(),
      prenom:    _prenomController.text.trim(),
      email:     _emailController.text.trim(),
      password:  _passwordController.text.trim(),
      telephone: _phoneController.text.trim(),
      adresse:   _adresseController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['erreur'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['erreur']), backgroundColor: Colors.red),
      );
      return;
    }

    if (result['userId'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code envoyé à votre email ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            userId: result['userId'].toString(),
            email:  _emailController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['msg'] ?? 'L\'inscription a échoué'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF9EC7CF),
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: screenWidth * 0.03,
          color: Colors.white.withOpacity(0.25),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00C8F0), size: screenWidth * 0.05),
        suffixIcon: suffix,
        filled: true,
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
          vertical: screenHeight * 0.018,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF071628),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'CRÉEZ VOTRE COMPTE',
          style: TextStyle(
            color: const Color(0xFFB4DCE6),
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF04111F),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: Icon(Icons.water_drop,
                size: screenWidth * 0.065,
                color: const Color(0xFF1E88E5)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // ── Logo ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C8F0).withOpacity(0.3),
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

              SizedBox(height: screenHeight * 0.015),

              Text(
                'S\'inscrire',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: screenHeight * 0.005),

              Text(
                'Ajoutez vos coordonnées pour commencer',
                style: TextStyle(
                  color: const Color(0xFF9EC7CF),
                  fontSize: screenWidth * 0.033,
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // ── Name row ──────────────────────────────
              Row(children: [
                Expanded(child: _buildField(
                  controller: _nomController,
                  label: 'Nom de famille', hint: 'Doe',
                  icon: Icons.badge_outlined,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                )),
                SizedBox(width: screenWidth * 0.03),
                Expanded(child: _buildField(
                  controller: _prenomController,
                  label: 'Prénom', hint: 'John',
                  icon: Icons.person_outline,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                )),
              ]),

              SizedBox(height: screenHeight * 0.015),

              // ── Email ────────────────────────────────
              _buildField(
                controller: _emailController,
                label: 'Email', hint: 'john@gmail.com',
                icon: Icons.email_outlined,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Veuillez entrer votre email';
                  if (!v.contains('@')) return 'Entrez un email valide';
                  return null;
                },
              ),

              SizedBox(height: screenHeight * 0.015),

              // ── Phone ────────────────────────────────
              _buildField(
                controller: _phoneController,
                label: 'Numéro de téléphone', hint: '0555 123 456',
                icon: Icons.phone_outlined,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),

              SizedBox(height: screenHeight * 0.015),

              // ── Password ─────────────────────────────
              _buildField(
                controller: _passwordController,
                label: 'Mot de passe', hint: '••••••••',
                icon: Icons.lock_outline,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9EC7CF),
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Veuillez entrer votre mot de passe';
                  if (v.length < 8) return 'Au moins 8 caractères';
                  return null;
                },
              ),

              SizedBox(height: screenHeight * 0.015),

              // ── Confirm password ──────────────────────
              _buildField(
                controller: _confirmPasswordController,
                label: 'Confirmez le mot de passe', hint: '••••••••',
                icon: Icons.lock_outline,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9EC7CF),
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Veuillez confirmer votre mot de passe';
                  if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),

              SizedBox(height: screenHeight * 0.015),

              // ── Address ───────────────────────────────
              _buildField(
                controller: _adresseController,
                label: 'Adresse', hint: 'Entrez votre adresse',
                icon: Icons.location_on_outlined,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),

              SizedBox(height: screenHeight * 0.03),

              // ── Sign Up button ────────────────────────
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0099CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: screenWidth * 0.055,
                    height: screenWidth * 0.055,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    'S\'inscrire',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // ── Login link ────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  'Vous avez déjà un compte? ',
                  style: TextStyle(
                    color: const Color(0xFF9EC7CF),
                    fontSize: screenWidth * 0.033,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => Loginpage())),
                  child: Text(
                    'Se connecter',
                    style: TextStyle(
                      color: const Color(0xFF00C8F0),
                      fontSize: screenWidth * 0.033,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}