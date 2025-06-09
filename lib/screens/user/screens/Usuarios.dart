/// Pantalla de perfil de usuario con foto, nombre y fichaje.
/// Permite actualizar la foto de perfil, fichar entrada/salida y realiza tracking de ubicación
/// solo cuando el usuario está fichado. El tracking se detiene automáticamente al cambiar de día.
/// Incluye feedback visual y animaciones.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img; // al inicio del archivo

// Suscripción global para el tracking de ubicación
StreamSubscription<Position>? _posicionSub;

/// Inicia el tracking de ubicación si el usuario está fichado
Future<void> iniciarTracking() async {
  final usuario = FirebaseAuth.instance.currentUser;
  if (usuario == null) return;

  // Verifica si el usuario está fichado
  final doc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(usuario.uid)
          .get();
  final data = doc.data();
  if (data == null || data['hasCheckedIn'] != true) {
    detenerTracking();
    return;
  }

  LocationPermission permiso = await Geolocator.requestPermission();
  if (permiso == LocationPermission.denied ||
      permiso == LocationPermission.deniedForever) {
    return;
  }

  _posicionSub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    ),
  ).listen((Position posicion) async {
    await FirebaseFirestore.instance.collection('users').doc(usuario.uid).set({
      'lat': posicion.latitude,
      'lng': posicion.longitude,
      'accuracy': posicion.accuracy,
    }, SetOptions(merge: true));
  });
}

/// Detiene el tracking de ubicación
void detenerTracking() {
  _posicionSub?.cancel();
  _posicionSub = null;
}

/// Pantalla de perfil de usuario con foto, nombre y fichaje
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  String? photoBase64;
  String? displayName;

  @override
  void initState() {
    super.initState();
    iniciarTracking();
    _checkAndAutoDesactivar();
  }

  /// Permite actualizar la foto de perfil del usuario
  Future<void> _updateProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final File file = File(pickedFile.path);
          final bytes = await file.readAsBytes();

          // Redimensionar y comprimir la imagen
          img.Image? image = img.decodeImage(bytes);
          if (image != null) {
            // Calcula el nuevo tamaño manteniendo la proporción
            int maxSide = 400;
            int width = image.width;
            int height = image.height;
            if (width > height) {
              if (width > maxSide) {
                height = (height * maxSide / width).round();
                width = maxSide;
              }
            } else {
              if (height > maxSide) {
                width = (width * maxSide / height).round();
                height = maxSide;
              }
            }
            final resized = img.copyResize(image, width: width, height: height);

            // Comprime a jpg calidad 80
            final jpg = img.encodeJpg(resized, quality: 80);

            final base64Image = base64Encode(jpg);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'photoBase64': base64Image}, SetOptions(merge: true));

            setState(() {
              photoBase64 = base64Image;
            });
          }
        }
      }
    } catch (e) {
      print("Error al actualizar la foto de perfil: $e");
    }
  }

  /// Desactiva el fichaje automáticamente si es un nuevo día
  Future<void> _checkAndAutoDesactivar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data == null) return;

    final bool hasCheckedIn = data['hasCheckedIn'] == true;
    if (!hasCheckedIn) return;

    final now = DateTime.now();
    // Si es después de las 00:00 (nuevo día)
    if (now.hour == 0 && now.minute >= 0) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'hasCheckedIn': false,
      }, SetOptions(merge: true));
      detenerTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/blob-scene-haikei.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child:
              user == null
                  ? const CircularProgressIndicator()
                  : StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final photoBase64Stream =
                            data['photoBase64'] as String?;
                        final displayNameStream =
                            data['displayName'] as String?;
                        final hasCheckedInStream =
                            data['hasCheckedIn'] as bool? ?? false;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "perfil".tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _updateProfilePicture,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        hasCheckedInStream
                                            ? Colors.green
                                            : Colors.red,
                                    width: 5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 100,
                                  backgroundImage: _getProfileImage(
                                    photoBase64Stream,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              displayNameStream ?? "nombre_no_disponible".tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 32),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final nuevoEstado = !hasCheckedInStream;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user!.uid)
                                      .set({
                                        'hasCheckedIn': nuevoEstado,
                                      }, SetOptions(merge: true));
                                  if (nuevoEstado) {
                                    await iniciarTracking();
                                  } else {
                                    detenerTracking();
                                  }
                                },
                                icon: Icon(
                                  hasCheckedInStream
                                      ? Icons.logout
                                      : Icons.login,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  hasCheckedInStream
                                      ? "fichar_salida".tr()
                                      : "fichar_entrada".tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      hasCheckedInStream
                                          ? Colors.red
                                          : Colors.green,
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 80,
                                    vertical: 25,
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        );
                      }
                      return Text("no_hay_datos_usuario".tr());
                    },
                  ),
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(String? base64String) {
    if (base64String == null) {
      return const AssetImage('assets/images/Logo_Proyecto_SMP.png');
    }
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      // Si falla el decode, usa la imagen por defecto
      return const AssetImage('assets/images/Logo_Proyecto_SMP.png');
    }
  }
}
