import 'dart:async';
import 'dart:collection';
import 'package:client/models/client_command.dart';
import 'package:client/models/server.dart';
import 'package:client/resources.dart';
import 'package:client/screens/widgets/standard_text.dart';
import 'package:client/screens/widgets/standart_button.dart';
import 'package:client/service/backend_requester.dart';
import 'package:client/service/database_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';


class DashboardBody extends StatefulWidget {
  final Server server;

  const DashboardBody({Key key, this.server}) : super(key: key);

  @override
  _DashboardBodyState createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  BackendRequester _requester = BackendRequester();
  DatabaseManager _dbManager = DatabaseManager();
  FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String _networkImgUrl;

  bool _takePictureStatus;
  bool _vibrateStatus;
  bool _playSoundStatus;

  DateTime _receivedAt;
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');

  String _token;

  Queue<ClientCommand> _commandSequence;
  int _increment = 10;
  int _breakSequenceTime = 1000;
  int _coolDownTime = 1000;
  bool _canTakePicture = true;
  bool _canEnqueue = true;
  Timer _incrementTimer;

  Future<void> setupListeners() async {
    _token = await FirebaseMessaging.instance.getToken();
    print("TOKEN IS: " + _token);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) => _token = newToken);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      var data = message.data;
      var response = data["response"];

      print("GOT A MESSAGE RESPONSEE: ${response}");
    });
  }

  void _resetStates() {
    _takePictureStatus = null;
    _vibrateStatus = null;
    _playSoundStatus = null;
  }

  @override
  void initState() {
    super.initState();

    _commandSequence = Queue();

    _messaging.requestPermission(
      alert: false,
      announcement: true,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    ).then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await setupListeners();
        });
      }
    });
  }

  void enqueueCommand(ClientCommand clientCommand) {
    if (_incrementTimer == null || !_incrementTimer.isActive) {
      _incrementTimer = Timer.periodic(Duration(milliseconds: _increment), (Timer timer) async {
        if (timer.tick >= _breakSequenceTime / _increment) {
          timer.cancel();
          for (var command in _commandSequence) {
            print("SEQUENCE LENGTH WAS: ${_commandSequence.length}");
            await _requester.sendCommand(command, (id) => print("Command initiated with id $id"));
          }
          _canEnqueue = false;
          Future.delayed(Duration(milliseconds: _coolDownTime), () => _canEnqueue = true);
          _commandSequence.clear();
        }
      });
    }
    _commandSequence.add(clientCommand);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width / 3;
    var height = MediaQuery.of(context).size.height / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 24.h,),
        if (_networkImgUrl != null)
          Container(
            width: width,
            height: height,
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    constrained: true,
                    scaleEnabled: true,
                    panEnabled: true,
                    minScale: 1,
                    maxScale: 3,
                    child: Image.network(
                      _networkImgUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16.h,),
                Center(
                  child: StandardText(
                    color: Colors.black,
                    text: "Image received from server at: ${_dateFormat.format(_receivedAt)}",
                    size: 16.sp,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 32.h,),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            width: width * 3 - 48,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StandardButton(
                        text: "REQUEST NEW PHOTO FROM SERVER",
                        onPressed: () async {
                          if (_canTakePicture && _token != null && widget.server != null) {
                            var clientCommand = ClientCommand(_token, ClientAction.TAKE_PICTURE, widget.server.token);

                            _dbManager.listenToServer(widget.server.name, clientCommand.commandId, (dateReceived, data) {
                              setState(() {
                                _networkImgUrl = data["output"];
                                _receivedAt = dateReceived;
                                _takePictureStatus = data["completed"].toString().toLowerCase() == 'true';
                              });
                            });
                            _resetStates();

                            _canTakePicture = false;
                            await _requester.sendCommand(clientCommand, (id) => print("Command initiated with id $id"));
                            Future.delayed(Duration(milliseconds: _coolDownTime), () => _canTakePicture = true);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w,),
                    if (_takePictureStatus != null)
                      Icon(_takePictureStatus ? Icons.check : Icons.close)
                  ],
                ),
                SizedBox(height: 24.h,),
                Row(
                  children: [
                    Expanded(
                      child: StandardButton(
                        text: "VIBRATE SERVER",
                        onPressed: () async {
                          if (_canEnqueue && _token != null && widget.server != null) {
                            var clientCommand = ClientCommand(_token, ClientAction.VIBRATE, widget.server.token);

                            _dbManager.listenToServer(widget.server.name, clientCommand.commandId, (dateReceived, data) {
                              setState(() {
                                _receivedAt = dateReceived;
                                _vibrateStatus = data["completed"].toString().toLowerCase() == 'true';
                              });
                            });
                            _resetStates();

                            enqueueCommand(clientCommand);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w,),
                    if (_vibrateStatus != null)
                      Icon(_vibrateStatus ? Icons.check : Icons.close)
                  ],
                ),
                SizedBox(height: 24.h,),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: StandardButton(
                        text: "PLAY SOUND ON SERVER",
                        onPressed: () async {
                          if (_canEnqueue && _token != null && widget.server != null) {
                            var clientCommand = ClientCommand(_token, ClientAction.PLAY_SOUND, widget.server.token);

                            _dbManager.listenToServer(widget.server.name, clientCommand.commandId, (dateReceived, data) {
                              setState(() {
                                _receivedAt = dateReceived;
                                _playSoundStatus = data["completed"].toString().toLowerCase() == 'true';
                              });
                            });
                            _resetStates();

                            enqueueCommand(clientCommand);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w,),
                    if (_playSoundStatus != null)
                      Icon(_playSoundStatus ? Icons.check : Icons.close)
                  ],
                ),
                SizedBox(height: 32.h,),
              ],
            ),
          )
        )
      ],
    );
  }
}