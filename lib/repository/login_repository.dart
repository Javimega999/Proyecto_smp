/// Repositorio para manejar el login y el usuario actual.
/// Implementa el patrón singleton para que solo exista una instancia.
/// Permite autenticar al usuario con email y contraseña y expone el usuario autenticado.
library;

import 'package:firebase_auth/firebase_auth.dart';

// Repositorio para manejar el login y el usuario actual
class LoginRepository {
  static LoginRepository? _instance; // Instancia singleton
  User? _user; // Usuario autenticado actualmente

  // Constructor privado para el singleton
  LoginRepository._internal();

  /// Devuelve la instancia singleton del repositorio.
  factory LoginRepository() {
    _instance ??= LoginRepository._internal();
    return _instance!;
  }

  /// Getter para obtener el usuario actual.
  User? get user => _user;

  /// Método para hacer login con email y contraseña.
  /// Devuelve true si el login es exitoso, false si falla.
  Future<bool> login(String email, String pass) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      _user = credential.user; // Guardamos el usuario autenticado
      print("Conseguido");
      return true; // Login exitoso
    } catch (e) {
      print("Error en login: $e");
      return false; // Error en login
    }
  }
}
