import 'package:char/firebase/database.dart';
import 'package:char/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Room {
  late final DocumentReference ref;

  late final String name, owner;
  late final List<String> aliases;

  Room.id(String id) {
    ref = roomsCollection.doc(id);
  }

  Future pull() async {
    final snapshot = await ref.get().then((value) => value.data()! as Map);
    name = snapshot['name'];
    owner = snapshot['owner'];
    aliases = (snapshot['aliases'] as List).cast();
  }

  RoomSettings getSettings() => RoomSettings.ref('${ref.path}/settings');
}

class RoomSettings {
  late final DocumentReference ref;

  late final Color color;
  late final MessageLifetimeMode messageLifetimeMode;

  RoomSettings.ref(this.ref);

  Future pull() async {
    final data = await ref.get().then((value) => value.data()! as Map);
    color = data['color'] ?? brandColor;
    messageLifetimeMode = data['messageLifetimeMode'] ?? MessageLifetimeMode.afterViewed;
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
