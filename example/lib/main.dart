import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zendesk_flutter_plugin/zendesk_flutter_plugin.dart';
import 'package:zendesk_flutter_plugin/chat_models.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _chatStatus = 'Uninitialized';
  String _zendeskAccountkey = '';

  final ZendeskFlutterPlugin _chatApi = ZendeskFlutterPlugin();

  StreamSubscription<ConnectionStatus> _chatConnectivitySubscription;
  StreamSubscription<AccountStatus> _chatAccountSubscription;
  StreamSubscription<List<Agent>> _chatAgentsSubscription;
  StreamSubscription<List<ChatItem>> _chatItemsSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await _chatApi.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _chatConnectivitySubscription =
        _chatApi.onConnectionStatusChanged.listen(_chatConnectivityUpdated);
    _chatAccountSubscription =
        _chatApi.onAccountStatusChanged.listen(_chatAccountUpdated);
    _chatAgentsSubscription =
        _chatApi.onAgentsChanged.listen(_chatAgentsUpdated);
    _chatItemsSubscription =
        _chatApi.onChatItemsChanged.listen(_chatItemsUpdated);

    String chatStatus;
    try {
      await _chatApi.init(_zendeskAccountkey);
      chatStatus = 'INITIALIZED';
    } on PlatformException {
      chatStatus = 'Failed to initialize.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _chatStatus = chatStatus;
    });
  }

  @override
  void dispose() {
    _chatConnectivitySubscription.cancel();
    _chatAccountSubscription.cancel();
    _chatAgentsSubscription.cancel();
    _chatItemsSubscription.cancel();
    _chatApi.endChat();
    super.dispose();
  }

  void _chatConnectivityUpdated(ConnectionStatus status) {
    print('chatConnectivityUpdated: $status');
  }

  void _chatAccountUpdated(AccountStatus status) {
    print('chatAccountUpdated: $status');
  }

  void _chatAgentsUpdated(List<Agent> agents) {
    print('chatAgentsUpdated:');
    agents.forEach((e) => debugPrint(e.toString()));
  }

  void _chatItemsUpdated(List<ChatItem> chatLog) {
    print('chatItemsUpdated:');
    chatLog.forEach((e) => debugPrint(e.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('Running on: $_platformVersion\n'),
            Text('Chat status: $_chatStatus'),
            RaisedButton(
              onPressed: () async {
                await _chatApi.startChat('Test Visitor Name',
                    department: 'Card');
              },
              child: Text("Start Chat"),
            ),
            RaisedButton(
              onPressed: () async {
                await _chatApi.sendMessage('Greeting from Visitor');
              },
              child: Text("Send Greeting Message"),
            ),
            RaisedButton(
              onPressed: () async {
                final file =
                    await ImagePicker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  try {
                    await _chatApi.sendAttachment(file.path);
                  } on PlatformException catch (e) {
                    debugPrint('An error occurred: ${e.code}');
                  }
                }
              },
              child: Text("Send Attachment"),
            ),
            RaisedButton(
              onPressed: () async {
                await _chatApi.sendChatRating(ChatRating.GOOD,
                    comment: 'Good service');
              },
              child: Text("Send GOOD Rating"),
            ),
            RaisedButton(
              onPressed: () async {
                await _chatApi.sendChatRating(ChatRating.BAD,
                    comment: 'Bad service');
              },
              child: Text("Send BAD Rating"),
            ),
            RaisedButton(
              onPressed: () async {
                await _chatApi
                    .sendOfflineMessage('Offline Greeting from Visitor');
              },
              child: Text("Send Offline Message"),
            ),
            RaisedButton(
              onPressed: () async {
                await _chatApi.endChat();
              },
              child: Text("EndChat"),
            ),
          ],
        )),
      ),
    );
  }
}
