import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ─────────────────────────────────────────
  // BASE URLS
  // ─────────────────────────────────────────

  /// Node.js backend — auth, users, commandes, chauffeurs
  static const String baseUrl = 'https://pfe-backend-nwmy.onrender.com';

  /// Python FastAPI — VRP NSGA-II optimization (local PC)
  static const String pythonUrl = 'https://pfebackendpython.onrender.com';

  // Stored after login
  static String? token;
  static String? userId;
  static String? userRole;
  static String? clientId;

  // ─────────────────────────────────────────
  // HEADERS
  // ─────────────────────────────────────────

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static const Map<String, String> _pythonHeaders = {
    'Content-Type': 'application/json',
  };

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {
        'error':
        'Server returned unexpected response (status ${response.statusCode})',
      };
    }
  }

  static List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode == 429) return [];
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }



// ─────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getVrpSolutionWithRealOrders({
    required List<Map<String, dynamic>> commandes, // ← pass real API commandes here
    required double depotLat,
    required double depotLon,
    double capaciteVehicule = 5000,
  }) async {
    // Re-map real commande fields to the flat format lancer-direct expects
    final normalizedCommandes = commandes.map((c) => {
      'id'      : (c['_id'] ?? c['id'] ?? '').toString(),
      'lat'     : (c['position']?['lat'] as num?)?.toDouble() ?? 0.0,
      'lon'     : (c['position']?['lon'] as num?)?.toDouble() ?? 0.0,
      'quantity': (c['capacite'] as num?)?.toInt() ?? 0,
      'price'   : (c['prix'] as num?)?.toDouble() ?? 0.0,
      'demand'  : (c['capacite'] as num?)?.toInt() ?? 1,
      'gain'    : (c['prix'] as num?)?.toDouble() ?? 0.0,
      'address' : c['adresse']?.toString() ?? '',
    }).toList();

    return getVrpSolutionWithOrders(
      commandes        : normalizedCommandes,
      depotLat         : depotLat,
      depotLon         : depotLon,
      capaciteVehicule : capaciteVehicule,
    );
  }
  static Future<Map<String, dynamic>> getVrpSolutionWithOrders({
    required List<Map<String, dynamic>> commandes,
    required double depotLat,
    required double depotLon,
    double capaciteVehicule = 5000,
    int nbVehicules = 1,
    List<Map<String, dynamic>> chauffeurs = const [],
  }) async {

    try {
      // ── Build index→originalId map BEFORE sending ──
      final Map<int, String> vrpIdToOriginalId = {};
      final nChauffeurs = chauffeurs.length;

      final vrpCommandes = commandes.asMap().entries.map((e) {
        final i   = e.key;
        final c   = e.value;
        final vid = i + 1 + nChauffeurs;   // ← offset to avoid collision
        vrpIdToOriginalId[vid] = (c['id'] ?? c['_id'] ?? '').toString();
        return {
          'id'         : vid,
          'lat'        : (c['lat'] as num?)?.toDouble()   ?? 0.0,
          'lon'        : (c['lon'] as num?)?.toDouble()   ?? 0.0,
          'demand'     : (c['demand'] as num?)?.toInt()
              ?? (c['quantity'] as num?)?.toInt()
              ?? 1,
          'gain'       : (c['gain'] as num?)?.toDouble()
              ?? (c['price'] as num?)?.toDouble()
              ?? 0.0,
          'description': c['address']?.toString()         ?? 'Client ${i + 1}',
        };
      }).toList();



      // Build ordered point list: depot first, then orders
      final allPoints = <Map<String, dynamic>>[
        {'id': 'depot', 'lat': depotLat, 'lon': depotLon},
        // ← add chauffeur positions
        ...chauffeurs.asMap().entries.map((e) => {
          'id'  : '${e.key + 1}',
          'lat' : (e.value['lat'] as num).toDouble(),
          'lon' : (e.value['lon'] as num).toDouble(),
        }),
        ...commandes.asMap().entries.map((e) => {
          'id'  : '${e.key + 1 + nChauffeurs}',
          'lat' : (e.value['lat'] as num?)?.toDouble() ?? 0.0,
          'lon' : (e.value['lon'] as num?)?.toDouble() ?? 0.0,
        }),
      ];

      Map<String, dynamic>? distanceMatrix;
      try {
        final coordsStr = allPoints
            .map((p) => '${p['lon']},${p['lat']}')
            .join(';');

        final osrmRes = await http
            .get(Uri.parse(
          'http://router.project-osrm.org/table/v1/driving/$coordsStr'
              '?annotations=distance,duration',
        ))
            .timeout(const Duration(seconds: 40));

        if (osrmRes.statusCode == 200) {
          final osrmData = jsonDecode(osrmRes.body) as Map<String, dynamic>;
          if (osrmData['code'] == 'Ok') {
            // Convert distances from meters → km
            final rawDist = osrmData['distances'] as List;
            final kmDist  = rawDist.map((row) =>
                (row as List).map((v) =>
                v != null ? (v as num).toDouble() / 1000.0 : null
                ).toList()
            ).toList();

            distanceMatrix = {
              'ids'      : allPoints.map((p) => p['id']).toList(),
              'distances': kmDist,
              'durations': osrmData['durations'],  // already in seconds
            };
            print('[OSRM table] ✅ matrix built — ${allPoints.length} points');
          }
        }
      } catch (e) {
        print('[OSRM table] ❌ failed: $e — Python will use Haversine');
      }

      final conducteurs = chauffeurs.isNotEmpty
          ? chauffeurs.asMap().entries.map((e) => {
        'id'      : e.key + 1,
        'lat'     : (e.value['lat'] as num).toDouble(),
        'lon'     : (e.value['lon'] as num).toDouble(),
        'capacity': (e.value['capacity'] as num?)?.toInt()
            ?? capaciteVehicule.toInt(),  // ← use chauffeur's own capacity
        'nom'     : e.value['nom'],
      }).toList()
          : List.generate(nbVehicules, (i) => {
        'id'      : i + 1,
        'lat'     : depotLat,
        'lon'     : depotLon,
        'capacity': capaciteVehicule.toInt(),
        'nom'     : 'Conducteur ${i + 1}',
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[VRP] ${conducteurs.length} conducteurs:');
      for (final c in conducteurs) {
        print('  → ${c['nom']}  id=${c['id']}  capacity=${c['capacity']}');
      }
      print('[VRP] ${vrpCommandes.length} commandes:');
      int totalDemand = 0;
      for (final c in vrpCommandes) {
        totalDemand += (c['demand'] as num).toInt();
        print('  → id=${c['id']}  demand=${c['demand']}  gain=${c['gain']}');
      }
      final totalCapacity = conducteurs.fold<int>(
          0, (sum, c) => sum + (c['capacity'] as int));
      print('[VRP] total demand=$totalDemand  total capacity=$totalCapacity  '
          '${totalCapacity >= totalDemand ? "✅ OK" : "⚠️ UNDER-CAPACITY"}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      final body = jsonEncode({
        'conducteurs'    : conducteurs, // ← single entry, no duplicate
        'pop_size'       : 30,
        'generations'    : 80,
        'distance_matrix': distanceMatrix,
        'commandes'      : vrpCommandes,
        'priorite'       : 'balance',
      });

      final res = await http.post(
        Uri.parse('$pythonUrl/optimisation/lancer-direct'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 180));

      if (res.statusCode != 200) {
        return {'error': 'VRP not ready (${res.statusCode})'};
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

// ADD THESE 4 LINES:
      print('[VRP RAW] keys: ${decoded.keys.toList()}');
      print('[VRP RAW] unserved: ${decoded['unserved']}');
      print('[VRP RAW] vrpIdToOriginalId sample: ${Map.fromEntries(vrpIdToOriginalId.entries.take(5))}');
      final firstRoute = (decoded['routes'] as List?)?.first;
      print('[VRP RAW] first route ids: ${(firstRoute?['route'] as List?)?.take(3).toList()}');
      // ── Remap VRP integer IDs → original string IDs ──
      // ── Remap VRP integer IDs → original string IDs (routes) ──
      final routes = decoded['routes'] as List<dynamic>? ?? [];
      for (final route in routes) {
        final rawRoute = route['route'] as List<dynamic>? ?? [];
        route['route'] = rawRoute.map((id) {
          final vid = int.tryParse(id.toString());
          return vid != null ? (vrpIdToOriginalId[vid] ?? id.toString()) : id.toString();
        }).toList();
      }

      // ── Remap unserved integer IDs → original string IDs ──
      final unservedRaw = decoded['unserved'] as List<dynamic>? ?? [];
      decoded['unserved_original_ids'] = unservedRaw.map((id) {
        print('[REMAP] unserved_original_ids: ${decoded['unserved_original_ids']}');
        final vid = int.tryParse(id.toString());
        return vid != null ? (vrpIdToOriginalId[vid] ?? id.toString()) : id.toString();
      }).toList();

      print('[REMAP] unserved count: ${unservedRaw.length}');
      print('[REMAP] unserved_original_ids: ${decoded['unserved_original_ids']}');

      return decoded;


    } on SocketException  { return {'error': 'Python API unreachable.'}; }
    on TimeoutException   { return {'error': 'VRP timeout.'}; }
    catch (e)             { return {'error': e.toString()}; }
  }


// ─────────────────────────────────────────
// CAMIONS  →  /api/camions
// ─────────────────────────────────────────

  static Future<List<dynamic>> getMyCamions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/camions/my'),
        headers: _authHeaders,
      );
      return _decodeList(response);
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addCamion({
    required String name,
    required String plate,
    required int capacity,
    String? model,
    String? year,
    String? lastService,
    String? nextService,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/camions/add'),
        headers: _authHeaders,
        body: jsonEncode({
          'name': name,
          'plate': plate,
          'capacity': capacity,
          if (model != null) 'model': model,
          if (year != null) 'year': year,
          if (lastService != null) 'lastService': lastService,
          if (nextService != null) 'nextService': nextService,
        }),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCamion(
      String id, {
        String? name,
        String? plate,
        int? capacity,
        String? status,
        String? model,
        String? year,
        String? lastService,
        String? nextService,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/camions/$id'),
        headers: _authHeaders,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (plate != null) 'plate': plate,
          if (capacity != null) 'capacity': capacity,
          if (status != null) 'status': status,
          if (model != null) 'model': model,
          if (year != null) 'year': year,
          if (lastService != null) 'lastService': lastService,
          if (nextService != null) 'nextService': nextService,
        }),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> getCommandesByStatus(
      String status, {
        String? chauffeurId, // ← optional filter
      }) async {
    try {
      // Build URL with optional chauffeurId param
      String url = '$baseUrl/api/commandes?status=${Uri.encodeComponent(status)}';
      if (chauffeurId != null) {
        url += '&chauffeurId=${Uri.encodeComponent(chauffeurId)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders,
      );

      print('[API] getCommandesByStatus($status, chauffeurId: $chauffeurId) → ${response.statusCode}');
      print('[API] body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return {'data': data};
        if (data is Map && data['commandes'] != null) return {'data': data['commandes']};
        return data as Map<String, dynamic>;
      }

      return {'error': 'Erreur serveur ${response.statusCode}'};
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }



  static Future<Map<String, dynamic>> deleteCamion(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/camions/$id'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // AUTH  →  /api/auth
  // ─────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
    required String adresse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'email': email,
          'password': password,
          'adresse': adresse,
        }),
      );
      final data = _decode(response);
      if (data['userId'] != null) userId = data['userId'];
      return data;
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = _decode(response);
      if (data['token'] != null) token = data['token'];
      if (data['user']?['id'] != null) userId = data['user']['id'];
      if (data['user']?['role'] != null) userRole = data['user']['role'];
      return data;
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// ✅ Saves new token with role after choosing role
  static Future<Map<String, dynamic>> chooseRole({
    required String userId,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/choose-role'),
        headers: _headers,
        body: jsonEncode({'userId': userId, 'role': role}),
      );
      final data = _decode(response);
      if (data['role'] != null) userRole = data['role'];
      if (data['token'] != null) token = data['token'];
      return data;
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  // In api_service.dart

// Client reviews chauffeur
  static Future<Map<String, dynamic>> submitClientReview({
    required String commandeId,
    required int note,
    required List<String> tags,
    String? commentaire,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/avis/client'),
        headers: _authHeaders,
        body: jsonEncode({
          'commande':    commandeId,
          'note':        note,
          'tags':        tags,
          if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
        }),
      );
      return _decode(res);
    } on SocketException  { return {'error': 'Connection error.'}; }
    on TimeoutException   { return {'error': 'Request timed out.'}; }
    catch (e)             { return {'error': e.toString()}; }
  }
  static Future<Map<String, dynamic>> submitTicket({
    required String sujet,
    required String message,
    String priorite = 'normale',
  }) async {
    try {
      debugPrint('[TICKET] token: $token');
      debugPrint('[TICKET] url: $baseUrl/api/reclamations/add');
      debugPrint('[TICKET] headers: $_authHeaders');

      final res = await http.post(
        Uri.parse('$baseUrl/api/reclamations/add'),
        headers: _authHeaders,
        body: jsonEncode({
          'sujet':    sujet,
          'message':  message,
          'priorite': priorite,
        }),
      );

      debugPrint('[TICKET] statusCode: ${res.statusCode}');
      debugPrint('[TICKET] body: ${res.body}');

      return _decode(res);
    } on SocketException  {
      debugPrint('[TICKET] SocketException');
      return {'error': 'Connection error.'};
    }
    on TimeoutException   {
      debugPrint('[TICKET] TimeoutException');
      return {'error': 'Request timed out.'};
    }
    catch (e) {
      debugPrint('[TICKET] error: $e');
      return {'error': e.toString()};
    }
  }
// Chauffeur reviews client
  static Future<Map<String, dynamic>> submitChauffeurReview({
    required String commandeId,
    required int note,
    required List<String> issues,
    required List<String> positives,
    required bool accessFacile,
    required bool clientPresent,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/avis/chauffeur'),
        headers: _authHeaders,
        body: jsonEncode({
          'commande':      commandeId,
          'note':          note,
          'issues':        issues,
          'positives':     positives,
          'accessFacile':  accessFacile,
          'clientPresent': clientPresent,
        }),
      );
      return _decode(res);
    } on SocketException  { return {'error': 'Connection error.'}; }
    on TimeoutException   { return {'error': 'Request timed out.'}; }
    catch (e)             { return {'error': e.toString()}; }
  }
  // ─────────────────────────────────────────
  // CLIENT  →  /api/clients
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getFournisseurs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clients/fournisseurs'),
        headers: _authHeaders,
      );
      return _decodeList(response);
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getClientInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clients/me'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // FOURNISSEUR  →  /api/fournisseurs
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getMyInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/fournisseurs/me'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateWilayas(List<String> wilayas) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/fournisseurs/wilayas'),
        headers: _authHeaders,
        body: jsonEncode({'wilayas': wilayas}),
      );
      return _decode(res);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFournisseurInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: _authHeaders,
      );
      return _decode(res);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Client submits a water shortage report
  static Future<Map<String, dynamic>> addSignalement({
    required String quartier,
    required String commune,
    required String niveau,       // 'legere' | 'moderee' | 'grave'
    required int dureeNombre,
    required String dureeUnite,
    String commentaire = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/signalements/add'),
        headers: _authHeaders,
        body: jsonEncode({
          'quartier':    quartier,
          'commune':     commune,
          'niveau':      niveau,
          'dureeNombre': dureeNombre,
          'dureeUnite':  dureeUnite,
          'commentaire': commentaire,
        }),
      );
      return _decode(res);
    } on SocketException  { return {'error': 'Connection error.'}; }
    on TimeoutException   { return {'error': 'Request timed out.'}; }
    catch (e)             { return {'error': e.toString()}; }
  }

  /// Driver fetches all reports (with optional filters)
  static Future<List<dynamic>> getSignalements({
    String commune = 'Toutes',
    String? niveau,
    Duration? depuis,
  }) async {
    try {
      final params = <String, String>{};
      if (commune != 'Toutes') params['commune'] = commune;
      if (niveau != null)      params['niveau']  = niveau;
      if (depuis != null)      params['depuis']  = depuis.inMilliseconds.toString();

      final uri = Uri.parse('$baseUrl/api/signalements')
          .replace(queryParameters: params.isEmpty ? null : params);

      final res = await http.get(uri, headers: _authHeaders);
      return _decodeList(res);
    } on SocketException { return []; }
    on TimeoutException  { return []; }
    catch (e)            { return []; }
  }
  static Future<Map<String, dynamic>> addFournisseurInfo({
    required double quantiteEau,
    required List<String> wilayas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/fournisseurs/add-info'),
        headers: _authHeaders,
        body: jsonEncode({
          'quantiteEau': quantiteEau,
          'wilayas': wilayas,
        }),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// ✅ Nouvelle méthode : modifier la quantité d’eau
  static Future<Map<String, dynamic>> updateWaterQuantity({
    required double quantiteEau,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/fournisseurs/quantite-eau'),
        headers: _authHeaders,
        body: jsonEncode({
          'quantiteEau': quantiteEau,
        }),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updatePosition({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/fournisseurs/position'),
        headers: _authHeaders,
        body: jsonEncode({'lat': lat, 'lon': lon}),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> setOffline() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/fournisseurs/offline'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // CHAUFFEUR  →  /api/chauffeurs
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> joinGerant({
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/fournisseurs/join'),
        headers: _authHeaders,
        body: jsonEncode({'code': code}),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getGerantInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getMyChauffeurs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/fournisseurs/my'),
        headers: _authHeaders,
      );
      return _decodeList(response);
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }
  static Future<Map<String, dynamic>> acceptCommande(String commandeId) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/commandes/accept/$commandeId'),
        headers: _authHeaders,
      );
      return _decode(res);
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  // ─────────────────────────────────────────
  // COMMANDE  →  /api/commandes
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> addCommande({
    required double capacite,
    required double prix,
    double? lat,
    double? lon,
    required String wilaya,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/commandes/add'),
        headers: _authHeaders,
        body: jsonEncode({
          'capacite': capacite,
          'prix': prix,
          'wilaya': wilaya,          // ← add this
          if (lat != null) 'lat': lat,
          if (lon != null) 'lon': lon,
          // ← remove the fournisseurId line entirely
        }),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getMyCommandes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commandes/my'),
        headers: _authHeaders,
      );
      return _decodeList(response);
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }
  /// Registers a single commande with the Python solver.
  /// Mirrors [sendCommandeToPython] but uses the field names
  /// the solver expects: id / lat / lon / demand.
  static Future<Map<String, dynamic>> addCommandeToSolver({
    required String commandeId,
    required double lat,
    required double lon,
    required double capacite,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/commandes/add'),
        headers: _pythonHeaders,
        body: jsonEncode({
          'id':     commandeId,
          'lat':    lat,
          'lon':    lon,
          'demand': capacite,   // Python solver uses "demand"
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } on TimeoutException {
      return {'error': 'addCommandeToSolver timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Triggers cheapest-insert on the Python solver so every
  /// registered commande is woven into an initial feasible route
  /// before NSGA-II runs.
  static Future<Map<String, dynamic>> ajouterDynamique() async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/commandes/ajouter-dynamique'),
        headers: _pythonHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } on TimeoutException {
      return {'error': 'ajouterDynamique timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> resetSolver() async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/reset'),
        headers: _pythonHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } on TimeoutException {
      return {'error': 'reset timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }




  static Future<void> seedTestOrders(List<Map<String, dynamic>> testOrders) async {
    // POST each test order to your backend as a real commande
    for (final order in testOrders) {
      await http.post(
        Uri.parse('$baseUrl/commandes'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'position': {'lat': order['lat'], 'lon': order['lon']},
          'adresse':  order['address']  ?? '',
          'capacite': order['quantity'] ?? 0,
          'client':   order['clientName'] ?? 'Test Client',
          'status':   'en livraison',
        }),
      );
    }
  }
  // method to delete test orders after use
  static Future<void> deleteTestOrders(List<String> ids) async {
    for (final id in ids) {
      await http.delete(
        Uri.parse('$baseUrl/commandes/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
  }

  static Future<List<dynamic>> getPendingCommandes() async {
    try {
      final uri = Uri.parse('$baseUrl/api/commandes/pending');
      print('[API] GET $uri');
      print('[API] Headers: $_authHeaders');

      final response = await http.get(uri, headers: _authHeaders);

      print('[API] Status: ${response.statusCode}');
      print('[API] Body: ${response.body}');

      return _decodeList(response);
    } on SocketException catch (e) {
      print('[API] SocketException: $e');
      return [];
    } on TimeoutException catch (e) {
      print('[API] TimeoutException: $e');
      return [];
    } catch (e, stack) {
      print('[API] Unknown error: $e');
      print('[API] Stack: $stack');
      return [];
    }
  }

  static Future<List<dynamic>> getCommandes({String? status}) async {
    try {
      final uri = status != null
          ? Uri.parse(
          '$baseUrl/api/commandes?status=${Uri.encodeComponent(status)}')
          : Uri.parse('$baseUrl/api/commandes');
      final response = await http.get(uri, headers: _authHeaders);
      return _decodeList(response);
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> assignCommande({
    required String commandeId,
    required String chauffeurId,
  }) async {
    print('>>> assignCommande called | commandeId: $commandeId | chauffeurId: $chauffeurId');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/commandes/assign/$commandeId/$chauffeurId'),
        headers: _authHeaders,
      );
      print('>>> assign status: ${response.statusCode}');
      print('>>> assign body: ${response.body}');

      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markLivree(String commandeId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/commandes/livree/$commandeId'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelCommande(String commandeId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/commandes/cancel/$commandeId'),

        headers: _authHeaders,
      );
      print('>>> cancel status: ${response.statusCode}');  // ← add
      print('>>> cancel body: ${response.body}');          // ← add
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // PYTHON AI  →  VRP NSGA-II (192.168.1.40:8000)
  // ─────────────────────────────────────────

  static Future<bool> pythonHealthCheck() async {
    try {
      final res = await http.get(
        Uri.parse('$pythonUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> deleteChauffeur(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/fournisseurs/$id'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> setupConducteurs({
    required List<dynamic> chauffeurs,
    required double fournisseurLat,
    required double fournisseurLon,
  }) async {
    try {
      final conducteurs = chauffeurs.map((c) => {
        'id': (c['_id'] ?? c['id']).toString(),
        'capacity': (c['capaciteCamion'] as num?)?.toDouble() ?? 0.0,
        'lat': fournisseurLat,
        'lon': fournisseurLon,
        'nom': c['nom'] ?? '',

      }).toList();

      final res = await http.post(
        Uri.parse('$pythonUrl/setup/conducteurs'),
        headers: _pythonHeaders,
        body: jsonEncode({'conducteurs': conducteurs}),
      );
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable. Is it running?'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> setupConducteursTestMode({
    required double fournisseurLat,
    required double fournisseurLon,
    required double totalCapacity, // sum of all order quantities
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/setup/conducteurs'),
        headers: _pythonHeaders,
        body: jsonEncode({
          'conducteurs': [
            {
              'id':       'test_driver_001',
              'capacity': totalCapacity * 1.5, // extra buffer so route is feasible
              'lat':      fournisseurLat,
              'lon':      fournisseurLon,
              'nom':      'Test Driver',
            }
          ],
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } on TimeoutException {
      return {'error': 'setupConducteurs timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  static Future<Map<String, dynamic>> sendCommandeToPython({
    required String id,
    required double lat,
    required double lon,
    required double demand,


    String description = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/commandes/add'),
        headers: _pythonHeaders,
        body: jsonEncode({
          'id': id,
          'lat': lat,
          'lon': lon,
          'demand': demand,
          'description': description,
        }),
      );
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable. Is it running?'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> addSecondaryRole() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/choose-role'),
        headers: _authHeaders,
        body: jsonEncode({'userId': userId, 'addSecondaryRole': true}),
      );
      final data = _decode(response);
      if (response.statusCode == 200) return data;
      return {'error': data['msg'] ?? 'Error'};
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> acceptCommandePython(String id) async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/commandes/accept'),
        headers: _pythonHeaders,
        body: jsonEncode({
          'commande_id': id,
          'action': 'accepter',
        }),
      );
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable. Is it running?'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> optimize() async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/optimisation/lancer'),
        headers: _pythonHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable. Is it running?'};
    } on TimeoutException {
      return {'error': 'Optimization timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSolution() async {
    try {
      final res = await http.get(
        Uri.parse('$pythonUrl/optimisation/solution'),
      );
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // NODE AI PROXY  →  /api/ai (optional)
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> optimiseRoute(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/optimise'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────
// COMMANDE  →  /api/commandes (AJOUTS)
// ─────────────────────────────────────────

  static Future<Map<String, dynamic>> updateCommandeStatus({
    required String commandeId,
    required String status,
    double? prix,
  }) async {
    try {
      // Use the correct endpoint based on status
      final endpoint = status == 'livrée'
          ? '$baseUrl/api/commandes/livree/$commandeId'
          : '$baseUrl/api/commandes/accept/$commandeId';

      final body = <String, dynamic>{'status': status};
      if (prix != null) body['prix'] = prix;

      final response = await http.put(
        Uri.parse(endpoint),   // ← was: /api/commandes/status/$commandeId
        headers: _authHeaders,
        body: jsonEncode(body),
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error. Check your internet.'};
    } on TimeoutException {
      return {'error': 'Request timed out. Try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// ✅ NOUVEAU : Récupérer une commande par ID
  static Future<Map<String, dynamic>> getCommandeById(String commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commandes/$commandeId'),
        headers: _authHeaders,
      );
      return _decode(response);
    } on SocketException {
      return {'error': 'Connection error.'};
    } on TimeoutException {
      return {'error': 'Request timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> initGraph() async {
    try {
      final res = await http.post(
        Uri.parse('$pythonUrl/optimisation/init'),
        headers: _pythonHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));
      return jsonDecode(res.body);
    } on SocketException {
      return {'error': 'Python API unreachable.'};
    } on TimeoutException {
      return {'error': 'Init timed out.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}