/// Pantalla principal de navegación de la app.
/// Permite cambiar entre las diferentes secciones principales (perfil, chat, grupo, mapa, etc.)
/// según el rol del usuario (admin o usuario normal). Si el usuario es admin, puede alternar
/// entre la vista de usuario y la vista de administración, accediendo a funciones exclusivas.
/// Incluye barra de navegación inferior y AppBar dinámico según la sección y el rol.
library;

import 'package:flutter/material.dart';
import 'package:proyecto_smp/menu/popup_menu.dart';
import 'package:proyecto_smp/screens/admin/UsuariosActivosScreen.dart';
import 'package:proyecto_smp/screens/grupos/screens/ChatMiGrupoScreen.dart';
import 'package:proyecto_smp/screens/admin/CrearUsuarioScreen.dart';
import 'package:proyecto_smp/screens/admin/GestionGruposScreen.dart';
import 'package:proyecto_smp/screens/admin/MapaTrabajadoresScreen.dart';
import 'package:proyecto_smp/screens/user/screens/Usuarios.dart';
import 'package:proyecto_smp/screens/grupos/screens/GrupoScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_smp/screens/vehiculos/screens/CrearVehiculoScreen.dart';
import 'package:proyecto_smp/screens/vehiculos/screens/ListaVehiculosScreen.dart';
import 'package:proyecto_smp/screens/grupos/screens/ChatsGruposAdminScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:proyecto_smp/screens/grupos/screens/MapaRutaGrupoScreen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int currentIndex = 0; // Índice de la pestaña actual
  bool isAdmin = false; // ¿El usuario es admin?
  bool loading = true; // ¿Está cargando la info del usuario?
  bool adminView =
      false; // Por defecto, todos (incluido admin) ven la vista normal

  // Colores principales de la app
  final Color primaryPurple = const Color(0xFF6C63FF);
  final Color accentPurple = const Color(0xFF5F52EE);
  final Color darkPurple = const Color(0xFF3F3D56);
  final Color navBarPurple = const Color(0xFF2D254C);
  final Color lightBg = const Color(0xFFFFFFFF);

  /// Devuelve la lista de pantallas según el rol y la vista actual.
  List<Widget> get screens {
    if (isAdmin && adminView) {
      return [
        CrearUsuarioScreen(),
        CrearVehiculoScreen(),
        ListaVehiculosScreen(),
        UsuariosActivosScreen(),
      ];
    }
    return [
      UsuariosScreen(),
      isAdmin ? ChatsGruposAdminScreen() : ChatMiGrupoScreen(),
      isAdmin ? GestionGruposScreen() : GrupoScreen(),
      isAdmin
          ? MapaTrabajadoresScreen()
          : FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final grupoId = data?['grupoId'];
              if (grupoId == null || grupoId.isEmpty) {
                return const Center(child: Text('No tienes grupo asignado.'));
              }
              return MapaRutaGrupoScreen(grupoId: grupoId);
            },
          ),
    ];
  }

  /// Devuelve los items del BottomNavigationBar según el rol y la vista actual.
  List<BottomNavigationBarItem> get navItems {
    if (isAdmin && adminView) {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_add),
          label: tr('crear_usuario'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.directions_car),
          label: tr('crear_vehiculo'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory),
          label: tr('inventarios'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.verified_user),
          label: tr('usuarios_activos'),
        ),
      ];
    }
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: tr('perfil'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.forum),
        label: isAdmin ? tr('chats_grupos') : tr('chat_grupal'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.groups),
        label: isAdmin ? tr('asignar_grupos') : tr('grupo'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.map_rounded),
        label: tr('mapa'),
      ),
    ];
  }

  /// Comprueba si el usuario es admin y actualiza el estado.
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  /// Consulta en Firestore si el usuario es admin y actualiza variables de estado.
  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        isAdmin = doc.data()?['isAdmin'] == true;
        loading = false;
      });
    } else {
      setState(() {
        isAdmin = false;
        loading = false;
      });
    }
  }

  /// Construye la UI principal del menú, con AppBar, navegación y contenido.
  @override
  Widget build(BuildContext context) {
    if (loading) {
      // Mientras carga, muestra un spinner
      return const Center(child: CircularProgressIndicator());
    }

    // Títulos de cada pestaña según el rol y la vista
    final List<String> titles =
        isAdmin && adminView
            ? [
              tr('crear_usuario'),
              tr('crear_vehiculo'),
              tr('inventarios'),
              tr('usuarios_activos'),
            ]
            : [
              tr('perfil'),
              isAdmin ? tr('chats_grupos') : tr('chat_grupal'),
              isAdmin ? tr('asignar_grupos') : tr('grupo'),
              tr('mapa'),
            ];

    // Si el índice actual es mayor que el máximo, lo ajustamos
    final int maxIndex = screens.length - 1;
    if (currentIndex > maxIndex) {
      currentIndex = maxIndex;
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/blob-scene-haikei.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            titles[currentIndex],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 28,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            /// Botón para cambiar entre vista admin y usuario (solo si es admin)
            if (isAdmin)
              IconButton(
                icon: Icon(
                  adminView ? Icons.visibility : Icons.admin_panel_settings,
                  color: Colors.white,
                ),
                tooltip:
                    adminView
                        ? tr('cambiar_a_vista_usuario')
                        : tr('cambiar_a_vista_admin'),
                onPressed: () {
                  setState(() {
                    adminView = !adminView;
                    currentIndex = 0;
                  });
                },
              ),
            const CustomPopupMenu(),
          ],
        ),

        /// Muestra la pantalla seleccionada
        body: screens[currentIndex],

        /// Barra de navegación inferior personalizada
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F4FB),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              selectedItemColor: primaryPurple,
              unselectedItemColor: darkPurple.withOpacity(0.7),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
