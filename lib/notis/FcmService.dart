/// Servicio para gestionar las notificaciones push (FCM) y notificaciones locales.
/// Se encarga de inicializar FCM, mostrar notificaciones locales, guardar el token FCM
/// del usuario en Firestore y escuchar cambios de token para mantenerlo actualizado.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa las notificaciones locales.
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/logo98x98negroyblanco');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Inicializa FCM y define el callback para mensajes en foreground.
  void initFCM({required Function(RemoteMessage) onMessage}) async {
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Muestra una notificación local en el dispositivo.
  Future<void> mostrarNotificacion(String titulo, String mensaje) async {
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
    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      mensaje,
      platformChannelSpecifics,
    );
  }

  /// Guarda el token FCM del usuario en Firestore.
  Future<void> guardarTokenFCM() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(usuario.uid)
            .update({'fcmToken': token});
      }
    }
  }

  /// Escucha cambios de token FCM y actualiza el valor en Firestore.
  void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(usuario.uid)
            .update({'fcmToken': newToken});
      }
    });
  }
}
