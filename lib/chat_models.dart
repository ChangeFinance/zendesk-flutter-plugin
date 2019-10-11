import 'package:meta/meta.dart';
import 'dart:convert';
import 'dart:io' show Platform;

enum ConnectionStatus {
  UNKNOWN,
  NO_CONNECTION,
  CLOSED,
  DISCONNECTED,
  CONNECTING,
  CONNECTED
}

enum AccountStatus {
  UNKNOWN,
  ONLINE,
  OFFLINE,
}

enum ChatItemType {
  UNKNOWN,
  MEMBER_JOIN,
  MEMBER_LEAVE,
  MESSAGE,
  SYSTEM_MESSAGE,
  TRIGGER_MESSAGE,
  REQUEST_RATING,
  RATING,
}

enum ChatRating {
  GOOD,
  BAD,
  UNRATED,
  UNKNOWN,
}

ConnectionStatus toConnectionStatus(String value) {
  switch (value) {
    case 'noConnection':
    case 'NO_CONNECTION':
      return ConnectionStatus.NO_CONNECTION;
    case 'closed':
    case 'CLOSED':
      return ConnectionStatus.CLOSED;
    case 'disconnected':
    case 'DISCONNECTED':
      return ConnectionStatus.DISCONNECTED;
    case 'connecting':
    case 'CONNECTING':
      return ConnectionStatus.CONNECTING;
    case 'connected':
    case 'CONNECTED':
      return ConnectionStatus.CONNECTED;
    default:
      return ConnectionStatus.UNKNOWN;
  }
}

AccountStatus toAccountStatus(String value) {
  switch (value) {
    case 'online':
    case 'ONLINE':
      return AccountStatus.ONLINE;
    case 'offline':
    case 'OFFLINE':
      return AccountStatus.OFFLINE;
    default:
      return AccountStatus.UNKNOWN;
  }
}

ChatItemType toChatItemType(String value) {
  switch (value) {
    case 'chat.memberjoin':
      return ChatItemType.MEMBER_JOIN;
    case 'chat.memberleave':
      return ChatItemType.MEMBER_LEAVE;
    case 'chat.msg':
    case 'chat.systemmsg':
    case 'chat.triggermsg':
      return ChatItemType.MESSAGE;
    case 'chat.request.rating':
      return ChatItemType.REQUEST_RATING;
    case 'chat.rating':
    case 'chat.comment':
      return ChatItemType.RATING;
    default:
      return ChatItemType.UNKNOWN;
  }
}

ChatRating toChatRating(String value) {
  switch (value) {
    case 'good':
      return ChatRating.GOOD;
    case 'bad':
      return ChatRating.BAD;
    case 'unrated':
      return ChatRating.UNRATED;
    default:
      return ChatRating.UNKNOWN;
  }
}

class AbstractModel {
  final String _id;
  final Map<String, dynamic> _attributes;
  final String _os;

  AbstractModel(this._id, this._attributes, [@visibleForTesting this._os]);

  String get id {
    return _id;
  }

  dynamic attribute(String attrname) {
    return _attributes != null ? _attributes[attrname] : null;
  }

  @visibleForTesting
  String os() {
    return this._os ?? Platform.operatingSystem;
  }

  String toString() => 'id=$_id ${JsonEncoder().convert(_attributes)}';
}

class Agent extends AbstractModel {
  Agent(String id, Map attributes, [@visibleForTesting String os])
      : super(id, attributes, os);

  String get displayName {
    if (os() == 'android') {
      return attribute('display_name');
    } else if (os() == 'ios') {
      return attribute('displayName');
    } else {
      return null;
    }
  }

  bool get isTyping {
    return attribute('typing');
  }

  String get avatarUri {
    if (os() == 'android') {
      return attribute('avatar_path');
    } else if (os() == 'ios') {
      return attribute('avatarURL');
    } else {
      return null;
    }
  }

  static List<Agent> parseAgentsJson(String json,
      [@visibleForTesting String os]) {
    var out = List<Agent>();
    jsonDecode(json).forEach((key, value) {
      out.add(Agent(key, value, os));
    });
    return out;
  }
}

class Attachment extends AbstractModel {
  Attachment(Map attributes, [@visibleForTesting String os])
      : super('', attributes, os);

  String get mimeType {
    return attribute('mime_type');
  }

  String get name {
    return attribute('name');
  }

  int get size {
    return attribute('size');
  }

  String get type {
    return attribute('type');
  }

  String get url {
    return attribute('url');
  }

  String get thumbnailUrl {
    return attribute('thumbnail') ?? attribute('thumbnail_url');
  }
}

class ChatOption extends AbstractModel {
  ChatOption(Map attributes) : super('', attributes);

  String get label {
    return attribute('label');
  }

  bool get selected {
    return attribute('selected');
  }
}

class ChatItem extends AbstractModel {
  ChatItem(String id, Map attrs, [@visibleForTesting String os])
      : super(id, attrs, os);

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(attribute('timestamp'), isUtc: false);

  ChatItemType get type => toChatItemType(attribute('type'));

  String get displayName => attribute('display_name');

  String get message => attribute('msg');

  String get nick => attribute('nick');

  Attachment get attachment {
    dynamic raw = attribute('attachment');
    return (raw != null && raw is Map) ? Attachment(raw) : null;
  }

  bool get unverified {
    if (os() == 'android') {
      return attribute('unverified');
    } else if (os() == 'ios') {
      bool verified = attribute('verified');
      return verified != null ? !verified : null;
    } else {
      return null;
    }
  }

  bool get failed => attribute('failed');

  String get options {
    var raw = attribute('options');
    if (os() == 'android') {
      return raw;
    } else if (os() == 'ios' && raw != null) {
      return raw.join("/");
    } else {
      return null;
    }
  }

  List<ChatOption> get convertedOptions {
    if (os() == 'android') {
      List<dynamic> raw = attribute('converted_options');
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return raw.map((optionAttrs) => ChatOption(optionAttrs)).toList();
    } else if (os() == 'ios') {
      List<ChatOption> out = List();
      var labels = attribute('options');
      if (labels != null) {
        int selectedOptionIndex = attribute('selectedOptionIndex') ?? -1;
        for (var i = 0; i < labels.length; i++) {
          Map optionAttrs = Map<String, dynamic>();
          optionAttrs['label'] = labels[i];
          optionAttrs['selected'] = (i == selectedOptionIndex);
          out.add(ChatOption(optionAttrs));
        }
      }
      return out;
    } else {
      return null;
    }
  }

  int get uploadProgress => attribute('upload_progress');

  ChatRating get rating => toChatRating(attribute('rating'));

  ChatRating get newRating => toChatRating(attribute('new_rating'));

  String get newComment => attribute('new_comment');

  static List<ChatItem> parseChatItemsJsonForAndroid(String json,
      [@visibleForTesting String os]) {
    var out = List<ChatItem>();
    jsonDecode(json).forEach((key, value) {
      out.add(ChatItem(key, value, os));
    });
    return out;
  }

  static List<ChatItem> parseChatItemsJsonForIOS(String json,
      [@visibleForTesting String os]) {
    var out = List<ChatItem>();
    jsonDecode(json).forEach((value) {
      out.add(ChatItem(value['id'], value, os));
    });
    return out;
  }
}
