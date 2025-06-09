/// Pantalla para gestionar el inventario de un vehículo.
/// Permite añadir, editar, eliminar y marcar como presente cada ítem del inventario.
/// Soporta subida de foto, edición en línea y feedback visual inmediato.
/// El inventario se guarda en Firestore bajo el documento del vehículo.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

// Pantalla para gestionar el inventario de un vehículo
class InventarioVehiculoScreen extends StatefulWidget {
  final String vehiculoId;
  const InventarioVehiculoScreen({super.key, required this.vehiculoId});

  @override
  State<InventarioVehiculoScreen> createState() =>
      _InventarioVehiculoScreenState();
}

class _InventarioVehiculoScreenState extends State<InventarioVehiculoScreen> {
  final Map<String, Map<String, dynamic>> items = {};
  final ImagePicker _picker = ImagePicker();

  // Controladores para el formulario de añadir
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  String? nuevaFotoBase64;

  @override
  void initState() {
    super.initState();
    cargarInventario();
  }

  // Carga el inventario del vehículo desde Firestore
  Future<void> cargarInventario() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('inventarios')
            .doc(widget.vehiculoId)
            .get();
    final data = doc.data() ?? {};
    items.clear();
    data.forEach((key, value) {
      if (key == 'vehiculoId') return; // Ignora el campo vehiculoId
      items[key] = {
        'nombre': value['nombre'] ?? '',
        'cantidad': value['cantidad'] ?? 1,
        'foto': value['foto'] ?? '',
        'presente': value['presente'] ?? false,
      };
    });
    setState(() {});
  }

  // Guarda el inventario actualizado en Firestore
  Future<void> guardarInventario() async {
    final data = <String, dynamic>{};
    items.forEach((key, value) {
      data[key] = {
        'nombre': value['nombre'],
        'cantidad': value['cantidad'],
        'foto': value['foto'],
        'presente': value['presente'],
      };
    });
    data['vehiculoId'] = widget.vehiculoId;
    await FirebaseFirestore.instance
        .collection('inventarios')
        .doc(widget.vehiculoId)
        .set(data);
  }

  // Selecciona imagen para un nuevo ítem
  Future<void> pickImageForNew() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        nuevaFotoBase64 = base64Encode(bytes);
      });
    }
  }

  // Selecciona imagen para editar un ítem
  Future<void> pickImageForEdit(TextEditingController fotoController) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      fotoController.text = base64Encode(bytes);
      setState(() {});
    }
  }

  // Selecciona imagen para un ítem existente
  Future<void> pickImageForItem(String key) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        items[key]!['foto'] = base64Encode(bytes);
      });
      guardarInventario();
    }
  }

  // Agrega un nuevo ítem al inventario
  void agregarItem() {
    final nombre = nombreController.text.trim();
    final cantidad = int.tryParse(cantidadController.text.trim()) ?? 1;
    if (nombre.isEmpty) return;
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    items[key] = {
      'nombre': nombre,
      'cantidad': cantidad,
      'foto': nuevaFotoBase64 ?? '',
      'presente': false,
    };
    nombreController.clear();
    cantidadController.clear();
    nuevaFotoBase64 = null;
    setState(() {});
    guardarInventario();
  }

  // Diálogo para editar un ítem existente
  void editarItemDialog(String key) {
    final item = items[key]!;
    final editNombre = TextEditingController(text: item['nombre']);
    final editCantidad = TextEditingController(
      text: item['cantidad'].toString(),
    );
    final editFoto = TextEditingController(text: item['foto']);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('editar_item'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await pickImageForEdit(editFoto);
                    setState(() {});
                  },
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        editFoto.text.isNotEmpty
                            ? MemoryImage(base64Decode(editFoto.text))
                            : const AssetImage(
                                  "assets/images/default_profile.png",
                                )
                                as ImageProvider,
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.13),
                    child:
                        editFoto.text.isEmpty
                            ? const Icon(
                              Icons.add_a_photo,
                              size: 28,
                              color: Colors.white70,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editNombre,
                  decoration: InputDecoration(labelText: 'nombre'.tr()),
                ),
                TextField(
                  controller: editCantidad,
                  decoration: InputDecoration(labelText: 'cantidad'.tr()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('cancelar'.tr()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('guardar'.tr()),
                onPressed: () {
                  setState(() {
                    item['nombre'] = editNombre.text.trim();
                    item['cantidad'] =
                        int.tryParse(editCantidad.text.trim()) ?? 1;
                    item['foto'] = editFoto.text;
                  });
                  guardarInventario();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
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
            'inventario_vehiculo'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryPurple,
          icon: const Icon(Icons.add),
          label: Text('anadir_item'.tr()),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              builder:
                  (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      left: 16,
                      right: 16,
                      top: 24,
                    ),
                    child: Wrap(
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: pickImageForNew,
                            child: CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  nuevaFotoBase64 != null
                                      ? MemoryImage(
                                        base64Decode(nuevaFotoBase64!),
                                      )
                                      : const AssetImage(
                                            "assets/images/default_profile.png",
                                          )
                                          as ImageProvider,
                              backgroundColor: primaryPurple.withOpacity(0.13),
                              child:
                                  nuevaFotoBase64 == null
                                      ? const Icon(
                                        Icons.add_a_photo,
                                        size: 28,
                                        color: Colors.white70,
                                      )
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(labelText: 'nombre'.tr()),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: cantidadController,
                          decoration: InputDecoration(
                            labelText: 'cantidad'.tr(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text('anadir'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              agregarItem();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            );
          },
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...items.entries.map((entry) {
                    final key = entry.key;
                    final item = entry.value;
                    final fotoBase64 = item['foto'];
                    ImageProvider foto;
                    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                      try {
                        foto = MemoryImage(base64Decode(fotoBase64));
                      } catch (_) {
                        foto = const AssetImage(
                          "assets/images/default_profile.png",
                        );
                      }
                    } else {
                      foto = const AssetImage(
                        "assets/images/default_profile.png",
                      );
                    }
                    return Card(
                      color: lightBg.withOpacity(0.96),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            await pickImageForItem(key);
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: primaryPurple.withOpacity(0.13),
                            child:
                                (fotoBase64 != null && fotoBase64.isNotEmpty)
                                    ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(fotoBase64),
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.add_a_photo,
                                      size: 18,
                                      color: Colors.white70,
                                    ),
                          ),
                        ),
                        title: Text(
                          item['nombre'],
                          style: TextStyle(
                            color: darkPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${"cantidad".tr()}: "),
                            Text(
                              item['cantidad'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () => editarItemDialog(key),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  items.remove(key);
                                });
                                guardarInventario();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
