/// Pantalla que muestra el chat del grupo al que pertenece el usuario actual.
/// Si el usuario no tiene grupo asignado, muestra un mensaje informativo.
/// Utiliza ChatGrupoScreen para mostrar el chat en tiempo real del grupo correspondiente.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ChatGrupoScreen.dart';

class ChatMiGrupoScreen extends StatelessWidget {
  const ChatMiGrupoScreen({super.key});

  /// Construye la pantalla del chat de mi grupo o un mensaje si no tiene grupo.
  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    // Si no está autenticado, muestra mensaje
    if (usuario == null) {
      return Center(child: Text('no_autenticado'.tr()));
    }
    // Busca los datos del usuario para saber a qué grupo pertenece
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(usuario.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('error_cargando_datos'.tr()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _noGrupoWidget();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final grupoId = data?['grupoId'];
        final nombreGrupo = data?['grupoNombre'];
        // Si no tiene grupo asignado, muestra mensaje
        if (grupoId == null || grupoId.isEmpty) {
          return _noGrupoWidget();
        }
        // Si tiene grupo, muestra el chat del grupo
        return ChatGrupoScreen(
          grupoId: grupoId,
          nombreGrupo:
              (nombreGrupo is String && nombreGrupo.isNotEmpty)
                  ? nombreGrupo
                  : null,
        );
      },
    );
  }

  /// Widget para mostrar cuando el usuario no tiene grupo asignado.
  Widget _noGrupoWidget() {
    return Center(
      child: Text(
        'no_asignado_a_grupo'.tr(),
        style: const TextStyle(fontSize: 18, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
