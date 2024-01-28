
import 'package:server/resources.dart';

class ServerResponse {
  final dynamic data;
  final String clientToken;
  final ServerResponseType response;

  ServerResponse(this.response, this.data, this.clientToken);

  Map<String, dynamic> toJson() {
    return {
      "response": data,
      "responseType": response.toName,
      "clientToken": clientToken
    };
  }
}