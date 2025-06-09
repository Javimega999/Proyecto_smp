/// Widget de menú emergente (popup) para la barra superior de la app.
/// Permite al usuario cerrar sesión mostrando un diálogo de confirmación.
/// Si el usuario confirma, se cierra la sesión y se redirige a la pantalla de login.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomPopupMenu extends StatelessWidget {
  const CustomPopupMenu({super.key});

  /// Muestra un diálogo de confirmación para cerrar sesión.
  /// Si el usuario acepta, cierra la sesión y navega al login.
  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFF5F4FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'cerrar_sesion_pregunta'.tr(),
              style: const TextStyle(color: Color(0xFF3F3D56)),
            ),
            content: Text(
              'cerrar_sesion_confirmacion'.tr(),
              style: const TextStyle(color: Color(0xFF3F3D56)),
            ),
            actions: [
              TextButton(
                child: Text(
                  'cancelar'.tr(),
                  style: const TextStyle(color: Color(0xFF6C63FF)),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  'cerrar_sesion'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );
    if (salir == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/login');
      }
    }
  }

  /// Construye el menú emergente con la opción de cerrar sesión.
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFFF5F4FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Text(
                    'cerrar_sesion'.tr(),
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
      onSelected: (int item) async {
        if (item == 1) {
          await _confirmarCerrarSesion(context);
        }
      },
    );
  }
}
