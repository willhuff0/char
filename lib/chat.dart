import 'dart:async';

import 'package:char/firebase/message.dart';
import 'package:char/firebase/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final CharRoom room;

  const ChatRoomPage({required this.room, super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late final StreamSubscription _messageChangesSubscription;

  final messages = <int, CharMessage>{};

  @override
  void initState() {
    _messageChangesSubscription = widget.room.messagesStream.listen((event) async {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            messages[change.newIndex] = await CharMessage.fromMap(change.doc.data()!);
            break;
          case DocumentChangeType.modified:
            messages[change.newIndex] = await CharMessage.fromMap(change.doc.data()!);
            break;
          case DocumentChangeType.removed:
            messages.remove(change.oldIndex);
            break;
        }
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _messageChangesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.room.name),
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
      ),
    );
  }
}
