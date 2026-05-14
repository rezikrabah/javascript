import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'RoleSelectionScreen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String userId;
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'Entrez le code à 6 chiffres');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'code':   _code,
        }),
      );

      final data = jsonDecode(res.body);
      setState(() => _loading = false);

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email vérifié ✓'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSelectionScreen(userId: widget.userId),
            ),
          );
        }
      } else {
        setState(() => _error = data['msg'] ?? 'Code invalide');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = 'Erreur réseau. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF071628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF04111F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Vérification Email',
          style: TextStyle(
            color: const Color(0xFFB4DCE6),
            fontSize: screenWidth * 0.045,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            SizedBox(height: screenHeight * 0.04),

            // ── Icon ────────────────────────────────────
            Container(
              width:  screenWidth * 0.2,
              height: screenWidth * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                color: const Color(0xFF1E88E5),
                size: screenWidth * 0.1,
              ),
            ),

            SizedBox(height: screenHeight * 0.025),

            // ── Title ───────────────────────────────────
            Text(
              'Vérifiez votre email',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            // ── Subtitle ─────────────────────────────────
            Text(
              'Un code de vérification a été envoyé à\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF9EC7CF),
                fontSize: screenWidth * 0.035,
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            // ── 6-digit code boxes ────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => SizedBox(
                width:  screenWidth * 0.12,
                height: screenWidth * 0.14,
                child: TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E88E5), width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    }
                    if (val.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    if (_code.length == 6) _verify();
                  },
                ),
              )),
            ),

            SizedBox(height: screenHeight * 0.02),

            // ── Error message ────────────────────────────
            if (_error != null)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline,
                      color: Colors.redAccent, size: screenWidth * 0.045),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: screenWidth * 0.033,
                      ),
                    ),
                  ),
                ]),
              ),

            SizedBox(height: screenHeight * 0.035),

            // ── Verify button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.07,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                  width:  screenWidth * 0.055,
                  height: screenWidth * 0.055,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  'Vérifier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}