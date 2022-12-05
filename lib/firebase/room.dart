import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Room {
  late final DatabaseReference ref;

  late final String name, owner;
  late final List<String> aliases;
  late final RoomSettings settings;

  Room.id(String id) {
    ref = FirebaseDatabase.instance.ref('groups/$id');
  }

  Future pull() async {
    final snapshot = await ref.get().then((value) => value.data()! as Map);
    name = snapshot['name'];
    owner = snapshot['owner'];
    aliases = (snapshot['aliases'] as List).cast();
    settings = RoomSettings.fromMap(this, snapshot['settings']);
  }

  // Future<List<CharMessage>> getMessages(DocumentSnapshot startAfter, int count) async {
  //   final snapshot = await ref.collection('messages').startAfterDocument(startAfter).limit(count).get();
  //   return snapshot.docs.map((e) => CharMessage.fromMap(e.data())).toList();
  // }

  //Stream<CharMessage> getMessages() {}
}

class RoomSettings {
  late final Room room;
  late final Color color;
  late final MessageLifetimeMode messageLifetimeMode;

  RoomSettings.fromMap(this.room, Map data) {
    color = _colorFromJson(data['color']);
    messageLifetimeMode = MessageLifetimeMode.values[data['messageLifetime']];
  }
}

enum MessageLifetimeMode {
  afterViewed,
  hours24,
}

int _colorToJson(Color value) => value.value;
Color _colorFromJson(int value) => Color(value);

class CharMessage {
  late final String? message;
  late final Uri? attachment;

  CharMessage.fromMap(Map data) {
    message = data['message'];
    if (data['attachment'] != null) attachment = Uri.tryParse(data['attachment']);
  }
  CharMessage.fromString(String data) {
    message = data;
  }

  CharMessage([this.message, this.attachment]);
}
