import 'dart:async';

import 'package:char/firebase/message.dart';
import 'package:char/firebase/room.dart';
import 'package:char/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final CharRoom room;

  const ChatRoomPage({required this.room, super.key});

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
    _controller.dispose();
    _messageChangesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  centerTitle: false,
                  title: Text(widget.room.name),
                  shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final message = messages[index];
                    return message!.buildWidget();
                  }, childCount: messages.length),
                ),
              ],
            ),
          ),
          Material(
            elevation: 2.0,
            color: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            child: SafeArea(
              top: false,
              child: Container(
                height: 70.0,
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.text,
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
                            widget.room.
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
