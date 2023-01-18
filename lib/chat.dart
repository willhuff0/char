import 'dart:async';

import 'package:char/firebase/message.dart';
import 'package:char/firebase/room.dart';
import 'package:char/firebase/user.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final CharUser user;
  final CharRoom room;

  const ChatRoomPage({required this.user, required this.room, super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late final TextEditingController _controller;
  late final StreamSubscription _messageChangesSubscription;

  final messages = <int, CharMessage>{};

  @override
  void initState() {
    _controller = TextEditingController();
    _messageChangesSubscription = widget.room.snapshots.listen((event) async {
      for (var change in event.docChanges) {
        final timestamp = int.parse(change.doc.id);
        switch (change.type) {
          case DocumentChangeType.added:
            messages[timestamp] = await CharMessage.fromMap(timestamp, change.doc.data()!);
            break;
          case DocumentChangeType.modified:
            messages[timestamp] = await CharMessage.fromMap(timestamp, change.doc.data()!);
            break;
          case DocumentChangeType.removed:
            messages.remove(timestamp);
            break;
        }
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageChangesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMessages = messages.values.toList();
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.room.name),
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
      ),
      body: Column(
        children: [
          SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemBuilder: (context, index) {
                final previousMessage = index == messages.length - 1 ? null : currentMessages[(messages.length - 2) - index];
                final message = currentMessages[(messages.length - 1) - index];
                return Padding(
                  padding: EdgeInsets.only(
                    top: previousMessage != null
                        ? message.timestamp > previousMessage.timestamp + 2 * 60 * 1000
                            ? 10.0
                            : 0.0
                        : 0.0,
                  ),
                  child: message.buildWidget(context, isFromSelf: message.from == widget.user.ref.id),
                );
              },
              itemCount: messages.length,
            ),
          ),
          Material(
            elevation: 2.0,
            color: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            child: SafeArea(
              top: false,
              child: Container(
                height: 60.0,
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.newline,
                  //keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(999.9)),
                    fillColor: Colors.black26,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
                    filled: true,
                    hintText: 'Send message',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    hoverColor: Colors.black12,
                    //prefixIcon: Center(child: Icon(Icons.search, size: 20.0)),
                    //prefixIconConstraints: BoxConstraints(minWidth: 45.0, maxWidth: 45.0),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.symmetric(horizontal: 14.0),
                        icon: Icon(Icons.send),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            widget.room.pushMessage(CharTextMessage(widget.user.ref.id, _controller.text));
                            _controller.clear();
                            //setState(() => _controller.clear());
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
