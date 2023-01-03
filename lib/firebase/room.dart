import 'package:char/firebase/message.dart';
import 'package:char/firebase/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CharRoom {
  late final DocumentReference ref;

  late final String name, owner;
  late final Map<String, RoomMemberSettings> members;
  late final List<String>? invites;
  late final RoomSettings settings;
  late CharMessage? lastMessage;

  CharRoom._create({required this.name, required this.owner, required this.members, this.invites, required this.settings, this.lastMessage});

  CharRoom.id(String id) {
    ref = FirebaseFirestore.instance.doc('rooms/$id');
  }

  Future pull() async {
    final snapshot = await ref.get().then((value) => value.data()! as Map);
    name = snapshot['name'];
    owner = snapshot['owner'];
    members = (snapshot['members'] as List).map((e) => RoomMemberSettings.fromMap(e)).toList();
    lastMessage = snapshot['last'] == null ? null : await CharMessage.fromMap(snapshot['last'], pull: false);
    settings = RoomSettings.fromMap(this, snapshot['settings']);
  }

  static Future<CharRoom> idAndPull(String id) async {
    final room = CharRoom.id(id);
    await room.pull();
    return room;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get messagesStream => ref.collection('messages').snapshots();
  Future<void> sendMessage

  static Future<CharRoom> create(CharUser owner, String name, {List<String>? invites}) async {
    final room = CharRoom._create(
      name: name,
      owner: owner.ref.id,
      members: [RoomMemberSettings._(alias: owner.defaultAlias, notificationOption: 0)],
      invites: invites,
      settings: RoomSettings._(),
    );
    room.settings.room = room;

    room.ref = await FirebaseFirestore.instance.collection('rooms').add({
      'name': room.name,
      'owner': room.owner,
      'members': room.members.map((e) => e.toMap()).toList(),
      if (room.invites != null) 'invites': room.invites,
    });

    return room;
  }

  // Future<List<CharMessage>> getMessages(DocumentSnapshot startAfter, int count) async {
  //   final snapshot = await ref.collection('messages').startAfterDocument(startAfter).limit(count).get();
  //   return snapshot.docs.map((e) => CharMessage.fromMap(e.data())).toList();
  // }

  //Stream<CharMessage> getMessages() {}
}

class RoomMemberSettings {
  late final String alias;
  late final int notificationOption;

  RoomMemberSettings._({required this.alias, required this.notificationOption});

  RoomMemberSettings.fromMap(Map data) {
    alias = data['alias'];
    notificationOption = data['notify'];
  }

  Map<String, dynamic> toMap() => {
        'alias': alias,
        'notify': notificationOption,
      };
}

class RoomSettings {
  late final CharRoom room;
  late final Color color;
  late final MessageLifetimeMode messageLifetimeMode;

  RoomSettings._();

  RoomSettings.fromMap(this.room, Map? data) {
    data ??= {};
    color = _colorFromJson(data['color'] ?? 0xFFFFFFFF);
    messageLifetimeMode = MessageLifetimeMode.values[data['messageLifetime'] ?? 0];
  }
}

enum MessageLifetimeMode {
  afterViewed,
  hours24,
}

int _colorToJson(Color value) => value.value;
Color _colorFromJson(int value) => Color(value);
