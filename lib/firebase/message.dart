import 'dart:async';

import 'package:char/firebase/room.dart';
import 'package:char/firebase/user.dart';
import 'package:char/main.dart';
import 'package:char/profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class CharMessage {
  final int timestamp;
  final String from;
  final Set<String> seen;

  Widget buildWidget(BuildContext context, {bool isFromSelf = false});
  String getTextDescription(CharRoom room);

  CharMessage(this.from, {int? timestamp, List<String> seen = const []})
      : seen = seen.toSet(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  FirestoreMap toMap({bool includeTimestamp = false}) => {
        'from': from,
        if (includeTimestamp) 'timestamp': timestamp,
        'seen': seen.toList(),
      };

  static FutureOr<CharMessage> fromMapTimestamp(FirestoreMap data, {bool pull = true}) => fromMap(data['timestamp'] as int? ?? 0, data, pull: pull);
  static FutureOr<CharMessage> fromMap(int timestamp, FirestoreMap data, {bool pull = true}) {
    if (data.containsKey('text')) {
      return CharTextMessage(
        data['from'] as String,
        data['text'] as String,
        timestamp: timestamp,
        seen: (data['seen'] as List?)?.cast() ?? [],
      );
    }
    if (data.containsKey('info')) {
      return CharSystemMessage(
        data['from'] as String,
        info: data['info'] as String?,
        timestamp: timestamp,
        seen: (data['seen'] as List?)?.cast() ?? [],
      );
    }
    // if (data.containsKey('data')) {
    //   return CharAttachmentMessage(
    //     data['from'] as String,
    //     data: pull ? base64.decode(data['data'] as String) : null,
    //     label: data['label'],
    //   );
    // }
    if (data.containsKey('url')) {
      if (pull && data['path'] != null && data['url'] == null) {
        return FirebaseStorage.instance.ref(data['url'] as String).getDownloadURL().then((url) => CharAttachmentMessage(
              data['from'] as String,
              path: data['path'] as String?,
              label: data['label'] as String?,
              url: url,
              timestamp: timestamp,
              seen: (data['seen'] as List?)?.cast() ?? [],
            ));
      }
      return CharAttachmentMessage(
        data['from'] as String,
        path: data['path'] as String?,
        label: data['label'] as String?,
        url: data['url'] as String?,
        timestamp: timestamp,
        seen: (data['seen'] as List?)?.cast() ?? [],
      );
    }
    throw Exception('Couldn\'t interpret CharMessage.');
  }
}

class CharSystemMessage extends CharMessage {
  final String? info;

  CharSystemMessage(super.from, {this.info, super.timestamp, super.seen});

  @override
  Widget buildWidget(BuildContext context, {bool isFromSelf = false}) {
    return CharMessageCard(
      isFromSelf: false,
      isFromSystem: true,
      child: Text(info ?? ''),
    );
  }

  @override
  String getTextDescription(CharRoom room) => 'Char said: $info';

  @override
  FirestoreMap toMap({bool includeTimestamp = false}) => super.toMap(includeTimestamp: includeTimestamp)
    ..addAll({
      if (info != null) 'info': info,
    });
}

class CharTextMessage extends CharMessage {
  final String text;

  CharTextMessage(super.from, this.text, {super.timestamp, super.seen});

  @override
  Widget buildWidget(BuildContext context, {bool isFromSelf = false}) {
    return CharMessageCard(
      isFromSelf: isFromSelf,
      child: Text(text),
    );
  }

  @override
  String getTextDescription(CharRoom room) => '${room.lookupAlias(from)} said: $text';

  @override
  FirestoreMap toMap({bool includeTimestamp = false}) => super.toMap(includeTimestamp: includeTimestamp)
    ..addAll({
      'text': text,
    });
}

class CharAttachmentMessage extends CharMessage {
  @Deprecated('Prefer storing byte data outside the database.')
  final Uint8List? data;
  final String? url;
  final String? path;
  final String? label;

  CharAttachmentMessage(super.from, {this.data, this.url, this.path, this.label, super.timestamp, super.seen});

  @override
  Widget buildWidget(BuildContext context, {bool isFromSelf = false}) {
    return CharMessageCard(
      isFromSelf: isFromSelf,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (path != null) Image(image: FirebaseImage(path!, fallbackUrl: url)),
          if (url != null) Image.network(url!),
          if (data != null) Image.memory(data!),
          if (label != null) ...[
            SizedBox(height: 4.0),
            Text('Label'),
          ],
        ],
      ),
    );
  }

  @override
  String getTextDescription(CharRoom room) => label == null ? '(Example AI guess) ${room.lookupAlias(from)} sent a picture of a banana.' : '${room.lookupAlias(from)} said: $label';
  // '$from sent an image containing ...'
  // '$from sent a pixel art image containing ...'

  @override
  FirestoreMap toMap({bool includeTimestamp = false}) => super.toMap(includeTimestamp: includeTimestamp)
    ..addAll({
      if (data != null) 'data': data,
      if (url != null) 'url': url,
      if (path != null) 'path': path,
      if (label != null) 'label': label,
    });
}

class CharMessageCard extends StatefulWidget {
  final bool isFromSelf;
  final bool isFromSystem;
  final Widget child;

  const CharMessageCard({required this.isFromSelf, this.isFromSystem = false, required this.child, super.key});

  @override
  State<CharMessageCard> createState() => _CharMessageCardState();
}

class _CharMessageCardState extends State<CharMessageCard> {
  bool extend = false;

  @override
  Widget build(BuildContext context) {
    final child = Card(
      margin: EdgeInsets.zero,
      color: widget.isFromSelf || widget.isFromSystem ? brandColor : null,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget.child,
      ),
    );
    return GestureDetector(
      onLongPressStart: (details) {
        setState(() => extend = true);
      },
      onLongPressEnd: (details) {
        setState(() => extend = false);
      },
      onLongPressCancel: () {
        setState(() => extend = false);
      },
      onLongPressUp: () {
        setState(() => extend = false);
      },
      child: Padding(
        padding: EdgeInsets.only(
          top: 2.0,
          bottom: 2.0,
          left: widget.isFromSelf ? 24.0 : 8.0,
          right: !widget.isFromSelf ? 24.0 : 8.0,
        ),
        child: AnimatedAlign(
          alignment: extend ? Alignment.center : Alignment.topRight,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          // width: extend ? 1000.0 : 24.0,
          // decoration: BoxDecoration(
          //   color: Theme.of(context).colorScheme.secondaryContainer,
          //   borderRadius: BorderRadius.circular(12.0),
          // ),
          child: child,
        ),
      ),
    );
  }
}
