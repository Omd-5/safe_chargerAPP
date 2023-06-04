import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_info/enums/charging_status.dart';
import 'package:battery_info/model/android_battery_info.dart';
import 'package:battery_info/model/iso_battery_info.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return monitorBattery();
  }
}

class monitorBattery extends StatefulWidget {
  const monitorBattery({super.key});

  @override
  State<monitorBattery> createState() => _monitorBatteryState();
}

////////////////////////////////////////////////////////////

class _monitorBatteryState extends State<monitorBattery> {
  BluetoothConnection? connection;

  Future<void> _initBluetoothConnection() async {
    try {
      connection = await BluetoothConnection.toAddress('98:D3:31:F5:C9:29');
      // BluetoothDevice device =
      // await BluetoothDevice.fromAddress('98:D3:31:F5:C9:29');
      // print('Connected to ${device.name} [${device.address}]');
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initBluetoothConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FutureBuilder<AndroidBatteryInfo?>(
            future: BatteryInfoPlugin().androidBatteryInfo,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                    'Battery Health: ${snapshot.data?.health?.toUpperCase()}');
              }
              return CircularProgressIndicator();
            }),
        SizedBox(
          height: 20,
        ),
        StreamBuilder<AndroidBatteryInfo?>(
            stream: BatteryInfoPlugin().androidBatteryInfoStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.hasData) {
                  // connect();
                  int level = snapshot.data!.batteryLevel!;
                  int capcity = snapshot.data!.batteryCapacity!;
                  // int left = snapshot.data!.remainingEnergy!;
                  int time_reming = snapshot.data!.chargeTimeRemaining!;
                  int volt = snapshot.data!.voltage!;
                  delayedFunction(1);
                  String bluto = "$level,$capcity,$time_reming,$volt";
                  send(bluto);
                }
                return Column(
                  children: [
                    Text("Voltage: ${(snapshot?.data?.voltage)} mV"),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                        "Charging status: ${(snapshot.data?.chargingStatus.toString().split(".")[1])}"),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Battery Level: ${(snapshot.data?.batteryLevel)} %"),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                        "Battery Capacity: ${(snapshot.data!.batteryCapacity! / 1000)} mAh"),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Technology: ${(snapshot.data?.technology)} "),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                        "Battery present: ${snapshot.data!.present! ? "Yes" : "False"} "),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Scale: ${(snapshot.data?.scale)} "),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                        "Remaining energy: ${-(snapshot.data!.remainingEnergy! * 1.0E-9)} Watt-hours,"),
                    SizedBox(
                      height: 20,
                    ),
                    _getChargeTime(snapshot.data!),
                  ],
                );
              }
              return CircularProgressIndicator();
            })
      ],
    );
  }

  Widget _getChargeTime(AndroidBatteryInfo data) {
    if (data.chargingStatus == ChargingStatus.Charging) {
      return data.chargeTimeRemaining == -1
          ? Text("Calculating charge time remaining")
          : Text(
              "Charge time remaining: ${(data.chargeTimeRemaining! / 1000 / 60).truncate()} minutes");
    }
    return Text("Battery is full or not connected to a power source");
  }

  @override
  void dispose() {
    connection?.close();
    super.dispose();
  }

  Future<void> delayedFunction(int duration) async {
    print('Starting delayed function...');
    await Future.delayed(Duration(seconds: duration));
    print('Delayed function finished!');
  }

  void send(String txt) async {
    try {
      connection!.output.add(Uint8List.fromList(utf8.encode(txt + "\r\n")));
      await connection!.output.allSent;
    } catch (e) {
      print(e);
    }
  }
}
