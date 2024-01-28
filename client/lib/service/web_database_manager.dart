import 'package:client/models/server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebase.dart';
import 'package:intl/intl.dart';
import 'database_manager.dart';

class WebDatabaseManager implements DatabaseManager {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd-hh:mm:ss');
  Database _realtimeDb = database();

  @override
  void listenToServer(String serverName, String commandId, Function(DateTime dateReceived, dynamic data) onMessageReceived) {
    DatabaseReference serverRef = _realtimeDb.ref(serverName);
    serverRef.onChildAdded.listen((e) {
      var data = e.snapshot.toJson();
      var key = e.snapshot.key;

      var dateReceived = _dateFormat.parse(key);
      var id = data["commandId"];
      if (id == commandId) {
        print("ID $id IS EQUAL TO $commandId");
        onMessageReceived(dateReceived, data);
      }
    });
  }

  @override
  Future<List<Server>> getServerTokens() async {
    try {
      List<Server> servers = [];
      var snapshots = await _firestore.collection("servers").get();
      for (var doc in snapshots.docs) {
        var data = doc.data();
        servers.add(Server.fromJson(data));
      }
      return servers;
    } catch (e) {
      print(e);
      return null;
    }
  }
}

DatabaseManager getDatabaseManager() => WebDatabaseManager();