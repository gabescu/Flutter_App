import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:server/models/client_command.dart';
import 'package:server/models/server_response.dart';
import 'package:server/resources.dart';
import 'package:server/services/database_manager.dart';
import 'package:vibrate/vibrate.dart';
import 'backend_requester.dart';


Future<void> clearCache() async {
  final appDir = await getApplicationSupportDirectory();
  final cacheDir = await getTemporaryDirectory();

  if (cacheDir.existsSync()) {
    cacheDir.deleteSync(recursive: true);
  }

  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
}

Future<bool> takePicture(String clientToken, String commandId, {CameraController cameraController}) async {
  var _requester = BackendRequester();
  var _dbManager = DatabaseManager();

  try {
    if (cameraController == null) {
      var cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      await cameraController.initialize();
      await cameraController.lockCaptureOrientation();
    }
    var storedPicture = await cameraController?.takePicture();
    var pictureBytes = await storedPicture?.readAsBytes();

    if (pictureBytes != null) {
      var _resizedHeight = 1024;
      var _resizedWidth = (1024 * (1920/1080)).toInt();
      var trimmedBytes = await FlutterImageCompress.compressWithList(
        pictureBytes,
        minHeight: _resizedHeight,
        minWidth: _resizedWidth,
        quality: 95,
        format: CompressFormat.jpeg,
      );
      var serverResponse = ServerResponse(ServerResponseType.TAKE_PICTURE, base64Encode(trimmedBytes), clientToken);
      await _requester.sendImage(serverResponse, (downloadUri) async {
        var clientCommand = ClientCommand(commandId, clientToken, ClientAction.TAKE_PICTURE, pictureBytes != null);
        clientCommand.setOutput(downloadUri);
        await _dbManager.logCommand(clientCommand);
      });
    }

    return true;
  } catch(e) {
    print(e);
    var serverResponse = ServerResponse(ServerResponseType.TAKE_PICTURE, false, clientToken);
    await _requester.sendConfirmation(serverResponse, (id) {
      print("Response sent with $id");
    });
    return false;
  }
}

Future<bool> vibrate(String clientToken, String commandId) async {
  var _requester = BackendRequester();
  var _dbManager = DatabaseManager();

  try {
    bool canVibrate = await Vibrate.canVibrate;
    if (canVibrate)
      await Vibrate.vibrate();

    var clientCommand = ClientCommand(commandId, clientToken, ClientAction.VIBRATE, canVibrate);
    await _dbManager.logCommand(clientCommand);

    var serverResponse = ServerResponse(ServerResponseType.VIBRATE, canVibrate, clientToken);
    await _requester.sendConfirmation(serverResponse, (id) {
      print("Response sent with $id");
    });

    return canVibrate;
  } catch(e) {
    print(e);
    var serverResponse = ServerResponse(ServerResponseType.VIBRATE, false, clientToken);
    await _requester.sendConfirmation(serverResponse, (id) {
      print("Response sent with $id");
    });
    return false;
  }
}

Future<bool> playSound(String clientToken, String commandId) async {
  var _requester = BackendRequester();

  try {
    var _dbManager = DatabaseManager();
    FlutterBeep.beep();

    var clientCommand = ClientCommand(commandId, clientToken, ClientAction.PLAY_SOUND, true);
    await _dbManager.logCommand(clientCommand);

    var serverResponse = ServerResponse(ServerResponseType.PLAY_SOUND, true, clientToken);
    await _requester.sendConfirmation(serverResponse, (id) {
      print("Response sent with $id");
    });

    return true;
  } catch(e) {
    print(e);
    var serverResponse = ServerResponse(ServerResponseType.PLAY_SOUND, false, clientToken);
    await _requester.sendConfirmation(serverResponse, (id) {
      print("Response sent with $id");
    });
    return false;
  }
}