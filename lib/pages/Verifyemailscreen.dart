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

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

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
          // ✅ Go to role selection after verification
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
    return Scaffold(
      backgroundColor: const Color(0xFF071628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF04111F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Vérification Email',
            style: TextStyle(color: Color(0xFFB4DCE6))),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined,
                  color: Color(0xFF1E88E5), size: 40),
            ),
            const SizedBox(height: 24),

            const Text('Vérifiez votre email',
                style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Text(
              'Un code de vérification a été envoyé à\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9EC7CF), fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ✅ 6-digit code input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => SizedBox(
                width: 43, height: 55,
                child: TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E88E5), width: 2)),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    }
                    if (val.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    // Auto-submit when all 6 filled
                    if (_code.length == 6) _verify();
                  },
                ),
              )),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13))),
                ]),
              ),

            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Vérifier',
                    style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}