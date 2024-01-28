import 'package:client/models/server.dart';

import 'database_stub.dart'
  // ignore: uri_does_not_exist
  if (dart.library.js) 'package:client/service/web_database_manager.dart'
  // ignore: uri_does_not_exist
  if (dart.library.io) 'package:client/service/mobile_database_manager.dart';


abstract class DatabaseManager {
  void listenToServer(String serverName, String commandId, Function(DateTime dateReceived, dynamic data) onMessageReceived);

  Future<List<Server>> getServerTokens();

  factory DatabaseManager() => getDatabaseManager();
}