import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:server/resources.dart';
import 'package:server/screens/dashboard.dart';
import 'package:server/services/listener_commands.dart';

AndroidNotificationChannel _channel;
FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
List<CameraDescription> _cameras;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  var data = message.data;
  var clientToken = data["clientToken"];
  var action = data["action"];
  var commandId = data["commandId"];

  if (action == ClientAction.TAKE_PICTURE.toName) {
    _cameras = await availableCameras();
    if (_cameras.length > 0) {
      var cameraController = CameraController(_cameras[0], ResolutionPreset.max);
      await cameraController.initialize();
      await takePicture(clientToken, commandId, cameraController: cameraController);
    }
  } else if (action == ClientAction.VIBRATE.toName) {
    await vibrate(clientToken, commandId);
  } else if (action == ClientAction.PLAY_SOUND.toName) {
    await playSound(clientToken, commandId);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await clearCache();

  _channel = const AndroidNotificationChannel(
    'client_channel',
    'Client Events',
    'Events sent from client',
    importance: Importance.max,
  );
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  _cameras = await availableCameras();

  runApp(ServerApp());
}

class ServerApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(414, 896),
      builder: () => MaterialApp(
        title: 'Server App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: DashboardScreen(
          channel: _channel,
          plugin: _flutterLocalNotificationsPlugin,
          cameras: _cameras,
        ),
      ),
    );
  }
}
