/// Pantalla para crear y eliminar usuarios (solo para administradores).
/// Permite registrar nuevos usuarios (con foto, nombre, correo, contraseña y rol admin/no admin)
/// y eliminar usuarios existentes por correo electrónico. Incluye pestañas para crear y eliminar,
/// subida de foto de perfil y gestión de roles.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nombreController =
      TextEditingController(); // Controlador para el nombre
  final TextEditingController _correoController =
      TextEditingController(); // Controlador para el correo
  final TextEditingController _passwordController =
      TextEditingController(); // Controlador para la contraseña
  String? _photoBase64; // Foto de perfil en base64
  bool _isSaving = false; // ¿Está guardando el usuario?
  bool _isAdmin = false; // ¿El usuario es admin?

  late TabController _tabController; // Controlador de pestañas
  final TextEditingController _correoEliminarController =
      TextEditingController(); // Controlador para eliminar usuario
  bool _isDeleting = false; // ¿Está eliminando el usuario?

  /// Inicializa el controlador de pestañas.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Dos pestañas: crear y eliminar
  }

  /// Libera los controladores al destruir el widget.
  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _correoEliminarController.dispose();
    super.dispose();
  }

  /// Selecciona una imagen de la galería y la convierte a base64.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  /// Crea un usuario nuevo en Firebase Auth y Firestore.
  Future<void> _crearUsuario() async {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || correo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('todos_los_campos_obligatorios'.tr())),
      );
      return;
    }
    setState(() => _isSaving = true);

    // Guarda el usuario y contraseña del admin actual
    final adminUser = FirebaseAuth.instance.currentUser;
    final adminEmail = adminUser?.email;

    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: password);

      final uid = userCredential.user!.uid;

      // Guardar datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': nombre,
        'photoBase64': _photoBase64,
        'hasCheckedIn': false,
        'email': correo,
        'isAdmin': _isAdmin,
      });

      // Volver a iniciar sesión como admin
      if (adminEmail != null) {
        final adminPassword = await _pedirPasswordAdmin(context);
        if (adminPassword != null) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('usuario_creado_correctamente'.tr())),
      );
      _nombreController.clear();
      _correoController.clear();
      _passwordController.clear();
      setState(() {
        _photoBase64 = null;
        _isSaving = false;
        _isAdmin = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isSaving = false);
      String msg = 'error_al_crear_usuario'.tr();
      if (e.code == 'email-already-in-use') {
        msg = 'correo_ya_en_uso'.tr();
      } else if (e.code == 'invalid-email') {
        msg = 'correo_invalido'.tr();
      } else if (e.code == 'weak-password') {
        msg = 'contrasena_debil'.tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generico'.tr(args: ['$e']))),
      );
    }
  }

  /// Pide la contraseña del admin actual mediante un diálogo.
  Future<String?> _pedirPasswordAdmin(BuildContext context) async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Introduce tu contraseña de admin'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Contraseña'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = controller.text;
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
    return password;
  }

  /// Elimina un usuario de Firestore por su correo electrónico.
  Future<void> _eliminarUsuarioPorCorreo() async {
    final correo = _correoEliminarController.text.trim();
    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('introduce_correo_usuario_eliminar'.tr())),
      );
      return;
    }
    setState(() => _isDeleting = true);
    try {
      // Buscar usuario por correo en Firestore
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: correo)
              .get();
      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('usuario_no_encontrado'.tr())));
      } else {
        final uid = query.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('usuario_eliminado_firestore'.tr())),
        );
        _correoEliminarController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_eliminar_usuario'.tr(args: ['$e']))),
      );
    }
    setState(() => _isDeleting = false);
  }

  /// Construye la interfaz de la pantalla con pestañas para crear y eliminar usuarios.
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
            'usuarios'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.person_add), text: "crear".tr()),
              Tab(icon: const Icon(Icons.delete), text: "eliminar".tr()),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pestaña Crear Usuario
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _photoBase64 != null
                                ? MemoryImage(base64Decode(_photoBase64!))
                                : const AssetImage(
                                      "assets/images/default_profile.png",
                                    )
                                    as ImageProvider,
                        backgroundColor: primaryPurple.withOpacity(0.15),
                        child:
                            _photoBase64 == null
                                ? const Icon(
                                  Icons.add_a_photo,
                                  size: 36,
                                  color: Colors.white70,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'nombre'.tr(),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF6C63FF),
                        ),
                        filled: true,
                        fillColor: lightBg.withOpacity(0.95),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'correo_electronico'.tr(),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF6C63FF),
                        ),
                        filled: true,
                        fillColor: lightBg.withOpacity(0.95),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'contrasena'.tr(),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF6C63FF),
                        ),
                        filled: true,
                        fillColor: lightBg.withOpacity(0.95),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6C63FF).withOpacity(0.95),
                            Color(0xFF3F3D56).withOpacity(0.95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 34,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              'es_administrador'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 4,
                                    offset: const Offset(1, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Switch(
                            value: _isAdmin,
                            activeColor: Colors.white,
                            activeTrackColor: Color(0xFF6C63FF),
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: Colors.white24,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (value) {
                              setState(() {
                                _isAdmin = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    key: ValueKey('saving'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'crear_usuario'.tr(),
                                    key: const ValueKey('text'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                        ),
                        onPressed: _isSaving ? null : _crearUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: primaryPurple.withOpacity(0.18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pestaña Eliminar Usuario
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'eliminar_usuario'.tr(),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'eliminar_usuario_irreversible'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _correoEliminarController,
                        decoration: InputDecoration(
                          labelText: 'correo_usuario_eliminar'.tr(),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF6C63FF),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child:
                                _isDeleting
                                    ? const SizedBox(
                                      key: ValueKey('deleting'),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      'eliminar_usuario'.tr(),
                                      key: const ValueKey('text'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                        fontSize: 17,
                                      ),
                                    ),
                          ),
                          onPressed:
                              _isDeleting ? null : _eliminarUsuarioPorCorreo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: Colors.red.withOpacity(0.18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
