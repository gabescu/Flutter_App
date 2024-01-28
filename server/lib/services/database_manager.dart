import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:server/models/client_command.dart';
import 'package:server/models/server.dart';

class DatabaseManager {
  static final DatabaseManager _singleton = DatabaseManager._internal();
  factory DatabaseManager() {
    return _singleton;
  }
  DatabaseManager._internal() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (authenticatedUser == null)
        await unregisterServer();
    });
  }
  
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _lastId;
  User get authenticatedUser => FirebaseAuth.instance.currentUser;
  DatabaseReference _serversDbRef;
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd-hh:mm:ss');

  Future<void> registerServer(Server server) async {
    try {
      if (authenticatedUser == null)
        await FirebaseAuth.instance.signInAnonymously();

      await _firestore.collection("servers").doc(server.name).set(server.toJson());
      _serversDbRef = _realtimeDb.reference().child(server.name);

      _lastId = server.name;
    } catch (e) {
      print(e);
    }
  }

  Future<void> logCommand(ClientCommand command) async {
    try {
      var now = DateTime.now().toUtc();
      await _serversDbRef.child(_dateFormat.format(now)).set(command.toJson());
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateKeepAlive() async {
    try {
      await _firestore.collection("servers").doc(_lastId).update({
        "keepalive": DateTime.now()
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> unregisterServer() async {
    try {
      await _firestore.collection("servers").doc(_lastId).delete();
    } catch (e) {
      print(e);
    }
  }
}