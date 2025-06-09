/// Pantalla principal de gestión de vehículos (crear y eliminar).
/// Permite registrar nuevos vehículos con foto, nombre y matrícula, y eliminar vehículos existentes.
/// Incluye pestañas para crear y eliminar, subida de foto y feedback visual.
library;

import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

// Pantalla principal de gestión de vehículos (crear y eliminar)
class VehiculoApp extends StatefulWidget {
  const VehiculoApp({super.key});

  @override
  _VehiculoAppState createState() => _VehiculoAppState();
}

class _VehiculoAppState extends State<VehiculoApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        title: Text(
          'gestion_vehiculos'.tr(),
          style: const TextStyle(
            color: Color(0xFF3F3D56),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: Color(0xFF6C63FF)),
                insets: EdgeInsets.symmetric(horizontal: 36),
              ),
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  text: 'crear_vehiculo'.tr(),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Tab(
                  text: 'eliminar_vehiculo'.tr(),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [CrearVehiculoScreen(), EliminarVehiculoTab()],
      ),
    );
  }
}

// Pestaña para crear un vehículo nuevo
class CrearVehiculoScreen extends StatefulWidget {
  const CrearVehiculoScreen({super.key});

  @override
  State<CrearVehiculoScreen> createState() => _CrearVehiculoScreenState();
}

class _CrearVehiculoScreenState extends State<CrearVehiculoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController matriculaController = TextEditingController();
  String? _photoBase64;
  bool isSaving = false;

  late TabController _tabController;
  final TextEditingController _matriculaEliminarController =
      TextEditingController();
  bool _isDeleting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nombreController.dispose();
    matriculaController.dispose();
    _matriculaEliminarController.dispose();
    super.dispose();
  }

  // Selecciona una imagen de la galería y la convierte a base64
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  // Crea un vehículo en Firestore
  Future<void> crearVehiculo() async {
    if (nombreController.text.isEmpty || matriculaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('todos_los_campos_obligatorios'.tr())),
      );
      return;
    }
    setState(() => isSaving = true);
    await FirebaseFirestore.instance.collection('vehiculos').add({
      'nombre': nombreController.text.trim(),
      'matricula': matriculaController.text.trim(),
      'foto': _photoBase64 ?? '',
    });
    setState(() => isSaving = false);
    nombreController.clear();
    matriculaController.clear();
    setState(() {
      _photoBase64 = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('vehiculo_creado'.tr())));
  }

  // Elimina un vehículo por matrícula
  Future<void> _eliminarVehiculoPorMatricula() async {
    final matricula = _matriculaEliminarController.text.trim();
    if (matricula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('introduce_matricula_eliminar'.tr())),
      );
      return;
    }
    setState(() => _isDeleting = true);
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('vehiculos')
              .where('matricula', isEqualTo: matricula)
              .get();
      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('vehiculo_no_encontrado'.tr())));
      } else {
        final id = query.docs.first.id;
        await FirebaseFirestore.instance
            .collection('vehiculos')
            .doc(id)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('vehiculo_eliminado'.tr())));
        _matriculaEliminarController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_eliminar_vehiculo'.tr(args: ['$e']))),
      );
    }
    setState(() => _isDeleting = false);
  }

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
            'vehiculos'.tr(),
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
              Tab(
                icon: const Icon(Icons.add_circle_outline),
                text: "crear".tr(),
              ),
              Tab(
                icon: const Icon(Icons.delete_outline),
                text: "eliminar".tr(),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pestaña Crear Vehículo
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
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'nombre_vehiculo'.tr(),
                        prefixIcon: const Icon(
                          Icons.directions_car,
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
                      controller: matriculaController,
                      decoration: InputDecoration(
                        labelText: 'matricula'.tr(),
                        prefixIcon: const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF6C63FF),
                        ),
                        filled: true,
                        fillColor: lightBg.withOpacity(0.95),
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
                        icon: const Icon(Icons.add, color: Colors.white),
                        label:
                            isSaving
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'crear_vehiculo'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        onPressed: isSaving ? null : crearVehiculo,
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
            // Pestaña Eliminar Vehículo
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
                        'eliminar_vehiculo'.tr(),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'eliminar_vehiculo_irreversible'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _matriculaEliminarController,
                        decoration: InputDecoration(
                          labelText: 'matricula_vehiculo_eliminar'.tr(),
                          prefixIcon: const Icon(
                            Icons.confirmation_number,
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
                          label:
                              _isDeleting
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'eliminar_vehiculo'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      fontSize: 17,
                                    ),
                                  ),
                          onPressed:
                              _isDeleting
                                  ? null
                                  : _eliminarVehiculoPorMatricula,
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

// Pestaña para eliminar vehículos desde una lista
class EliminarVehiculoTab extends StatefulWidget {
  const EliminarVehiculoTab({super.key});

  @override
  State<EliminarVehiculoTab> createState() => _EliminarVehiculoTabState();
}

class _EliminarVehiculoTabState extends State<EliminarVehiculoTab> {
  bool _isDeleting = false;
  String? _vehiculoEliminandoId;

  // Elimina un vehículo por su ID de documento
  Future<void> _eliminarVehiculo(String docId) async {
    setState(() {
      _isDeleting = true;
      _vehiculoEliminandoId = docId;
    });
    try {
      await FirebaseFirestore.instance
          .collection('vehiculos')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('vehiculo_eliminado'.tr())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_eliminar_vehiculo'.tr(args: ['$e']))),
      );
    }
    setState(() {
      _isDeleting = false;
      _vehiculoEliminandoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6C63FF);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vehiculos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('no_hay_vehiculos_registrados'.tr()));
          }
          final vehiculos = snapshot.data!.docs;
          return ListView.separated(
            itemCount: vehiculos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vehiculo = vehiculos[index];
              final nombre = vehiculo['nombre'] ?? '';
              final matricula = vehiculo['matricula'] ?? '';
              final fotoBase64 = vehiculo['foto'] ?? '';
              ImageProvider? foto;
              if (fotoBase64.isNotEmpty) {
                foto = MemoryImage(base64Decode(fotoBase64));
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      foto ??
                      const AssetImage("assets/images/default_profile.png"),
                  backgroundColor: primaryPurple.withOpacity(0.15),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${'matricula'.tr()}: $matricula'),
                trailing:
                    _isDeleting && _vehiculoEliminandoId == vehiculo.id
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: Text(
                                      'eliminar_vehiculo_pregunta'.tr(),
                                    ),
                                    content: Text(
                                      'eliminar_vehiculo_confirmacion'.tr(
                                        args: [nombre],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: Text('cancelar'.tr()),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                        child: Text(
                                          'eliminar'.tr(),
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              _eliminarVehiculo(vehiculo.id);
                            }
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
