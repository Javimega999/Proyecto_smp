/// AppBar global reutilizable para todas las pantallas del proyecto.
/// Permite mostrar un título, un botón para alternar entre vista admin/usuario (si es admin)
/// y un botón para cerrar sesión (si se proporciona el callback).
library;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// AppBar global reutilizable para todas las pantallas del proyecto
class AppBarGlobal extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Título de la appbar
  final bool isAdmin; // ¿El usuario es admin?
  final bool adminView; // ¿Está en modo admin la vista?
  final VoidCallback?
  onToggleAdminView; // Acción para cambiar de vista admin/usuario
  final VoidCallback? onLogout; // Acción para cerrar sesión

  const AppBarGlobal({
    super.key,
    this.title,
    this.isAdmin = false,
    this.adminView = false,
    this.onToggleAdminView,
    this.onLogout,
  });

  /// Construye la AppBar con título, botón de cambio de vista y botón de logout.
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Título traducido y estilizado
      title: Text(
        title?.tr() ?? "",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          fontSize: 28,
        ),
      ),
      actions: [
        // Botón para cambiar entre vista admin y usuario (solo si es admin y hay callback)
        if (isAdmin && onToggleAdminView != null)
          IconButton(
            icon: Icon(
              adminView ? Icons.visibility : Icons.admin_panel_settings,
              color: Colors.white,
            ),
            tooltip: adminView ? 'vista_usuario'.tr() : 'vista_admin'.tr(),
            onPressed: onToggleAdminView,
          ),
        // Botón para cerrar sesión (si hay callback)
        if (onLogout != null)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'cerrar_sesion'.tr(),
            onPressed: onLogout,
          ),
      ],
    );
  }

  /// Altura estándar de la AppBar.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
