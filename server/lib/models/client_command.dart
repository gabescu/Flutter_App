import 'package:server/resources.dart';

class ClientCommand {
  final String commandId;
  final String clientToken;
  final ClientAction action;
  dynamic _output;
  final bool completed;

  ClientCommand(this.commandId, this.clientToken, this.action, this.completed);

  void setOutput(dynamic output) => this._output = output;

  Map<String, dynamic> toJson() {
    return {
      "commandId": commandId,
      "clientToken": clientToken,
      "action": action.toName,
      "completed": completed,
      "output": _output,
    };
  }
}