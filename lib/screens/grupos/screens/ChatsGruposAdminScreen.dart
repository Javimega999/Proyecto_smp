/// Pantalla para administradores que muestra la lista de todos los grupos existentes.
/// Permite acceder al chat de cualquier grupo tocando en la lista.
/// Si no hay grupos, muestra un mensaje informativo.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ChatGrupoScreen.dart';

class ChatsGruposAdminScreen extends StatelessWidget {
  const ChatsGruposAdminScreen({super.key});

  /// Construye la interfaz con la lista de grupos y acceso a su chat.
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
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('grupos').snapshots(),
            builder: (context, snapshot) {
              // Mientras carga, muestra spinner
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Si no hay grupos, muestra mensaje
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'no_hay_grupos_creados'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF3F3D56),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                );
              }
              final grupos = snapshot.data!.docs;
              // Lista de grupos
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 12,
                ),
                itemCount: grupos.length,
                itemBuilder: (context, index) {
                  final grupo = grupos[index];
                  final data = grupo.data() as Map<String, dynamic>;
                  final nombre =
                      (data['nombre'] as String?)?.isNotEmpty == true
                          ? data['nombre']
                          : 'grupo_sin_nombre'.tr();
                  return Card(
                    color: lightBg.withOpacity(0.92),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryPurple.withOpacity(0.15),
                        child: const Icon(
                          Icons.groups,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                          color: Color(0xFF3F3D56),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: primaryPurple,
                        size: 20,
                      ),
                      // Al tocar, navega al chat de ese grupo
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChatGrupoScreen(
                                  grupoId: grupo.id,
                                  nombreGrupo: nombre,
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
      ),
    );
  }
}
