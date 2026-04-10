import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test2/client/client_tracking_page.dart';
import '../services/api_service.dart';

// --- (Garder le modèle _Fournisseur identique) ---
class _Fournisseur {
  final String id;
  final String nom;
  _Fournisseur({required this.id, required this.nom});
  factory _Fournisseur.fromJson(Map<String, dynamic> j) => _Fournisseur(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    nom: '${j['prenom'] ?? ''} ${j['nom'] ?? ''}'.trim().isNotEmpty
        ? '${j['prenom'] ?? ''} ${j['nom'] ?? ''}'.trim()
        : j['email'] ?? 'Fournisseur',
  );
}

class commandes extends StatefulWidget {
  final int clientId;
  const commandes({super.key, required this.clientId});
  @override
  State<commandes> createState() => _CommandesState();
}

class _CommandesState extends State<commandes> {
  // --- (Garder toutes les variables et fonctions logiques identiques) ---
  String? selectedPosition;
  String? selectedVolume;
  _Fournisseur? selectedFournisseur;
  bool _submitting = false;
  bool _gettingLocation = false;
  double? _selectedLat;
  double? _selectedLon;
  List<_Fournisseur> _fournisseurs = [];
  bool _loadingFourn = false;
  String? _fournError;
  final List<String> volumes = ['100L', '500L', '1000L', '2000L', '3000L', '5000L'];

  @override
  void initState() { super.initState(); _loadFournisseurs(); }

  // --- (Garder _useMyLocation, _loadFournisseurs, _confirmOrder, etc. identiques) ---
  Future<void> _useMyLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _showError('Permission refusée.'); return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLat = pos.latitude; _selectedLon = pos.longitude;
        selectedPosition = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (_) { _showError('Erreur GPS'); }
    finally { if (mounted) setState(() => _gettingLocation = false); }
  }

  Future<void> _loadFournisseurs() async {
    setState(() { _loadingFourn = true; });
    final list = await ApiService.getFournisseurs();
    setState(() {
      _loadingFourn = false;
      _fournisseurs = list.map((e) => _Fournisseur.fromJson(e)).toList();
    });
  }

  Future<void> _confirmOrder() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      final demand = int.tryParse(selectedVolume!.replaceAll('L', '')) ?? 0;
      final result = await ApiService.addCommande(
        capacite: demand.toDouble(),
        prix: demand.toDouble() * 2,
        lat: _selectedLat, lon: _selectedLon,
        fournisseurId: selectedFournisseur!.id,
      );
      if (mounted && result['error'] == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientTrackingPage(
          commandeId: (result['_id'] ?? result['id']).toString(),
          clientId: ApiService.userId ?? widget.clientId.toString(),
        )));
      }
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  void _showError(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red)); }

  bool get _canConfirm => selectedPosition != null && selectedVolume != null && selectedFournisseur != null;

  // ── DESIGN ORIGINAL ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Détection du mode sombre
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette de couleurs adaptative
    final primaryColor = isDark ? Colors.blueAccent : const Color(0xFF1A237E);
    final accentColor = const Color(0xFF2979FF);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 70,
            floating: false,
            pinned: true,
            elevation: 0,
            // Utilisation d'un dégradé qui respecte le mode sombre
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black, const Color(0xFF1A237E)]
                      : [const Color(0xFF1A237E), accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                    'Nouvelle Commande',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    )
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Configuration de livraison", isDark),
                  const SizedBox(height: 20),

                  _buildModernStepCard(
                    index: "1",
                    title: "Lieu de livraison",
                    subtitle: selectedPosition ?? "Où devons-nous livrer ?",
                    icon: Icons.my_location,
                    isActive: _selectedLat != null,
                    isLoading: _gettingLocation,
                    onTap: _useMyLocation,
                    color: Colors.orange,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  _buildModernStepCard(
                    index: "2",
                    title: "Volume souhaité",
                    subtitle: selectedVolume ?? "Choisir la quantité d'eau",
                    icon: Icons.opacity,
                    isActive: selectedVolume != null,
                    onTap: _showVolumePicker,
                    color: Colors.blue,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  _buildModernStepCard(
                    index: "3",
                    title: "Prestataire",
                    subtitle: selectedFournisseur?.nom ?? "Sélectionner un chauffeur",
                    icon: Icons.local_shipping,
                    isActive: selectedFournisseur != null,
                    onTap: _showFournisseurPicker,
                    color: Colors.teal,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 40),

                  if (_canConfirm) _buildSummary(accentColor, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(primaryColor, accentColor, isDark),
    );
  }

  Widget _sectionTitle(String title, bool isDark) => Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white54 : Colors.black38,
          letterSpacing: 1.2
      )
  );

  Widget _buildModernStepCard({
    required String index,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    bool isLoading = false,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isActive ? color.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(
              color: isActive ? color : (isDark ? Colors.white10 : Colors.transparent),
              width: 2
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isActive ? color : (isDark ? Colors.white12 : Colors.grey[100]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: isLoading
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[500], fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A237E))),
                ],
              ),
            ),
            if (isActive) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                "Votre commande sera traitée dès confirmation.",
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF1A237E), fontWeight: FontWeight.w500)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(Color primary, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: (_canConfirm && !_submitting) ? _confirmOrder : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: _submitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('CONFIRMER LA COMMANDE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ),
      ),
    );
  }

  // --- _showVolumePicker et _showFournisseurPicker
  void _showVolumePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Important pour le clavier
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          // On enlève le double container et on gère la couleur ici
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)
                  )
              ),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                      "Volume requis",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black // Texte adaptatif
                      )
                  )
              ),

              // Choix prédéfinis
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: volumes.map((v) => ChoiceChip(
                  label: Text(v),
                  selected: selectedVolume == v,
                  onSelected: (sel) {
                    setState(() => selectedVolume = v);
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF2979FF),
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                  labelStyle: TextStyle(
                      color: selectedVolume == v ? Colors.white : (isDark ? Colors.white70 : Colors.black),
                      fontWeight: FontWeight.w500
                  ),
                )).toList(),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider(indent: 20)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                          "OU",
                          style: TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                    ),
                    Expanded(child: Divider(endIndent: 20)),
                  ],
                ),
              ),

              // Saisie manuelle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: customController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Entrez un volume personnalisé (L)",
                    prefixIcon: const Icon(Icons.edit, color: Color(0xFF2979FF)),
                    suffixText: "L",
                    suffixStyle: const TextStyle(
                        color: Color(0xFF2979FF),
                        fontWeight: FontWeight.bold
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final volume = int.tryParse(value);
                      if (volume != null && volume > 0) {
                        setState(() => selectedVolume = '${volume}L');
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Bouton de confirmation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final value = customController.text;
                      if (value.isNotEmpty) {
                        final volume = int.tryParse(value);
                        if (volume != null && volume > 0) {
                          setState(() => selectedVolume = '${volume}L');
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Veuillez entrer un nombre valide"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Confirmer le volume"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showFournisseurPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white, // Couleur adaptative
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(padding: EdgeInsets.all(20), child: Text("Chauffeurs disponibles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(
              child: _loadingFourn
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _fournisseurs.length,
                itemBuilder: (_, i) {
                  final f = _fournisseurs[i];
                  bool isSel = selectedFournisseur?.id == f.id;
                  return ListTile(
                    onTap: () { setState(() => selectedFournisseur = f); Navigator.pop(context); },
                    contentPadding: const EdgeInsets.all(10),
                    leading: CircleAvatar(backgroundColor: isSel ? const Color(0xFF2979FF) : Colors.grey[100], child: Icon(Icons.person, color: isSel ? Colors.white : Colors.grey)),
                    title: Text(f.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF2979FF)) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    tileColor: isSel ? Colors.blue.withOpacity(0.05) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}