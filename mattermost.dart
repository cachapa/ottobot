import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'config.dart';

class Mattermost {
  var _endpoint;
  var _token;
  var _userId;
  var _teamId;

  Mattermost() {
    _endpoint =
        (SECURE_SOCKET ? "https" : "http") + "://" + MATTERMOST_URL + "/api/v4";
  }

  connect() async {
    // Login and get token
    await _refreshToken();

    // Fetch team id
    _teamId = (await _get("/teams/name/$TEAM_NAME"))["id"];

    // Start listening to commands
    new SocketGateway(_token).connectSocket();
  }

  post(String channel, String message) async {
    var channelId = await _getChannelId(channel);
    _post("/posts", {"channel_id": channelId, "message": message});
  }

  _refreshToken() async {
    var endpoint = _endpoint + "/users/login";
    var body = {"login_id": USERNAME, "password": PASSWORD};
    print("--> POST $endpoint");
    print("    $body");

    var response = await http.post(endpoint, body: JSON.encode(body));
    _token = response.headers["token"];
    _userId = JSON.decode(response.body)["id"];
    print("token: $_token");
    print("userId: $_userId\n");
  }

  _getChannelId(channel) async {
    // TODO Cache channel id
    return (await _get("/teams/$_teamId/channels/name/$channel"))["id"];
  }

  _get(String path) async {
    var endpoint = _endpoint + path;
    print("--> GET $endpoint");

    var response =
        await http.get(endpoint, headers: {"Authorization": "Bearer $_token"});
    print("<-- ${response.statusCode} ${response.body}\n");
    return JSON.decode(response.body);
  }

  _post(String path, dynamic body) async {
    var endpoint = _endpoint + path;
    print("--> POST $endpoint");
    print("    $body");

    http
        .post(endpoint,
            headers: {"Authorization": "Bearer $_token"},
            body: JSON.encode(body))
        .then((response) {
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}\n");
    });
  }
}

class SocketGateway {
  var _endpoint;
  var _token;

  SocketGateway(this._token) {
    _endpoint = (SECURE_SOCKET ? "wss" : "ws") +
        "://" +
        MATTERMOST_URL +
        "/api/v4/websocket";
  }

  WebSocket _socket;
  connectSocket() async {
    print("Connecting...");
    _socket = await WebSocket.connect(_endpoint);
    _socket.pingInterval = new Duration(seconds: 5);
    print("Connected");
    _socket.add(JSON.encode({
      "seq": 1,
      "action": "authentication_challenge",
      "data": {"token": _token}
    }));

    _socket.listen(
      (event) => print("<-- $event\n"),
      onDone: () => print("Done"),
      onError: (error) => print(error),
      cancelOnError: false,
    );
  }
}
