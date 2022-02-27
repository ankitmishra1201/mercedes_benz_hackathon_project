import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
class DeviceScreen extends StatefulWidget {
  DeviceScreen({Key? key, required this.device}) : super(key: key);
  // Receive device information
  final BluetoothDevice device;

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // flutterBlue
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // connection status display string
  String stateText = 'Connecting';

  // connect button string
  String connectButtonText = 'Disconnect';

  // for saving the current connection state
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  // To release the listener when the connection status listener handle screen is closed
  StreamSubscription<BluetoothDeviceState>? _stateListener;

  @override
  initState() {
    super.initState();
    // Register state-connected listener
    _stateListener = widget.device.state.listen((event) {
      debugPrint('event :  $event');
      if (deviceState == event) {
        // change connection state information
        return;
      }
      // 연결 상태 정보 변경
      setBleConnectionState(event);
    });
    // start connection
    connect();
  }

  @override
  void dispose() {
    // clear the status lister
    _stateListener?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      // Update only when the screen is mounted
      super.setState(fn);
    }
  }

  /* update connection state */
  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        FlutterRingtonePlayer.stop();

        connectButtonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        FlutterRingtonePlayer.stop();
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        FlutterRingtonePlayer.play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.alarm,
          looping: true, // Android only - API >= 28
          volume: 0.1, // Android only - API >= 28
          asAlarm: false,
        );
        // change button state
        connectButtonText = 'Disconnect';
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        FlutterRingtonePlayer.play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.alarm,
          looping: true, // Android only - API >= 28
          volume: 0.1, // Android only - API >= 28
          asAlarm: false,
        );

        break;
    }
    //save previous state event
    deviceState = event;
    setState(() {});
  }

  /* start connection */
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      /* 상태 표시를 Connecting으로 변경 */
      stateText = 'Connecting';
    });

    /*
       Set timeout to 10 seconds (10000ms) and disable autoconnect
        For reference, if autoconnect is set to true, the connection may be delayed.
      */
    await widget.device
        .connect(autoConnect: true)
        .timeout(Duration(milliseconds: 10000), onTimeout: () {
      // timeout occurs
      //set returnValue to false
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      // change the connection state to disconnected
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) {
      if (returnValue == null) {
        // If returnValue is null, timeout does not occur and connection is successful
        debugPrint('connection successful');
        returnValue = Future.value(true);
      }
    });

    return returnValue ?? Future.value(false);
  }

  /* disconnect */
  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.device.name),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /* 연결 상태 */
              Text('$stateText'),
              /* connection state */
              OutlinedButton(
                  onPressed: () {
                    if (deviceState == BluetoothDeviceState.connected) {
                      /* Disconnect if connected */
                      disconnect();
                    } else if (deviceState == BluetoothDeviceState.disconnected) {
                      /* Connect if disconnected */
                      connect();
                    } else {}
                  },
                  child: Text(connectButtonText)),
            ],
          )),
    );
  }
}
