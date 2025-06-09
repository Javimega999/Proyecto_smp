/// Pantalla de chat grupal en tiempo real para un grupo.
/// Permite enviar y recibir mensajes instantáneamente, mostrando nombre, foto y rol (admin) de cada usuario.
/// Soporta notificaciones push, scroll automático y burbujas de mensaje diferenciadas para el usuario actual.
library;

import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_smp/notis/FcmService.dart';

class ChatGrupoScreen extends StatefulWidget {
  final String grupoId;
  final String? nombreGrupo;
  const ChatGrupoScreen({required this.grupoId, this.nombreGrupo, super.key});

  @override
  State<ChatGrupoScreen> createState() => _ChatGrupoScreenState();
}

class _ChatGrupoScreenState extends State<ChatGrupoScreen> {
  final TextEditingController controladorMensaje = TextEditingController();
  final ScrollController controladorScroll = ScrollController();
  final Map<String, ImageProvider> _profileImageCache = {};

  /// Inicializa notificaciones y scroll al final del chat.
  @override
  void initState() {
    super.initState();
    // Inicializa las notificaciones FCM y el guardado de token
    FcmService().initNotifications();
    FcmService().initFCM(
      onMessage: (message) {
        final notification = message.notification;
        if (notification != null) {
          FcmService().mostrarNotificacion(
            notification.title ?? '',
            notification.body ?? '',
          );
        }
      },
    );
    FcmService().guardarTokenFCM();
    FcmService().listenTokenRefresh();

    // Desplaza al final del chat al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controladorScroll.hasClients) {
        controladorScroll.jumpTo(controladorScroll.position.maxScrollExtent);
      }
    });
  }

  /// Envía un mensaje al chat del grupo.
  void enviarMensaje() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null && controladorMensaje.text.trim().isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(usuario.uid)
              .get();
      final datosUsuario = doc.data() ?? {};
      await FirebaseFirestore.instance
          .collection('grupos')
          .doc(widget.grupoId)
          .collection('chat')
          .add({
            'texto': controladorMensaje.text.trim(),
            'creadoEn': FieldValue.serverTimestamp(),
            'uid': usuario.uid,
            'nombre': datosUsuario['displayName'] ?? 'Usuario',
            'fotoBase64': datosUsuario['photoBase64'],
            'isAdmin': datosUsuario['isAdmin'] == true,
          });
      controladorMensaje.clear();
      if (controladorScroll.hasClients) {
        controladorScroll.animateTo(
          controladorScroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// Construye la interfaz del chat grupal.
  @override
  Widget build(BuildContext context) {
    // Colores principales del chat
    final Color primaryPurple = const Color(0xFF6C63FF);
    final Color accentPurple = const Color(0xFF5F52EE);
    final Color darkPurple = const Color(0xFF3F3D56);
    final Color lightBg = const Color(0xFFFFFFFF);

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('grupos')
              .doc(widget.grupoId)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.data!.exists) {
          return const Center(
            child: Text(
              'grupo_no_existe',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        }
        final usuario = FirebaseAuth.instance.currentUser;

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/blob-scene-haikei.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar:
                widget.nombreGrupo != null
                    ? AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: Text(
                        widget.nombreGrupo ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                    )
                    : null,
            body: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  // Lista de mensajes del chat
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('grupos')
                              .doc(widget.grupoId)
                              .collection('chat')
                              .orderBy('creadoEn', descending: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              "no_hay_mensajes_en_este_grupo".tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        final mensajes = snapshot.data!.docs;

                        // Desplaza al final cuando hay mensajes nuevos
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (controladorScroll.hasClients) {
                            controladorScroll.jumpTo(
                              controladorScroll.position.maxScrollExtent,
                            );
                          }
                        });

                        return ListView.builder(
                          controller: controladorScroll,
                          itemCount: mensajes.length,
                          itemBuilder: (context, indice) {
                            final datos =
                                mensajes[indice].data() as Map<String, dynamic>;
                            final esMio =
                                usuario != null && usuario.uid == datos['uid'];
                            final fotoBase64 = datos['fotoBase64'];
                            final nombre = datos['nombre'] ?? 'Usuario';
                            final uidMensaje = datos['uid'];
                            final String cacheKey = uidMensaje ?? '';
                            ImageProvider? imagenPerfil;

                            // Cache de imágenes de perfil para evitar decodificar cada vez
                            if (_profileImageCache.containsKey(cacheKey)) {
                              imagenPerfil = _profileImageCache[cacheKey];
                            } else if (fotoBase64 != null && fotoBase64 != "") {
                              try {
                                imagenPerfil = MemoryImage(
                                  base64Decode(fotoBase64),
                                );
                              } catch (_) {
                                imagenPerfil = const AssetImage(
                                  "assets/images/default_profile.png",
                                );
                              }
                              _profileImageCache[cacheKey] = imagenPerfil;
                            } else {
                              imagenPerfil = const AssetImage(
                                "assets/images/default_profile.png",
                              );
                              _profileImageCache[cacheKey] = imagenPerfil;
                            }

                            final isAdmin = datos['isAdmin'] == true;

                            // Widget para mostrar el nombre y el icono de admin si corresponde
                            Widget nombreWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdmin)
                                  const Icon(
                                    Icons.admin_panel_settings,
                                    color: Color(0xFF40C4FF),
                                    size: 18,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isAdmin
                                            ? const Color(0xFF40C4FF)
                                            : (esMio ? lightBg : darkPurple),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            );

                            // Burbuja de mensaje
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              alignment:
                                  esMio
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment:
                                    esMio
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!esMio)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundImage: imagenPerfil,
                                        backgroundColor: lightBg,
                                      ),
                                    ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          esMio
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                esMio
                                                    ? accentPurple.withOpacity(
                                                      0.95,
                                                    )
                                                    : lightBg.withOpacity(0.90),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                18,
                                              ),
                                              topRight: const Radius.circular(
                                                18,
                                              ),
                                              bottomLeft: Radius.circular(
                                                esMio ? 18 : 0,
                                              ),
                                              bottomRight: Radius.circular(
                                                esMio ? 0 : 18,
                                              ),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: darkPurple.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              nombreWidget,
                                              const SizedBox(height: 2),
                                              Text(
                                                datos['texto'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      esMio
                                                          ? lightBg
                                                          : darkPurple,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (esMio)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundImage: imagenPerfil,
                                        backgroundColor: lightBg,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Caja de texto y botón para enviar mensajes
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: lightBg.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryPurple,
                                width: 1.2,
                              ),
                            ),
                            child: TextField(
                              controller: controladorMensaje,
                              decoration: InputDecoration(
                                hintText: 'escribe_un_mensaje'.tr(),
                                border: InputBorder.none,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF3F3D56),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3F3D56),
                              ),
                              onSubmitted: (_) => enviarMensaje(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: enviarMensaje,
                            tooltip: 'enviar'.tr(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
