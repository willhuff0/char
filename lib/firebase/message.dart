import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class CharMessage {
  Widget buildWidget();

  static Future<CharMessage> fromMap(Map data) async {
    if (data.containsKey('text')) return CharTextMessage(data['text']);
    if (data.containsKey('info')) return CharSystemMessage(info: data['info']);
    if (data.containsKey('url')) return CharAttachmentMessage(url: await FirebaseStorage.instance.ref(data['url']).getDownloadURL());
    if (data.containsKey('data')) return CharAttachmentMessage(data: base64.decode(data['data']));
    throw Exception();
  }
}

class CharSystemMessage extends CharMessage {
  final String? info;

  CharSystemMessage({this.info});

  @override
  Widget buildWidget() {
    return ListTile(
      subtitle: info != null ? Text(info!) : null,
      dense: true,
    );
  }
}

class CharTextMessage extends CharMessage {
  final String text;

  CharTextMessage(this.text);

  @override
  Widget buildWidget() {
    return ListTile(title: Text(text));
  }
}

class CharAttachmentMessage extends CharMessage {
  final Uint8List? data;
  final String? url;

  CharAttachmentMessage({this.data, this.url});

  @override
  Widget buildWidget() {
    return ListTile(
      title: url != null
          ? Image.network(url!)
          : data != null
              ? Image.memory(data!)
              : throw Exception('No data.'),
    );
  }
}
