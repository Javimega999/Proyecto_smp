/// Pantalla que muestra en tiempo real los usuarios activos (que han hecho check-in).
/// Solo accesible para administradores. Muestra la foto, nombre y correo de cada usuario activo,
/// con un icono de verificación verde.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';

class UsuariosActivosScreen extends StatelessWidget {
  const UsuariosActivosScreen({super.key});

  /// Construye la interfaz que muestra la lista de usuarios activos.
  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6C63FF);
    final Color lightBg = const Color(0xFFFFFFFF);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/blob-scene-haikei.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Escucha en tiempo real los usuarios con hasCheckedIn = true
        body: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .where('hasCheckedIn', isEqualTo: true)
                  .snapshots(),
          builder: (context, snapshot) {
            // Mientras carga, muestra spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si no hay usuarios activos, muestra mensaje
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'no_hay_usuarios_activos'.tr(),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }
            final usuarios = snapshot.data!.docs;
            // Lista de usuarios activos
            return ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final data = usuarios[index].data() as Map<String, dynamic>;
                final nombre =
                    data['displayName'] ?? data['email'] ?? 'Usuario';
                final photoBase64 = data['photoBase64'] as String?;
                ImageProvider foto;

                // Si hay foto en base64, la decodifica, si no, pone una imagen por defecto
                if (photoBase64 != null && photoBase64.isNotEmpty) {
                  try {
                    foto = MemoryImage(base64Decode(photoBase64));
                  } catch (_) {
                    foto = const AssetImage(
                      'assets/images/Logo_Proyecto_SMP.png',
                    );
                  }
                } else {
                  foto = const AssetImage(
                    'assets/images/Logo_Proyecto_SMP.png',
                  );
                }

                return Card(
                  color: lightBg.withOpacity(0.93),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundImage: foto, radius: 28),
                    title: Text(
                      nombre,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      data['email'] ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold, // Negrita para el correo
                      ),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
