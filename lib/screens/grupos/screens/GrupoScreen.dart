/// Pantalla que muestra la información del grupo, vehículo y compañeros del usuario.
/// Permite ver el vehículo asignado, la dirección del grupo y la lista de compañeros.
/// Si no tienes grupo asignado, muestra un mensaje informativo.
/// Incluye acceso directo a la gestión del inventario del vehículo.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_smp/screens/vehiculos/screens/InventarioVehiculoScreen.dart';
import 'package:easy_localization/easy_localization.dart';

/// Pantalla que muestra la información del grupo, vehículo y compañeros del usuario
class GrupoScreen extends StatefulWidget {
  const GrupoScreen({super.key});

  @override
  State<GrupoScreen> createState() => _GrupoScreenState();
}

class _GrupoScreenState extends State<GrupoScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? grupoData;
  Map<String, dynamic>? vehiculoData;
  List<Map<String, dynamic>> companeros = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  /// Carga los datos del usuario, grupo, vehículo y compañeros.
  Future<void> cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    userData = userDoc.data();

    if (userData?['grupoId'] != null &&
        userData!['grupoId'].toString().isNotEmpty) {
      final grupoDoc =
          await FirebaseFirestore.instance
              .collection('grupos')
              .doc(userData!['grupoId'])
              .get();
      grupoData = grupoDoc.data();

      if (grupoData?['vehiculoId'] != null) {
        final vehiculoDoc =
            await FirebaseFirestore.instance
                .collection('vehiculos')
                .doc(grupoData!['vehiculoId'])
                .get();
        vehiculoData = vehiculoDoc.data();
        if (vehiculoData != null) {
          vehiculoData!['id'] = vehiculoDoc.id;
        }
      }

      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('grupoId', isEqualTo: userData!['grupoId'])
              .get();
      companeros =
          query.docs
              .where((doc) => doc.id != user.uid)
              .map((doc) => doc.data())
              .toList();
    } else {
      grupoData = null;
      vehiculoData = null;
      companeros = [];
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /// Construye el avatar de usuario a partir de base64 o muestra uno por defecto.
  Widget buildAvatar(String? base64, {double size = 54}) {
    if (base64 != null && base64.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(base64Decode(base64)),
          backgroundColor: Colors.white,
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
    );
  }

  /// Construye el avatar del vehículo a partir de base64 o muestra uno por defecto.
  Widget buildVehiculoAvatar(String? base64, {double size = 70}) {
    if (base64 != null && base64.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(base64Decode(base64)),
          backgroundColor: Colors.white,
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
      child: Icon(
        Icons.directions_car,
        size: size * 0.6,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6C63FF);
    final Color darkPurple = const Color(0xFF3F3D56);
    final Color lightBg = const Color(0xFFF5F4FB);

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool sinGrupo =
        userData?['grupoId'] == null || userData!['grupoId'].toString().isEmpty;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/blob-scene-haikei.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            grupoData?['nombre']?.toString().tr() ?? 'mi_grupo'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child:
              sinGrupo
                  ? Center(
                    child: Text(
                      'esperando_asignacion'.tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vehículo asignado al grupo
                        Card(
                          color: Colors.white.withOpacity(0.92),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                buildVehiculoAvatar(
                                  vehiculoData?['foto'] ?? '',
                                  size: 70,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehiculoData?['nombre']
                                                ?.toString()
                                                .tr() ??
                                            'no_asignado'.tr(),
                                        style: TextStyle(
                                          color: darkPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${'matricula'.tr()}: ${vehiculoData?['matricula'] ?? 'no_asignado'.tr()}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryPurple,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.inventory,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "gestionar_inventario".tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed:
                                            vehiculoData?['id'] != null
                                                ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => InventarioVehiculoScreen(
                                                            vehiculoId:
                                                                vehiculoData!['id'],
                                                          ),
                                                    ),
                                                  );
                                                }
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Dirección asignada al grupo
                        if (grupoData?['direccion'] != null &&
                            grupoData!['direccion'].toString().isNotEmpty)
                          Card(
                            color: lightBg.withOpacity(0.96),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF6C63FF),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      grupoData!['direccion'].toString().tr(),
                                      style: TextStyle(
                                        color: darkPurple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Compañeros del grupo (incluyéndote a ti)
                        Card(
                          color: Colors.white.withOpacity(0.93),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'companeros'.tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3F3D56),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (companeros.isEmpty && userData == null)
                                  Text(
                                    "no_hay_companeros_asignados".tr(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      // Tu propio perfil primero
                                      if (userData != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                          ),
                                          child: Row(
                                            children: [
                                              buildAvatar(
                                                userData?['photoBase64'],
                                                size: 44,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                userData?['displayName']
                                                        ?.toString()
                                                        .tr() ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF3F3D56),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Los demás compañeros
                                      ...companeros.map(
                                        (c) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                          ),
                                          child: Row(
                                            children: [
                                              buildAvatar(
                                                c['photoBase64'],
                                                size: 44,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                c['displayName']
                                                        ?.toString()
                                                        .tr() ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF3F3D56),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
