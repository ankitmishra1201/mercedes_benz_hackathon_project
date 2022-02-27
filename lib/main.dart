import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'Soteria';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  bool _isScanning = false;

  @override
  initState() {
    super.initState();
    // Initialize Bluetooth
    initBle();
  }

  void initBle() {
    // Listener to get BLE scan status
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  /*
   Scan start/stop function
   */
  scan() async {
    if (!_isScanning) {
      // if not scanning
      // Delete the previously scanned list
      scanResultList.clear();
      // start scan, timeout 4 seconds
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      // scan result listener
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
        // Update UI
        setState(() {});
      });
    } else {
      // If scanning, stop scanning
      flutterBlue.stopScan();
    }
  }

  /*
    From here, functions for output by device
   */
  /* Device signal value widget */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /* Device MAC address widget */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* Device name widget */
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      // If device.name has a value
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // if advertisementData.localName has a value
      name = r.advertisementData.localName;
    }else if (r.device.name.isEmpty&& r.advertisementData.localName.isEmpty){
      name="Band Name";

    }
    return Text(name);
  }

  Widget devicestatus(ScanResult r) {
    String status = '';
    status=r.device.state.toString();


    return Text(status);
  }
  /* BLE icon widget */
  Widget leading(ScanResult r) {
    return CircleAvatar(
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
      backgroundColor: Colors.cyan,
    );
  }

  /* Function called when a device item is tapped */
  void onTap(ScanResult r) {
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }

  /* device item widget */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        /* print device list */
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(
                scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider();
          },
        ),
      ),
      /* Search for devices or stop searching */
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        // Display a stop icon if scanning is in progress, and a search icon if it is in a stopped state
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
