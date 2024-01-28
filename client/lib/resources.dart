enum ClientAction {
  TAKE_PICTURE,
  VIBRATE,
  PLAY_SOUND
}

extension ClientActionExtension on ClientAction {
  String get toName => this.toString().split('.').last.toLowerCase();
}

enum ServerResponseType {
  TAKE_PICTURE,
  VIBRATE,
  PLAY_SOUND
}

extension ServerResponseExtension on ServerResponseType {
  String get toName => this.toString().split('.').last.toLowerCase();
}