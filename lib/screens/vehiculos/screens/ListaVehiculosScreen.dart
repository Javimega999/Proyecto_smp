/// Pantalla que muestra la lista de vehículos y permite acceder a su inventario.
/// Muestra foto, nombre y matrícula de cada vehículo. Si no hay vehículos, muestra mensaje informativo.
/// Permite navegar al inventario de cada vehículo con un solo toque.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'InventarioVehiculoScreen.dart';
import 'package:easy_localization/easy_localization.dart';

// Pantalla que muestra la lista de vehículos y permite acceder a su inventario
class ListaVehiculosScreen extends StatelessWidget {
  const ListaVehiculosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6C63FF);
    final Color darkPurple = const Color(0xFF3F3D56);
    final Color lightBg = const Color(0xFFF5F4FB);

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
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'vehiculos'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('vehiculos').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final vehiculos = snapshot.data!.docs;
            if (vehiculos.isEmpty) {
              return Center(
                child: Text(
                  'no_hay_vehiculos_registrados'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              itemCount: vehiculos.length,
              itemBuilder: (context, index) {
                final vehiculo = vehiculos[index];
                final fotoBase64 = vehiculo['foto'] ?? '';
                ImageProvider? foto;
                if (fotoBase64.isNotEmpty) {
                  try {
                    foto = MemoryImage(base64Decode(fotoBase64));
                  } catch (_) {
                    foto = const AssetImage(
                      "assets/images/default_profile.png",
                    );
                  }
                } else {
                  foto = const AssetImage("assets/images/default_profile.png");
                }
                return Card(
                  color: lightBg.withOpacity(0.96),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryPurple, width: 2),
                      ),
                      child: Hero(
                        tag: 'vehiculo_${vehiculo.id}',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: foto,
                          backgroundColor: primaryPurple.withOpacity(0.13),
                        ),
                      ),
                    ),
                    title: Text(
                      vehiculo['nombre']?.toString().tr() ?? 'sin_nombre'.tr(),
                      style: TextStyle(
                        color: darkPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${'matricula'.tr()}: ${vehiculo['matricula'] ?? ''}',
                      style: TextStyle(
                        color: darkPurple.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => InventarioVehiculoScreen(
                                vehiculoId: vehiculo.id,
                              ),
                        ),
                      );
                    },
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
