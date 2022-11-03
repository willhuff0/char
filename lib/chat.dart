import 'package:flutter/material.dart';

class ChatRoomPage extends StatelessWidget {
  const ChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Group name'),
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
      ),
    );
  }
}
