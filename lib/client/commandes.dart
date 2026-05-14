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
  // --- Variables existantes ---
  String? selectedPosition;
  String? selectedVolume;
  _Fournisseur? selectedFournisseur;
  bool _submitting = false;
  bool _gettingLocation = false;
  double? _selectedLat;
  double? _selectedLon;
 String? driverPhone;
  List<_Fournisseur> _fournisseurs = [];
  bool _loadingFourn = false;
  String? _fournError;
  final List<String> volumes = ['100L', '500L', '1000L', '2000L', '3000L', '5000L'];
  String? selectedWilaya;
  final List<String> wilayas = [
    '01 - Adrar', '02 - Chlef', '03 - Laghouat', '04 - Oum El Bouaghi',
    '05 - Batna', '06 - Béjaïa', '07 - Biskra', '08 - Béchar',
    '09 - Blida', '10 - Bouira', '11 - Tamanrasset', '12 - Tébessa',
    '13 - Tlemcen', '14 - Tiaret', '15 - Tizi Ouzou', '16 - Alger',
    '17 - Djelfa', '18 - Jijel', '19 - Sétif', '20 - Saïda',
    '21 - Skikda', '22 - Sidi Bel Abbès', '23 - Annaba', '24 - Guelma',
    '25 - Constantine', '26 - Médéa', '27 - Mostaganem', '28 - M\'Sila',
    '29 - Mascara', '30 - Ouargla', '31 - Oran', '32 - El Bayadh',
    '33 - Illizi', '34 - Bordj Bou Arréridj', '35 - Boumerdès', '36 - El Tarf',
    '37 - Tindouf', '38 - Tissemsilt', '39 - El Oued', '40 - Khenchela',
    '41 - Souk Ahras', '42 - Tipaza', '43 - Mila', '44 - Aïn Defla',
    '45 - Naâma', '46 - Aïn Témouchent', '47 - Ghardaïa', '48 - Relizane',
    '49 - Timimoun', '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal',
    '52 - Béni Abbès', '53 - In Salah', '54 - In Guezzam', '55 - Touggourt',
    '56 - Djanet', '57 - El M\'Ghair', '58 - El Meniaa',
  ];

  String? selectedPriceRange;
  final List<String> priceRanges = ['1000-2000 DA', '2000-3000 DA', '3000-4000 DA', '4000-5000 DA', '5000+'];

  @override
  void initState() { super.initState(); _loadFournisseurs(); }

  // --- Fonction GPS existante ---
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

  // --- NOUVELLE FONCTION: Options de localisation ---
  void _showLocationOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                    "Choisir le mode de localisation",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black
                    )
                )
            ),

            // Option 1: GPS
            ListTile(
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.gps_fixed, color: Colors.orange, size: 24),
              ),
              title: const Text("Utiliser ma position GPS", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Localisation automatique", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
              onTap: () {
                Navigator.pop(context);
                _useMyLocation();
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OU", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // Option 2: Adresse manuelle
            ListTile(
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.edit_location, color: Colors.blue, size: 24),
              ),
              title: const Text("Saisir l'adresse manuellement", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Entrer une adresse personnalisée", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
              onTap: () {
                Navigator.pop(context);
                _showAddressInput();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- NOUVELLE FONCTION: Saisie manuelle d'adresse ---
  void _showAddressInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
                      "Adresse de livraison",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black
                      )
                  )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Entrez votre adresse complète...",
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2979FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (addressController.text.isNotEmpty) {
                        setState(() {
                          selectedPosition = addressController.text;
                          _selectedLat = null;
                          _selectedLon = null;
                        });
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Confirmer l'adresse"),
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

  //  Sélecteur de fourchette de prix ---
  void _showPriceRangePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                    "Fourchette de prix",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black
                    )
                )
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: priceRanges.map((range) => ChoiceChip(
                label: Text(range),
                selected: selectedPriceRange == range,
                onSelected: (sel) {
                  setState(() => selectedPriceRange = range);
                  Navigator.pop(context);
                },
                selectedColor: const Color(0xFF2979FF),
                backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                labelStyle: TextStyle(
                    color: selectedPriceRange == range ? Colors.white : (isDark ? Colors.white70 : Colors.black),
                    fontWeight: FontWeight.w500
                ),
              )).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
        lat: _selectedLat,
        lon: _selectedLon,
        wilaya: selectedWilaya!,        // ← pass wilaya, not fournisseurId
      );

      if (mounted && result['error'] == null) {
        final clientInfo = await ApiService.getClientInfo();
        final clientNom = '${clientInfo['prenom'] ?? ''} ${clientInfo['nom'] ?? ''}'.trim();
        final driverPhone = '${clientInfo['telephone'] ?? ''} '.trim();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientTrackingPage(
              commandeId:  (result['_id'] ?? result['id']).toString(),
              clientId:    ApiService.userId ?? widget.clientId.toString(),
              clientNom:   clientNom.isNotEmpty ? clientNom : 'Client',
              volumeLivre: double.tryParse(selectedVolume!.replaceAll('L', '')) ?? 0.0,
              adresse:     selectedPosition!,
              driverPhone:   driverPhone.isNotEmpty ? driverPhone : 'telephone',

            ),
          ),
        );
      } else if (mounted && result['error'] != null) {
        _showError(result['error']);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  void _showError(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red)); }

  bool get _canConfirm =>  selectedPosition != null && selectedVolume != null && selectedWilaya != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black, const Color(0xFF0B3C49)]
                      : [const Color(0xFF0B3C49), accentColor],
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

                  // --- LIEU DE LIVRAISON AVEC OPTIONS ---
                  _buildModernStepCard(
                    index: "1",
                    title: "Lieu de livraison",
                    subtitle: selectedPosition ?? "Où devons-nous livrer ?",
                    icon: Icons.my_location,
                    isActive: selectedPosition != null,
                    isLoading: _gettingLocation,
                    onTap: _showLocationOptions,
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
                    title: "Wilaya de livraison",
                    subtitle: selectedWilaya ?? "Sélectionner votre wilaya",
                    icon: Icons.map_outlined,
                    isActive: selectedWilaya != null,
                    onTap: _showWilayaPicker,
                    color: Colors.teal,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // --- NOUVEAU: FOURCHETTE DE PRIX ---
                  _buildModernStepCard(
                    index: "4",
                    title: "Fourchette de prix",
                    subtitle: selectedPriceRange ?? "Définir votre budget",
                    icon: Icons.attach_money,
                    isActive: selectedPriceRange != null,
                    onTap: _showPriceRangePicker,
                    color: Colors.purple,
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

  void _showVolumePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
                          color: isDark ? Colors.white : Colors.black
                      )
                  )
              ),

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
                    fillColor: isDark ? Colors.white10 : Colors.grey[50],
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

  void _showWilayaPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Wilaya de livraison",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: wilayas.length,
              itemBuilder: (_, i) {
                final w = wilayas[i];
                final isSel = selectedWilaya == w;
                return ListTile(
                  onTap: () { setState(() => selectedWilaya = w); Navigator.pop(context); },
                  title: Text(w, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  )),
                  leading: Icon(Icons.map_outlined,
                      color: isSel ? const Color(0xFF2979FF) : Colors.grey),
                  trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF2979FF)) : null,
                  tileColor: isSel ? Colors.blue.withOpacity(isDark ? 0.15 : 0.05) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}