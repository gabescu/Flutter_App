import 'package:client/resources.dart';
import 'package:uuid/uuid.dart';

class ClientCommand {
  String commandId;
  final String clientToken;
  final ClientAction action;
  final String serverToken;

  ClientCommand(this.clientToken, this.action, this.serverToken) {
    this.commandId = Uuid().v4();
  }

  Map<String, dynamic> toJson() {
    return {
      "commandId": commandId,
      "clientToken": clientToken,
      "action": action.toName,
      "serverToken": serverToken
    };
  }
}