import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'config.dart';

class Mattermost {
  _RestGateway _restGateway;

  connect(EventCallback callback) async {
    _restGateway = new _RestGateway();

    // Login and get token
    await _restGateway.login();

    // Start listening to commands
    new _SocketGateway(callback).connectSocket(_restGateway._token);
  }

  post({String channel, String channelId, String message}) async {
    assert((channel != null && channelId == null) ||
        (channel == null && channelId != null));
    if (channel != null) {
      channelId = await _restGateway._getChannelId(channel);
    }
    _restGateway.post(channelId, message);
  }
}

class _RestGateway {
  final _endpoint;
  var _token;
  var _teamId;

  _RestGateway()
      : _endpoint = (SECURE_SOCKET ? "https" : "http") +
            "://" +
            MATTERMOST_URL +
            "/api/v4";

  login() async {
    var endpoint = _endpoint + "/users/login";
    var body = {"login_id": USERNAME, "password": PASSWORD};
    print("--> POST $endpoint");
    print("    $body");

    var response = await http.post(endpoint, body: JSON.encode(body));
    _token = response.headers["token"];
    print("token: $_token");

    // Fetch team id
    _teamId = (await _get("/teams/name/$TEAM_NAME"))["id"];
  }

  post(String channelId, String message) async {
    _post("/posts", {"channel_id": channelId, "message": message});
  }

  getChannelId(channel) async {
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

class _SocketGateway {
  final _endpoint;
  final EventCallback _callback;

  _SocketGateway(this._callback)
      : _endpoint = (SECURE_SOCKET ? "wss" : "ws") +
            "://" +
            MATTERMOST_URL +
            "/api/v4/websocket";

  WebSocket _socket;
  connectSocket(var token) async {
    print("Connecting...");
    _socket = await WebSocket.connect(_endpoint);
    _socket.pingInterval = new Duration(seconds: 5);
    print("Connected");
    _socket.add(JSON.encode({
      "seq": 1,
      "action": "authentication_challenge",
      "data": {"token": token}
    }));

    _socket.listen(
      (event) => _handleEvent(JSON.decode(event)),
      onDone: () => print("Done"),
      onError: (error) => print(error),
      cancelOnError: false,
    );
  }

  _handleEvent(var event) {
    print("<-- $event\n");

    var type = event["event"];
    switch (type) {
      case "posted":
        var sender = event["data"]["sender_name"];
        if (sender != USERNAME) {
          var post = JSON.decode(event["data"]["post"]);
          String message = post["message"];
          if (message.contains("@$USERNAME")) {
            _callback(sender, post["channel_id"], message);
          }
        }
        break;
    }
  }
}

typedef void EventCallback(String sender, String channelId, String message);
