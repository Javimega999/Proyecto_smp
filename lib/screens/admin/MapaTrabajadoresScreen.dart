/// Pantalla para visualizar en tiempo real la ubicación de todos los trabajadores fichados en el mapa.
/// Solo accesible para administradores. Permite seleccionar un usuario para centrar el mapa en su posición.
/// Muestra los trabajadores como marcadores personalizados con foto y nombre.
library;

import 'dart:convert';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla para ver a los trabajadores en el mapa en tiempo real (solo admin)
class MapaTrabajadoresScreen extends StatefulWidget {
  const MapaTrabajadoresScreen({super.key});

  @override
  State<MapaTrabajadoresScreen> createState() => _MapaTrabajadoresScreenState();
}

class _MapaTrabajadoresScreenState extends State<MapaTrabajadoresScreen> {
  StreamSubscription<Position>?
  _posicionSub; // Suscripción al tracking de posición
  final MapController _mapController = MapController(); // Controlador del mapa
  String? _usuarioSeleccionado; // UID del usuario seleccionado en el mapa
  LatLng? _centroActual; // Centro actual del mapa

  final Color primaryPurple = const Color(0xFF6C63FF);
  final Color accentPurple = const Color(0xFF5F52EE);
  final Color darkPurple = const Color(0xFF3F3D56);
  final Color lightBg = const Color(0xFFFFFFFF);

  /// Libera la suscripción al tracking al cerrar la pantalla.
  @override
  void dispose() {
    detenerTracking();
    super.dispose();
  }

  /// Inicia el tracking de la posición del usuario actual y la sube a Firestore.
  Future<void> iniciarTracking() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    LocationPermission permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return;
    }

    _posicionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, // máxima precisión
        distanceFilter: 5, // cada 5 metros
      ),
    ).listen((Position posicion) async {
      await FirebaseFirestore.instance.collection('users').doc(usuario.uid).set(
        {
          'lat': posicion.latitude,
          'lng': posicion.longitude,
          'accuracy':
              posicion.accuracy, // opcional, para mostrar círculo de precisión
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Detiene el tracking de la posición.
  void detenerTracking() {
    _posicionSub?.cancel();
    _posicionSub = null;
  }

  /// Construye la interfaz del mapa con los trabajadores y el selector de usuario.
  @override
  Widget build(BuildContext context) {
    final LatLng centroDefault = LatLng(
      40.4168,
      -3.7038,
    ); // Centro por defecto (Madrid)

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/blob-scene-haikei.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: PhysicalModel(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .where('hasCheckedIn', isEqualTo: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final trabajadores =
                        snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data.containsKey('lat') &&
                              data.containsKey('lng');
                        }).toList();

                    final Map<String, Map<String, dynamic>> mapaUsuarios = {
                      for (var doc in trabajadores)
                        doc.id: doc.data() as Map<String, dynamic>,
                    };

                    // Determina el centro: si hay usuario seleccionado, usa su posición
                    LatLng center;
                    if (_usuarioSeleccionado != null &&
                        mapaUsuarios[_usuarioSeleccionado!] != null) {
                      final data = mapaUsuarios[_usuarioSeleccionado!]!;
                      center = LatLng(data['lat'], data['lng']);
                    } else if (trabajadores.isNotEmpty) {
                      final data =
                          trabajadores.first.data() as Map<String, dynamic>;
                      center = LatLng(data['lat'], data['lng']);
                    } else {
                      center = centroDefault;
                    }

                    // Actualiza el centro solo si cambia
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_centroActual == null ||
                          _centroActual!.latitude != center.latitude ||
                          _centroActual!.longitude != center.longitude) {
                        // Si seleccionas un usuario, haz zoom a 18, si no, mantén el zoom actual
                        final double zoom =
                            _usuarioSeleccionado != null
                                ? 18.0
                                : _mapController.camera.zoom;
                        _mapController.move(center, zoom);
                        setState(() {
                          _centroActual = center;
                        });
                      }
                    });

                    final idsTrabajadores =
                        trabajadores.map((doc) => doc.id).toList();
                    if (_usuarioSeleccionado != null &&
                        !idsTrabajadores.contains(_usuarioSeleccionado)) {
                      // Si el usuario seleccionado ya no está, lo reseteamos
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _usuarioSeleccionado = null;
                        });
                      });
                    }

                    return Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(center: center, zoom: 13),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.proyecto_smp',
                            ),
                            MarkerLayer(
                              markers:
                                  trabajadores.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final nombre =
                                        data['fullName'] ??
                                        data['displayName'] ??
                                        'Usuario';
                                    final fotoBase64 = data['photoBase64'];
                                    ImageProvider imagenPerfil;
                                    if (fotoBase64 != null &&
                                        fotoBase64 != "") {
                                      try {
                                        imagenPerfil = MemoryImage(
                                          base64Decode(fotoBase64),
                                        );
                                      } catch (_) {
                                        imagenPerfil = const AssetImage(
                                          "assets/images/default_profile.png",
                                        );
                                      }
                                    } else {
                                      imagenPerfil = const AssetImage(
                                        "assets/images/default_profile.png",
                                      );
                                    }
                                    final pos = LatLng(
                                      data['lat'],
                                      data['lng'],
                                    );
                                    return Marker(
                                      width: 180,
                                      height: 80,
                                      point: pos,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Etiqueta flotante arriba del punto
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: lightBg.withOpacity(0.95),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryPurple
                                                      .withOpacity(0.13),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: primaryPurple,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: lightBg,
                                                  backgroundImage: imagenPerfil,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    nombre,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Punto morado (tracker) en el centro
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.easeInOut,
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: primaryPurple,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: lightBg,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryPurple
                                                      .withOpacity(0.25),
                                                  blurRadius: 14,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                        // Selector de usuarios arriba a la derecha
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value:
                                  idsTrabajadores.contains(_usuarioSeleccionado)
                                      ? _usuarioSeleccionado
                                      : null,
                              hint: Text("selecciona_usuario".tr()),
                              underline: Container(),
                              items:
                                  trabajadores.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final nombre =
                                        data['displayName'] ?? 'usuario'.tr();
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(nombre),
                                    );
                                  }).toList(),
                              onChanged: (String? uid) {
                                setState(() {
                                  _usuarioSeleccionado = uid;
                                  // El centro se actualizará automáticamente en el addPostFrameCallback
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
