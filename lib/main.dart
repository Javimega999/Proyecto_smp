/// Punto de entrada principal de la app.
/// Inicializa Firebase, notificaciones, orientación, localización y el provider global.
/// Gestiona el token FCM y muestra la SplashScreen al iniciar.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_smp/firebase_options.dart';
import 'package:proyecto_smp/provider/login_provider.dart';
import 'package:proyecto_smp/screens/user/screens/LoginScreen.dart';
import 'package:proyecto_smp/utils/Costantes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_smp/SplashScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final tipo = data['tipo'] ?? '';
  final grupo = data['grupo'] ?? '';
  final nombre = data['nombre'] ?? '';
  final texto = data['mensaje'] ?? '';

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Mensajes de grupo',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  if (tipo == 'nuevo_grupo' && grupo.isNotEmpty) {
    await flutterLocalNotificationsPlugin.show(
      0,
      '¡Has sido incluido en un grupo!',
      'Has sido incluido en el grupo $grupo',
      platformChannelSpecifics,
    );
  } else if (nombre.isNotEmpty && texto.isNotEmpty && grupo.isNotEmpty) {
    await flutterLocalNotificationsPlugin.show(
      0,
      'Nuevo mensaje en $grupo',
      '$nombre: $texto',
      platformChannelSpecifics,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Guarda el token FCM al iniciar
  final fcm = FirebaseMessaging.instance;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token},
      );
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale("es"), Locale("en")],
      path: "lib/translation",
      fallbackLocale: const Locale("es"),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => LoginProvider(),
      child: MaterialApp(
        title: 'SMP',
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: const SplashScreen(),
        routes: {'/login': (context) => LoginScreen()},
      ),
    );
  }
}

Future<String> getUsername() async {
  final prefs = await SharedPreferences.getInstance();
  String emailPref = prefs.getString(Constantes.EMAIL) ?? "";
  return emailPref;
}
