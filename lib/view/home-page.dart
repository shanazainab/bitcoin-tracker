import 'dart:convert';

import 'package:crypto_tracker/model/current_price.dart';
import 'package:crypto_tracker/service/background-task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController minTextEditingController = TextEditingController();
  TextEditingController maxTextEditingController = TextEditingController();

  String alertStatus = "SET ALERT";
  String serviceStatus = "STOP SERVICE";

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
    FlutterBackgroundService().onDataReceived.listen((event) async {
      if (event!['action'] == 'notify') {
        const IOSNotificationDetails iosNotificationDetails =
            IOSNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                threadIdentifier: 'RATE-ALERT-CHANNEL',
                badgeNumber: 101);
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(iOS: iosNotificationDetails);

        await FlutterLocalNotificationsPlugin().show(
          0,
          'Bitcoin tracker alert!',
          'Current rate is ${event!['value']}',
          platformChannelSpecifics,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(widget.title),
          actions: [
            TextButton(
                onPressed: () async {
                  var isRunning =
                      await FlutterBackgroundService().isServiceRunning();
                  if (isRunning) {
                    serviceStatus = 'START SERVICE';

                    FlutterBackgroundService().sendData(
                      {"action": "stopService"},
                    );
                  } else {
                    serviceStatus = 'STOP SERVICE';
                    FlutterBackgroundService().start();
                  }
                  setState(() {});
                },
                child: Text(
                  serviceStatus,
                  style: const TextStyle(color: Colors.white),
                ))
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<Map<String, dynamic>?>(
                stream: FlutterBackgroundService().onDataReceived,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    CurrentPriceData currentPriceData =
                        CurrentPriceData.fromJson(snapshot.data!);
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentPriceData.bpi.usd.code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 16),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              currentPriceData.bpi.usd.rate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 36),
                            ),
                          ],
                        ),
                        Text(
                          "Updated at : ${DateFormat('dd MMM yyyy hh:mm:ss a').format(currentPriceData.time.updatedIso.toLocal())}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 13),
                        ),
                      ],
                    );
                  }
                  return const Center(
                    child: SpinKitThreeBounce(
                      color: Colors.blue,
                      size: 20.0,
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a value';
                        } else {
                          return null;
                        }
                      },
                      controller: minTextEditingController,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey[400]!, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey[400]!, width: 1.0),
                        ),
                        hintText: 'Min limit',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a value';
                        } else {
                          return null;
                        }
                      },
                      controller: maxTextEditingController,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey[400]!, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey[400]!, width: 1.0),
                        ),
                        hintText: 'Max limit',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                child: Text(alertStatus),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.50,
                        45) // put the width and height you want
                    ),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  if (alertStatus == 'SET ALERT') {
                    bool? isValid = _formKey.currentState?.validate();
                    if (isValid != null && isValid) {
                      _persistData();

                      double minValue =
                          double.parse(minTextEditingController.text);
                      double maxValue =
                          double.parse(maxTextEditingController.text);
                      if (minValue < maxValue) {
                        FlutterBackgroundService().sendData(
                          {
                            "action": "limit-set",
                            "minValue": minValue,
                            "maxValue": maxValue
                          },
                        );
                        alertStatus = 'STOP ALERT';
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Set a valid minimum and maximum limit")));
                      }
                    }
                  } else {
                    _persistData();
                    FlutterBackgroundService().sendData(
                      {
                        "action": "limit-clear",
                      },
                    );
                    alertStatus = 'SET ALERT';
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _loadPersistedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('data')) {
      String? data = prefs.getString('data');
      if (data != null) {
        Map<String, dynamic> decodedData = json.decode(data);
        serviceStatus = decodedData['serviceState'];
        alertStatus = decodedData['alertState'];
        minTextEditingController.text = decodedData['minValue'];
        maxTextEditingController.text = decodedData['maxValue'];
        setState(() {});
      }
    }
  }

  _persistData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String data = json.encode({
      'serviceState': serviceStatus,
      'alertState': alertStatus,
      'minValue': minTextEditingController.text,
      'maxValue': maxTextEditingController.text
    });
    await prefs.setString('data', data);
  }
}
