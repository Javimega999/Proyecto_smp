/// Pantalla para gestionar grupos.
/// Permite crear, editar, asignar trabajadores, asignar vehículo, editar dirección y eliminar grupos.
/// Solo accesible para administradores. Incluye edición en línea y gestión visual de los grupos.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

/// Pantalla para gestionar grupos: crear, editar, asignar trabajadores y eliminar
class GestionGruposScreen extends StatefulWidget {
  const GestionGruposScreen({super.key});

  @override
  State<GestionGruposScreen> createState() => _GestionGruposScreenState();
}

class _GestionGruposScreenState extends State<GestionGruposScreen> {
  final Map<String, TextEditingController> _rutaControllers =
      {}; // Controladores para las rutas de cada grupo
  final Map<String, TextEditingController> _nombreControllers =
      {}; // Controladores para los nombres de cada grupo
  String? selectedGroupId; // Grupo seleccionado para editar

  /// Libera los controladores al cerrar la pantalla.
  @override
  void dispose() {
    // Liberamos los controladores al cerrar la pantalla
    for (final c in _rutaControllers.values) {
      c.dispose();
    }
    for (final c in _nombreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Diálogo para crear un nuevo grupo.
  Future<void> _crearGrupoDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFF5F4FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'crear_nuevo_grupo'.tr(),
              style: const TextStyle(color: Color(0xFF3F3D56)),
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'nombre_del_grupo'.tr()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancelar'.tr(),
                  style: const TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final nombre = controller.text.trim();
                  if (nombre.isNotEmpty) {
                    Navigator.pop(context, nombre);
                  }
                },
                child: Text(
                  'crear'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    if (result != null && result.isNotEmpty) {
      await FirebaseFirestore.instance.collection('grupos').add({
        'nombre': result,
        'ruta': '',
        'vehiculoId': null,
        'trabajadores': [],
      });
      setState(() {});
    }
  }

  /// Elimina un grupo y limpia referencias en usuarios y mensajes.
  Future<void> _eliminarGrupo(String grupoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('eliminar_grupo'.tr()),
            content: Text('confirmar_eliminar_grupo'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancelar'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'eliminar'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      // 1. Eliminar todos los mensajes del chat del grupo
      final chatSnap =
          await FirebaseFirestore.instance
              .collection('grupos')
              .doc(grupoId)
              .collection('chat')
              .get();
      for (var doc in chatSnap.docs) {
        await doc.reference.delete();
      }

      // 2. Obtener el array de trabajadores del grupo
      final grupoDoc =
          await FirebaseFirestore.instance
              .collection('grupos')
              .doc(grupoId)
              .get();
      final trabajadores = List<String>.from(
        grupoDoc.data()?['trabajadores'] ?? [],
      );

      // 3. Poner grupoId y grupoNombre en "" a los usuarios asignados a este grupo
      for (var userId in trabajadores) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'grupoId': "", 'grupoNombre': ""},
        );
      }

      // 4. Eliminar el grupo
      await FirebaseFirestore.instance
          .collection('grupos')
          .doc(grupoId)
          .delete();

      setState(() {
        selectedGroupId = null;
      });
    }
  }

  /// Construye la interfaz de la pantalla de gestión de grupos.
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('grupos').snapshots(),
          builder: (context, grupoSnap) {
            // Loader solo en la carga inicial
            if (grupoSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!grupoSnap.hasData || grupoSnap.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'no_hay_grupos_creados'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              );
            }
            final grupos = grupoSnap.data!.docs;
            return ListView.builder(
              itemCount: grupos.length,
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                final grupoId = grupo.id;
                final data = grupo.data() as Map<String, dynamic>;
                final rutaActual = data['ruta'] ?? '';
                final nombreActual = data['nombre'] ?? '';
                final trabajadoresActuales = List<String>.from(
                  data['trabajadores'] ?? [],
                );
                final vehiculoIdActual = data['vehiculoId'];

                _rutaControllers.putIfAbsent(
                  grupoId,
                  () => TextEditingController(text: rutaActual),
                );
                _nombreControllers.putIfAbsent(
                  grupoId,
                  () => TextEditingController(text: nombreActual),
                );

                final isSelected = selectedGroupId == grupoId;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? lightBg.withOpacity(0.98)
                            : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        selectedGroupId = isSelected ? null : grupoId;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          isSelected
                              ? Padding(
                                key: ValueKey('edit_$grupoId'),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Editar nombre del grupo
                                    TextField(
                                      controller: _nombreControllers[grupoId],
                                      decoration: InputDecoration(
                                        labelText: 'nombre_del_grupo'.tr(),
                                        prefixIcon: const Icon(Icons.edit),
                                      ),
                                      onSubmitted: (value) async {
                                        await FirebaseFirestore.instance
                                            .collection('grupos')
                                            .doc(grupoId)
                                            .update({'nombre': value});
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Selección de vehículo
                                    FutureBuilder<QuerySnapshot>(
                                      future:
                                          FirebaseFirestore.instance
                                              .collection('vehiculos')
                                              .get(),
                                      builder: (context, vehiculoSnap) {
                                        if (vehiculoSnap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const SizedBox(
                                            height: 32,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        }
                                        if (!vehiculoSnap.hasData) {
                                          return const SizedBox();
                                        }
                                        final vehiculos =
                                            vehiculoSnap.data!.docs;
                                        final vehiculoIds =
                                            vehiculos.map((v) => v.id).toList();
                                        final value =
                                            vehiculoIds.contains(
                                                  vehiculoIdActual,
                                                )
                                                ? vehiculoIdActual
                                                : null;

                                        return DropdownButton<String>(
                                          value: value,
                                          hint: Text(
                                            'selecciona_vehiculo'.tr(),
                                          ),
                                          items:
                                              vehiculos
                                                  .map(
                                                    (v) => DropdownMenuItem(
                                                      value: v.id,
                                                      child: Text(
                                                        '${v['nombre']} - ${v['matricula']}',
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) async {
                                            await FirebaseFirestore.instance
                                                .collection('grupos')
                                                .doc(grupoId)
                                                .update({'vehiculoId': value});
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Selección de trabajadores
                                    FutureBuilder<QuerySnapshot>(
                                      future:
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .where(
                                                'isAdmin',
                                                isEqualTo: false,
                                              )
                                              .where(
                                                'hasCheckedIn',
                                                isEqualTo: true,
                                              )
                                              .get(),
                                      builder: (context, userSnap) {
                                        if (userSnap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const SizedBox(
                                            height: 32,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        }
                                        if (!userSnap.hasData) {
                                          return const SizedBox();
                                        }
                                        final users = userSnap.data!.docs;
                                        final disponibles =
                                            users.where((user) {
                                              final data =
                                                  user.data()
                                                      as Map<String, dynamic>;
                                              final grupoIdUsuario =
                                                  data['grupoId'];
                                              return (grupoIdUsuario == null ||
                                                      grupoIdUsuario
                                                          .toString()
                                                          .isEmpty) &&
                                                  !trabajadoresActuales
                                                      .contains(user.id);
                                            }).toList();
                                        String? trabajadorSeleccionado;

                                        return StatefulBuilder(
                                          builder:
                                              (
                                                context,
                                                setStateDialog,
                                              ) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'anadir_trabajador'.tr(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF3F3D56),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: DropdownButton<
                                                          String
                                                        >(
                                                          value:
                                                              trabajadorSeleccionado,
                                                          hint: Text(
                                                            'selecciona_trabajador'
                                                                .tr(),
                                                          ),
                                                          items:
                                                              disponibles.map((
                                                                user,
                                                              ) {
                                                                final nombre =
                                                                    user['displayName'] ??
                                                                    user['email'] ??
                                                                    'sin_nombre'
                                                                        .tr();
                                                                return DropdownMenuItem(
                                                                  value:
                                                                      user.id,
                                                                  child: Text(
                                                                    nombre,
                                                                  ),
                                                                );
                                                              }).toList(),
                                                          onChanged: (value) {
                                                            setStateDialog(() {
                                                              trabajadorSeleccionado =
                                                                  value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      ElevatedButton.icon(
                                                        icon: const Icon(
                                                          Icons.person_add,
                                                          color: Colors.white,
                                                        ),
                                                        label: Text(
                                                          'anadir'.tr(),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                letterSpacing:
                                                                    1.1,
                                                              ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              primaryPurple,
                                                          elevation: 4,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 18,
                                                                vertical: 12,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  14,
                                                                ),
                                                          ),
                                                          shadowColor:
                                                              primaryPurple
                                                                  .withOpacity(
                                                                    0.25,
                                                                  ),
                                                        ),
                                                        onPressed:
                                                            trabajadorSeleccionado ==
                                                                    null
                                                                ? null
                                                                : () async {
                                                                  final nuevosTrabajadores =
                                                                      List<
                                                                        String
                                                                      >.from(
                                                                        trabajadoresActuales,
                                                                      );
                                                                  nuevosTrabajadores
                                                                      .add(
                                                                        trabajadorSeleccionado!,
                                                                      );
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                        'grupos',
                                                                      )
                                                                      .doc(
                                                                        grupoId,
                                                                      )
                                                                      .update({
                                                                        'trabajadores':
                                                                            nuevosTrabajadores,
                                                                      });
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                        'users',
                                                                      )
                                                                      .doc(
                                                                        trabajadorSeleccionado!,
                                                                      )
                                                                      .update({
                                                                        'grupoId':
                                                                            grupoId,
                                                                      });
                                                                  if (context
                                                                      .mounted) {
                                                                    setStateDialog(
                                                                      () {
                                                                        trabajadorSeleccionado =
                                                                            null;
                                                                      },
                                                                    );
                                                                  }
                                                                },
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'trabajadores_en_el_grupo'
                                                        .tr(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF3F3D56),
                                                    ),
                                                  ),
                                                  ...users
                                                      .where(
                                                        (user) =>
                                                            trabajadoresActuales
                                                                .contains(
                                                                  user.id,
                                                                ),
                                                      )
                                                      .map((user) {
                                                        final nombre =
                                                            user['displayName'] ??
                                                            user['email'] ??
                                                            'sin_nombre'.tr();
                                                        return ListTile(
                                                          title: Text(nombre),
                                                          trailing: IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .remove_circle,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed: () async {
                                                              final nuevosTrabajadores =
                                                                  List<
                                                                    String
                                                                  >.from(
                                                                    trabajadoresActuales,
                                                                  );
                                                              nuevosTrabajadores
                                                                  .remove(
                                                                    user.id,
                                                                  );
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                    'grupos',
                                                                  )
                                                                  .doc(grupoId)
                                                                  .update({
                                                                    'trabajadores':
                                                                        nuevosTrabajadores,
                                                                  });
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                    'users',
                                                                  )
                                                                  .doc(user.id)
                                                                  .update({
                                                                    'grupoId':
                                                                        "",
                                                                  });
                                                              if (context
                                                                  .mounted) {
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      }),
                                                ],
                                              ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Editar ruta del grupo
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                _rutaControllers[grupoId],
                                            decoration: InputDecoration(
                                              labelText:
                                                  'direccion_del_grupo'.tr(),
                                              prefixIcon: const Icon(
                                                Icons.location_on,
                                              ),
                                            ),
                                            onSubmitted: (value) async {
                                              await FirebaseFirestore.instance
                                                  .collection('grupos')
                                                  .doc(grupoId)
                                                  .update({'ruta': value});
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'guardar_direccion'.tr(),
                                          onPressed: () async {
                                            final value =
                                                _rutaControllers[grupoId]?.text
                                                    .trim() ??
                                                '';
                                            await FirebaseFirestore.instance
                                                .collection('grupos')
                                                .doc(grupoId)
                                                .update({'ruta': value});
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.close),
                                          label: Text('cerrar'.tr()),
                                          onPressed: () {
                                            setState(() {
                                              selectedGroupId = null;
                                            });
                                          },
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          label: Text(
                                            'eliminar'.tr(),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                          onPressed:
                                              () => _eliminarGrupo(grupoId),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                              : ListTile(
                                key: ValueKey('list_$grupoId'),
                                title: Text(
                                  nombreActual,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkPurple,
                                  ),
                                ),
                                subtitle: Text(
                                  '${'ruta'.tr()}: $rutaActual',
                                  style: TextStyle(
                                    color: darkPurple.withOpacity(0.7),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'crear_grupo'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          onPressed: _crearGrupoDialog,
        ),
      ),
    );
  }
}
