# 🚀 Proyecto SMP

Aplicación móvil Flutter para la gestión de grupos, vehículos e inventarios en tiempo real. Incluye chat grupal, seguimiento de ubicación, notificaciones push, fichaje de usuarios y administración avanzada de recursos. Soporta autenticación, subida de fotos, mapas, localización y multilenguaje (español/inglés).

---

## 🛠️ Funcionalidades principales

- **Gestión de usuarios**: Registro, login, roles (admin/usuario), subida de foto de perfil.
- **Grupos**: Creación, edición, asignación de trabajadores y vehículos, chat grupal en tiempo real.
- **Vehículos**: Alta, baja, inventario por vehículo, gestión de fotos y matrículas.
- **Inventarios**: Añadir, editar y eliminar ítems, control visual y edición en línea.
- **Chat grupal**: Mensajería instantánea, notificaciones push, diferenciación de roles.
- **Mapa en tiempo real**: Visualización de trabajadores activos y rutas asignadas.
- **Fichaje y tracking**: Entrada/salida de usuarios, tracking de ubicación solo cuando están fichados.
- **Notificaciones**: Push (FCM) y locales, gestión de tokens y permisos.
- **Soporte multilenguaje**: Español e inglés, fácil de ampliar.
- **Administración avanzada**: Paneles exclusivos para admins, gestión de grupos y usuarios.

---



## ⚙️ Instalación y ejecución

1. **Clona el repositorio:**
   ```sh
   git clone https://github.com/tuusuario/proyecto_smp.git
   cd proyecto_smp
   ```

2. **Instala las dependencias:**
   ```sh
   flutter pub get
   ```

3. **Configura Firebase:**
   - Descarga tu archivo `google-services.json` (Android) y/o `GoogleService-Info.plist` (iOS) desde la consola de Firebase y colócalos en las carpetas correspondientes.
   - Revisa y ajusta `firebase_options.dart` si es necesario.

4. **Ejecuta la app:**
   ```sh
   flutter run
   ```

---

## 🌐 Backend

El servidor backend para notificaciones está disponible en Replit:  
🔗 [Api-Notificaciones-SMP en Replit](https://replit.com/@javierramirez20/Api-Notificaciones-SMP?v=1#index.js)

<div align="center">

<br>

<img src="https://raw.githubusercontent.com/Javimega999/Proyecto_smp/refs/heads/main/Captura%20de%20pantalla%202025-06-09%20211840.png?token=GHSAT0AAAAAADFC7MWKLPGLYFMDHEABRJ7Y2CHHCUA" alt="Pantalla principal" width="1000"/>

</div>

---

## 📦 Estructura del proyecto

```
lib/
 ├── main.dart
 ├── firebase_options.dart
 ├── provider/
 ├── repository/
 ├── screens/
 ├── notis/
 ├── menu/
 ├── services/
 ├── themes/
 ├── translation/
 └── utils/
```

---

## 🧩 Tecnologías y paquetes usados

- **Flutter** y **Dart**
- **Firebase** (Auth, Firestore, Cloud Messaging)
- **Provider** (gestión de estado)
- **Easy Localization** (multilenguaje)
- **Flutter Local Notifications**
- **Geolocator** (ubicación)
- **Image Picker** (fotos)
- **Flutter Map** + **OpenStreetMap** (mapas)
- **Latlong2** (coordenadas)
- **Shared Preferences** (almacenamiento local)
- **http** (peticiones API)
- **flutter_svg**
- **intl**
- **flutter_launcher_icons** y **flutter_native_splash**
- **google_fonts**
- **Servidor backend en Replit** (notificaciones)



---

## 👤 Autor

- **Javier Ramírez Fernández**  
  [GitHub: Javimega999](https://github.com/Javimega999)

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.

---

## ⭐ ¡Contribuciones y feedback bienvenidos!

¿Ideas, bugs o mejoras? ¡Abre un issue o pull request!
