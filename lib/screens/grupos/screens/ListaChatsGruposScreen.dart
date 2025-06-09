/// Pantalla que muestra la lista de todos los grupos y acceso a su chat.
/// Permite ver todos los grupos existentes y acceder al chat de cada uno.
/// Si no hay grupos, muestra un mensaje informativo.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ChatGrupoScreen.dart';

class ListaChatsGruposScreen extends StatelessWidget {
  const ListaChatsGruposScreen({super.key});

  /// Construye la interfaz con la lista de grupos y acceso a su chat.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chats_de_grupos'.tr()),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF3F3D56),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              final nombre =
                  (grupo['nombre'] as String?)?.isNotEmpty == true
                      ? grupo['nombre']
                      : 'sin_nombre'.tr();
              return Card(
                color: Colors.white.withOpacity(0.93),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      color: Color(0xFF3F3D56),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'id_grupo'.tr(args: [grupo.id]),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF6C63FF),
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
    );
  }
}
