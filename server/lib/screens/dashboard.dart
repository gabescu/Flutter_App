import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:server/models/server.dart';
import 'package:server/resources.dart';
import 'package:server/screens/widgets/standard_button.dart';
import 'package:server/screens/widgets/standard_text.dart';
import 'package:server/services/database_manager.dart';
import 'package:server/services/listener_commands.dart';
import 'package:uuid/uuid.dart';

class DashboardScreen extends StatefulWidget {

  final AndroidNotificationChannel channel;
  final FlutterLocalNotificationsPlugin plugin;
  final List<CameraDescription> cameras;

  const DashboardScreen({
    Key key,
    this.channel,
    this.plugin,
    this.cameras
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DashboardScreenState();


}
class DashboardScreenState extends State<DashboardScreen> {
  String _statusText;
  bool _status;
  ClientAction _lastCommand;
  DateTime _receivedAt;
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');

  FirebaseMessaging _messaging = FirebaseMessaging.instance;
  DatabaseManager _dbManager = DatabaseManager();
  CameraController _cameraController;
  DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.androidId,
      'systemFeatures': build.systemFeatures,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Future<Map<String, dynamic>> _getDeviceData() async {
    Map<String, dynamic> deviceData;
    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await _deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await _deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      print('Failed to get platform version.');
    }
    return deviceData;
  }



  @override
  void initState() {
    super.initState();

    final AndroidInitializationSettings initializationSettingsAndroid  = AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
      defaultPresentAlert: false,
      defaultPresentSound: false,
      defaultPresentBadge: false,
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false
    );
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS
    );
    widget.plugin.initialize(initializationSettings);

    if (widget.cameras.length > 0) {
      _cameraController = CameraController(widget.cameras[0], ResolutionPreset.max);
      _cameraController.initialize().then((_) async {
        await _cameraController.lockCaptureOrientation();
        if (!mounted) return;
        setState(() {});
      });
    }

    _messaging.requestPermission(
      alert: false,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: false,
    ).then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          var fcmToken = await FirebaseMessaging.instance.getToken();

          var deviceName = Uuid().v4();
          var deviceData = await _getDeviceData();
          if (deviceData != null)
            deviceName = deviceData["model"].toString();

          var server = Server(deviceName, fcmToken, DateTime.now().toUtc());
          await _dbManager.registerServer(server);
          FirebaseMessaging.instance.onTokenRefresh.listen((String token) async => await _dbManager.registerServer(server.withToken(token)));
          FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
            _receivedAt = DateTime.now();
            _statusText = "Executing command";

            var data = message.data;
            var clientToken = data["clientToken"];
            var action = data["action"];
            var commandId = data["commandId"];

            if (action == ClientAction.TAKE_PICTURE.toName) {
              _lastCommand = ClientAction.TAKE_PICTURE;
              _status = await takePicture(clientToken, commandId, cameraController: _cameraController);
            } else if (action == ClientAction.VIBRATE.toName) {
              _lastCommand = ClientAction.VIBRATE;
              _status = await vibrate(clientToken, commandId);
            } else if (action == ClientAction.PLAY_SOUND.toName) {
              _lastCommand = ClientAction.PLAY_SOUND;
              _status = await playSound(clientToken, commandId);
            }

            setState(() {
              _status ? _statusText = "Command finished succesfully" : _statusText = "Command finished with errors";
            });
          });
          Timer.periodic(Duration(minutes: 5), (Timer t) => _dbManager.updateKeepAlive());
        });
      }
    });
  }

  @override
  void dispose() {
    Future.delayed(Duration.zero, () async {
      await _dbManager.unregisterServer();
      await _cameraController.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 80.h,),
            StandardText(
              color: Colors.black,
              text: "Server App",
              size: 32.sp,
              weight: FontWeight.bold,
            ),
            SizedBox(height: 80.h,),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StandardText(
                        color: Colors.orange,
                        text: "Status: ${_statusText != null ? _statusText : ""}",
                        size: 18.sp,
                      ),
                      SizedBox(height: 32.h,),
                      StandardText(
                        color: Colors.orange,
                        text: "Last Command: ${_lastCommand != null ? _lastCommand.toName : ""}",
                        size: 18.sp,
                      ),
                      SizedBox(height: 32.h,),
                      StandardText(
                        color: Colors.orange,
                        text: "Received at: ${_receivedAt != null ? _dateFormat.format(_receivedAt) : ""}",
                        size: 18.sp,
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 40.h,),
            Center(
              child: StandardButton(
                width: 120.w,
                text: "Close App",
                onPressed: () async {
                  await _dbManager.unregisterServer();
                  exit(0);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

}