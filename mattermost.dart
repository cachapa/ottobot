import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'config.dart';

class Mattermost {
  _RestGateway _restGateway;
  _SocketGateway _socketGateway;

  PostCallback _postCallback;

  var _teamId;
  Map<String, String> _channelMap = new Map();

  connect(postCallback) async {
    _postCallback = postCallback;
    _restGateway = new _RestGateway();

    // Login and get token
    await _restGateway.login();
    _teamId = (await _restGateway.get("/teams/name/$TEAM_NAME"))["id"];

    // Start listening to commands
    _socketGateway = new _SocketGateway((event) => _handleEvent(event));
    _socketGateway.connectSocket(_restGateway._token);
  }

  disconnect() {
    _socketGateway._socket.close();
  }

  post(String channelId, String message) async {
    _restGateway.post("/posts", {"channel_id": channelId, "message": message});
  }

  getChannelId(channelName) async {
    // Cache channel id
    if (!_channelMap.containsKey(channelName)) {
      String channelId = (await _restGateway
          .get("/teams/$_teamId/channels/name/$channelName"))["id"];
      _channelMap[channelName] = channelId;
    }
    return _channelMap[channelName];
  }

  notifyTyping(String channelId) {
    _socketGateway.send("user_typing", {"channel_id": channelId});
  }

  _handleEvent(var event) {
    print("<-- $event\n");

    var type = event["event"];
    switch (type) {
      case "posted":
        var sender = event["data"]["sender_name"];
        if (sender != USERNAME) {
          var channelType = event["data"]["channel_type"];
          var post = JSON.decode(event["data"]["post"]);
          String message = post["message"];
          if (message.contains("@$USERNAME") || channelType == "D") {
            _postCallback(sender, post["channel_id"], message);
          }
        }
        break;
    }
  }
}

class _RestGateway {
  final _endpoint;
  var _token;

  _RestGateway()
      : _endpoint = (SECURE_SOCKET ? "https" : "http") +
            "://" +
            MATTERMOST_URL +
            "/api/v4";

  login() async {
    var endpoint = _endpoint + "/users/login";
    var body = {"login_id": USERNAME, "password": PASSWORD};
    print("--> POST $endpoint");
    print("    ${body.toString().replaceAll(PASSWORD, "******")}");

    var response = await http.post(endpoint, body: JSON.encode(body));
    _token = response.headers["token"];
    print("token: $_token");
  }

  get(String path) async {
    var endpoint = _endpoint + path;
    print("--> GET $endpoint");

    var response =
        await http.get(endpoint, headers: {"Authorization": "Bearer $_token"});
    print("<-- ${response.statusCode} ${response.body}\n");
    return JSON.decode(response.body);
  }

  post(String path, dynamic body) async {
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
  final _EventCallback _callback;
  var _seq = 0;

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

    // Authenticate the socket connection
    send("authentication_challenge", {"token": token});

    // Start listening to events
    _socket.listen(
      (event) {
        var map = JSON.decode(event);
        if (map.containsKey("seq")) {
          _seq = map["seq"];
        }
        _callback(map);
      },
      onDone: () => print("Done"),
      onError: (error) => print(error),
      cancelOnError: false,
    );
  }

  send(String action, Map data) {
    var payload = {"seq": _seq + 1, "action": action, "data": data};
    print("--> $payload");
    _socket.add(JSON.encode(payload));
  }
}

typedef void _EventCallback(Map event);

typedef void PostCallback(String sender, String channelId, String message);
