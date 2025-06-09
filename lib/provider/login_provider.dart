/// Provider para la gestión del login y el usuario actual.
/// Se encarga de autenticar al usuario, guardar su email en preferencias,
/// y exponer el usuario autenticado a la app.
library;

import 'package:flutter/material.dart';
import 'package:proyecto_smp/repository/login_repository.dart';
import 'package:proyecto_smp/utils/Costantes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  final LoginRepository _repository = LoginRepository();

  /// Verifica las credenciales del usuario llamando al repositorio.
  Future<bool> checkCredentials(String email, String password) async {
    notifyListeners();
    return await _repository.login(email, password) == true;
  }

  /// Guarda el email del usuario en las preferencias compartidas.
  void saveData(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constantes.EMAIL);
    await prefs.setString(Constantes.EMAIL, email);
    await prefs.setBool(Constantes.CACHE, false);
    String? prueba = prefs.getString(Constantes.EMAIL);
    debugPrint("Email de prefs: $prueba");
    notifyListeners();
  }

  /// Devuelve el usuario autenticado actual.
  User? get user => _repository.user;
}
