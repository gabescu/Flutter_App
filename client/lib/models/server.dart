DateTime dateTimetoJson(DateTime dateTime) => dateTime?.toUtc();

DateTime dateTimeFromJson(dynamic dateTimeData) => dateTimeData?.toDate()?.toUtc() ?? DateTime(1980);

class Server {
  final String name;
  String token;
  DateTime lastKeepalive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'token': token,
      'keepalive': dateTimetoJson(lastKeepalive),
    };
  }

  static Server fromJson(Map<String, dynamic> data) => Server(
      data['name'],
      data['token'],
      dateTimeFromJson(data['keepalive'])
  );

  Server withToken(String token) {
    this.token = token;
    return this;
  }

  Server(this.name, this.token, this.lastKeepalive);
}