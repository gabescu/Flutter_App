import 'package:cloud_functions/cloud_functions.dart';
import 'package:server/models/server_response.dart';

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

  Future<void> sendImage(ServerResponse serverResponse, onSuccess(String downloadUrl), {onError(String error)}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'returnImage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final HttpsCallableResult result = await callable.call(serverResponse.toJson());
      if (result.data["STATUS"] == OperationStatus.COMPLETED.toInt()) {
        var downloadUrl = result.data["DATA"] as String;
        onSuccess(downloadUrl);
      } else {
        onError(result.data["DATA"] as String);
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> sendConfirmation(ServerResponse serverResponse, onSuccess(List results), {onError(String error)}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'returnConfirmation',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final HttpsCallableResult result = await callable.call(serverResponse.toJson());
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
