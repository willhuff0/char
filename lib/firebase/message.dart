import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class CharMessage {
  final String from;

  Widget buildWidget();
  String get accessibilityText;
  //String get subtitleText;

  CharMessage(this.from);

  static Future<CharMessage> fromMap(Map data, {bool pull = true}) async {
    if (data.containsKey('text')) return CharTextMessage(data['from'], data['text']);
    if (data.containsKey('info')) return CharSystemMessage(data['from'], info: data['info']);
    if (data.containsKey('url')) {
      return CharAttachmentMessage(
        data['from'],
        url: pull ? await FirebaseStorage.instance.ref(data['url']).getDownloadURL() : null,
        label: data['label'],
      );
    }
    if (data.containsKey('data')) {
      return CharAttachmentMessage(
        data['from'],
        data: pull ? base64.decode(data['data']) : null,
        label: data['label'],
      );
    }
    throw Exception('Couldn\'t interpret CharMessage.');
  }
}

class CharSystemMessage extends CharMessage {
  final String? info;

  CharSystemMessage(super.from, {this.info});

  @override
  Widget buildWidget() {
    return ListTile(
      subtitle: info != null ? Text(info!) : null,
      dense: true,
    );
  }

  @override
  String get accessibilityText => info ?? 'A system message.';
}

class CharTextMessage extends CharMessage {
  final String text;

  CharTextMessage(super.from, this.text);

  @override
  Widget buildWidget() {
    return ListTile(title: Text(text));
  }

  @override
  String get accessibilityText => '$from sent a message.';
}

class CharAttachmentMessage extends CharMessage {
  final Uint8List? data;
  final String? url;
  final String? label;

  CharAttachmentMessage(super.from, {this.data, this.url, this.label});

  @override
  Widget buildWidget() {
    return ListTile(
      title: url != null
          ? Image.network(url!)
          : data != null
              ? Image.memory(data!)
              : Text(label!),
    );
  }

  @override
  String get accessibilityText => label == null ? '$from sent an attachment.' : '$from sent $label.';
}
