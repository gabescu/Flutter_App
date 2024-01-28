import 'package:client/models/client_command.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum OperationStatus { COMPLETED, ERRORED }

extension OperationStatusExtension on OperationStatus {
  int toInt() => this.index + 1;
}

class BackendRequester {
  static final BackendRequester _singleton = BackendRequester._internal();
  factory BackendRequester() {
    return _singleton;
  }
  BackendRequester._internal();

  Future<void> sendCommand(ClientCommand command, onSuccess(List results), {onError(String error)}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'sendClientCommand',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final HttpsCallableResult result = await callable.call(command.toJson());
      if (result.data["STATUS"] == OperationStatus.COMPLETED.toInt()) {
        var results = result.data["DATA"] as List;
        onSuccess(results);
      } else {
        onError(result.data["DATA"] as String);
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
