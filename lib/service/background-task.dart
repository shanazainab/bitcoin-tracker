import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:crypto_tracker/model/current_price.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../main.dart';

var client = http.Client();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

Future<void> onIosBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('FLUTTER BACKGROUND FETCH');

}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  double? minValue;
  double? maxValue;
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }
    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }
    if (event["action"] == "stopService") {
      minValue = null;
      maxValue = null;
      service.stopBackgroundService();
    }
    if (event["action"] == "limit-set") {
      minValue = event["minValue"].toDouble();
      maxValue = event["maxValue"].toDouble();
    }
    if (event["action"] == "limit-clear") {
      minValue = null;
      maxValue = null;
    }
  });
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    service.setNotificationInfo(
      title: "Bitcoin Tracker Service",
      content: "Updated at ${DateTime.now()}",
    );
    CurrentPriceData? value = await getExchangeRate();

    if (value != null) {
      if (minValue != null && maxValue != null) {
        if (value.bpi.usd.rateFloat < minValue! ||
            value.bpi.usd.rateFloat > maxValue!) {
          if(Platform.isAndroid) {
            const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails('1', 'RATE-ALERT-CHANNEL',
                channelDescription: 'rate alert',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker');
            const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
                android: androidPlatformChannelSpecifics);

            await FlutterLocalNotificationsPlugin().show(
                0,
                'Bitcoin tracker alert!',
                'Current rate is ${value.bpi.usd.rateFloat}',
                platformChannelSpecifics);
          }else{
            service.sendData({
              'action':'notify',
              'value':value.bpi.usd.rateFloat
            });
          }
        }
      }
      service.sendData(
        value.toJson(),
      );
    }
  });
}

Future<CurrentPriceData?> getExchangeRate() async {
  try {
    var response = await client
        .get(Uri.https('api.coindesk.com', 'v1/bpi/currentprice.json'));
    debugPrint(response.body);
    return currentPriceDataFromJson(response.body);
  } catch (e) {
    return null;
  }
}
