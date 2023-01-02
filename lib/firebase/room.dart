import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CharRoom {
  late final DocumentReference ref;

  late final String name, owner;
  late final Map<String, RoomMemberSettings> members;
  late final RoomSettings settings;

  CharRoom.id(String id) {
    ref = FirebaseFirestore.instance.doc('rooms/$id');
  }

  Future pull() async {
    final snapshot =
        await ref.get().then((value) => value.data()! as Map<String, Object?>);
    name = snapshot['name'] as String;
    owner = snapshot['owner'] as String;
    members = (snapshot['members'] as Map<String, Map<String, Object?>>)
        .map((k, v) => MapEntry(k, RoomMemberSettings.fromMap(v)));
    settings = RoomSettings.fromMap(
        this, snapshot['settings'] as Map<String, Object?>? ?? {});
  }

  static Future<CharRoom> idAndPull(String id) async {
    final room = CharRoom.id(id);
    await room.pull();
    return room;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get messagesStream =>
      ref.collection('messages').snapshots();

  // Future<List<CharMessage>> getMessages(DocumentSnapshot startAfter, int count) async {
  //   final snapshot = await ref.collection('messages').startAfterDocument(startAfter).limit(count).get();
  //   return snapshot.docs.map((e) => CharMessage.fromMap(e.data())).toList();
  // }

  //Stream<CharMessage> getMessages() {}
}

class RoomMemberSettings {
  late final String alias;
  late final int notificationOption;

  RoomMemberSettings.fromMap(Map<String, Object?> data) {
    alias = data['alias'] as String;
    notificationOption = data['notify'] as int? ?? 0;
  }
}

class RoomSettings {
  late final CharRoom room;
  late final Color color;
  late final MessageLifetimeMode messageLifetimeMode;

  RoomSettings.fromMap(this.room, Map<String, Object?> data) {
    color = _colorFromJson(data['color'] as int? ?? 0xFFFFFFFF);
    messageLifetimeMode =
        MessageLifetimeMode.values[data['messageLifetime'] as int? ?? 0];
  }
}

enum MessageLifetimeMode {
  afterViewed,
  hours24,
}

int _colorToJson(Color value) => value.value;
Color _colorFromJson(int value) => Color(value);
