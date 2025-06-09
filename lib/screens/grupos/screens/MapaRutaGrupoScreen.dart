/// Pantalla que muestra el mapa con la ruta asignada al grupo y la ubicación actual del usuario.
/// Dibuja la ruta entre el usuario y el destino del grupo, mostrando marcadores personalizados.
/// Permite centrar el mapa en la ubicación del usuario y seguir su movimiento en tiempo real.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

// Pantalla que muestra el mapa con la ruta del grupo y tu ubicación
class MapaRutaGrupoScreen extends StatefulWidget {
  final String grupoId;
  const MapaRutaGrupoScreen({super.key, required this.grupoId});

  @override
  State<MapaRutaGrupoScreen> createState() => _MapaRutaGrupoScreenState();
}

class _MapaRutaGrupoScreenState extends State<MapaRutaGrupoScreen> {
  LatLng? _rutaLatLng; // Coordenadas de la ruta del grupo
  LatLng? _miLatLng; // Coordenadas de mi ubicación actual
  String? _direccion; // Dirección de la ruta
  bool _loading = true; // ¿Está cargando la pantalla?
  ImageProvider? _miFotoPerfil; // Foto de perfil del usuario
  bool _seguirUsuario = true; // ¿El mapa sigue la ubicación del usuario?

  final MapController _mapController = MapController();

  final Color primaryPurple = const Color(0xFF6C63FF);
  final Color accentPurple = const Color(0xFF5F52EE);
  final Color darkPurple = const Color(0xFF3F3D56);

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // Carga la ruta y la ubicación/foto del usuario
  Future<void> _cargarTodo() async {
    await _cargarRuta();
    await _cargarMiUbicacionYFoto();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  // Carga la dirección y la convierte a coordenadas
  Future<void> _cargarRuta() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('grupos')
            .doc(widget.grupoId)
            .get();
    final data = doc.data();
    if (data == null ||
        data['ruta'] == null ||
        data['ruta'].toString().isEmpty) {
      _direccion = null;
      return;
    }
    _direccion = data['ruta'];
    try {
      final locations = await locationFromAddress(_direccion!);
      if (locations.isNotEmpty) {
        _rutaLatLng = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
    } catch (_) {}
  }

  // Carga la ubicación actual y la foto de perfil del usuario
  Future<void> _cargarMiUbicacionYFoto() async {
    // Ubicación
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    _miLatLng = LatLng(pos.latitude, pos.longitude);

    // Foto de perfil en base64
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null &&
          data['photoBase64'] != null &&
          data['photoBase64'] != "") {
        try {
          _miFotoPerfil = MemoryImage(base64Decode(data['photoBase64']));
        } catch (_) {
          _miFotoPerfil = const AssetImage("assets/images/default_profile.png");
        }
      } else {
        _miFotoPerfil = const AssetImage("assets/images/default_profile.png");
      }
    }
  }

  // Centra el mapa en la ubicación del usuario
  void _centrarEnUsuario(LatLng miLatLng) {
    _mapController.move(miLatLng, _mapController.zoom);
    setState(() {
      _seguirUsuario = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng centroDefault = LatLng(40.4168, -3.7038); // Madrid por defecto

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
          floatingActionButton:
              !_seguirUsuario
                  ? FloatingActionButton(
                    backgroundColor: primaryPurple,
                    onPressed: () {
                      if (_miLatLng != null) {
                        _centrarEnUsuario(_miLatLng!);
                      }
                    },
                    tooltip: 'centrar_en_mi_ubicacion'.tr(),
                    child: const Icon(Icons.my_location, color: Colors.white),
                  )
                  : null,
          body:
              _loading || _rutaLatLng == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<Position>(
                    stream: Geolocator.getPositionStream(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.high,
                        distanceFilter: 5,
                      ),
                    ),
                    builder: (context, snapshot) {
                      LatLng? miLatLng = _miLatLng;
                      if (snapshot.hasData) {
                        miLatLng = LatLng(
                          snapshot.data!.latitude,
                          snapshot.data!.longitude,
                        );
                        if (_seguirUsuario) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _mapController.move(miLatLng!, _mapController.zoom);
                          });
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PhysicalModel(
                          color: Colors.transparent,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(24),
                          clipBehavior: Clip.antiAlias,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center:
                                    miLatLng ?? _rutaLatLng ?? centroDefault,
                                zoom: 11, // Menos zoom para ver más área
                                onPositionChanged: (pos, hasGesture) {
                                  if (hasGesture && _seguirUsuario) {
                                    setState(() {
                                      _seguirUsuario = false;
                                    });
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.proyecto_smp',
                                ),
                                if (miLatLng != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        width: 44,
                                        height: 44,
                                        point: miLatLng,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: primaryPurple,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryPurple
                                                    .withOpacity(0.2),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.white,
                                            backgroundImage: _miFotoPerfil,
                                            child:
                                                _miFotoPerfil == null
                                                    ? const Icon(
                                                      Icons.person,
                                                      size: 18,
                                                      color: Colors.grey,
                                                    )
                                                    : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 44,
                                      height: 44,
                                      point: _rutaLatLng!,
                                      child: Icon(
                                        Icons.flag_rounded,
                                        color: accentPurple,
                                        size: 36,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (miLatLng != null)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: [miLatLng, _rutaLatLng!],
                                        color: Colors.deepPurple,
                                        strokeWidth: 5,
                                        gradientColors: [
                                          primaryPurple,
                                          accentPurple,
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
