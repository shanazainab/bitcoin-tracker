import 'dart:async';
import 'package:crypto_tracker/service/background-task.dart';
import 'package:crypto_tracker/view/home-page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ///initialise background service
  initializeService();

  ///configure local notification for android and iOS
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('ic_launcher');

  const IOSInitializationSettings initializationSettingsIOS =
   IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification);

  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bitcoin Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Bitcoin Tracker'),
    );
  }
}
void onDidReceiveLocalNotification(int? id, String? title, String? body, String? payload) async {
  if (payload != null) {
    debugPrint('notification received payload: $payload');

  }
}
void selectNotification(String? payload) async {
  if (payload != null) {
    debugPrint('notification select payload: $payload');
  }
}