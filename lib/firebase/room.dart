import 'dart:async';

import 'package:char/firebase/message.dart';
import 'package:char/firebase/user.dart';
import 'package:char/main.dart';
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
    _setFromMap(await ref.get().then((value) => value.data()! as FirestoreMap));
  }

  Future _setFromMap(FirestoreMap snapshot) async {
    name = snapshot['name'] as String;
    owner = snapshot['owner'] as String;
    members = (snapshot['members'] as FirestoreMap).map((k, v) => MapEntry(k, RoomMemberSettings.fromMap(v as FirestoreMap)));
    lastMessage = snapshot['last'] == null ? null : await CharMessage.fromMapTimestamp(snapshot['last'] as FirestoreMap, pull: false);
    settings = RoomSettings.fromMap(this, snapshot['settings'] as FirestoreMap?);
  }

  static Future<CharRoom> idAndPull(String id) async {
    final room = CharRoom.id(id);
    await room.pull();
    return room;
  }

  late StreamSubscription _syncSubscription;
  void beginSync(void Function(DocumentSnapshot<Object?>) onSnapshot) {
    _syncSubscription = ref.snapshots().listen((snapshot) {
      _setFromMap(snapshot.data() as FirestoreMap);
      onSnapshot(snapshot);
    });
  }

  void endSync() {
    _syncSubscription.cancel();
  }

  String? lookupAlias(String id) => members[id]?.alias;

  Stream<QuerySnapshot<Map<String, dynamic>>> get snapshots => ref.collection('messages').snapshots();
  Stream<CharMessage> getLatestMessage() => ref.snapshots().expand((snapshot) {
        final lastMessage = (snapshot.data() as FirestoreMap)['last'] as FirestoreMap?;
        if (lastMessage == null) return [];
        return [CharMessage.fromMapTimestamp(lastMessage, pull: false) as CharMessage];
      });

  //Stream<CharMessage> getLatestMessage() => ref.collection('messages').snapshots().map((snapshot) => CharMessage.fromMap(snapshot.docs.first.data(), pull: false) as CharMessage);

  //Future<void> sendMessage

  static Future<CharRoom> create(CharUser owner, String name, {List<String>? invites}) async {
    final room = CharRoom._create(
      name: name,
      owner: owner.ref.id,
      members: {
        owner.ref.id: RoomMemberSettings._(alias: owner.defaultAlias, notificationOption: 0),
      },
      invites: invites,
      settings: RoomSettings._(),
    );
    room.settings.room = room;

    room.ref = await FirebaseFirestore.instance.collection('rooms').add({
      'name': room.name,
      'owner': room.owner,
      'members': room.members.map((k, v) => MapEntry(k, v.toMap())),
      if (room.invites != null) 'invites': room.invites,
    });

    return room;
  }

  Future<void> pushMessage(CharMessage message) async {
    final messageMap = message.toMap();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(ref.collection('messages').doc(message.timestamp.toString()), messageMap);
    batch.update(ref, {
      'last': {...messageMap, 'timestamp': message.timestamp}
    });
    await batch.commit();
  }

  Future<void> editMessage(String id, FirestoreMap update) async {}

  Future<void> deleteMessage(String id) async {}
}

class RoomMemberSettings {
  late final String alias;
  late final int notificationOption;

  RoomMemberSettings._({required this.alias, required this.notificationOption});

  RoomMemberSettings.fromMap(FirestoreMap data) {
    alias = data['alias'] as String;
    notificationOption = data['notify'] as int? ?? 0;
  }

  FirestoreMap toMap() => {
        'alias': alias,
        'notify': notificationOption,
      };
}

class RoomSettings {
  late final CharRoom room;
  late final Color color;
  late final MessageLifetimeMode messageLifetimeMode;

  // room.settings.room = room;
  RoomSettings._();

  RoomSettings.fromMap(this.room, FirestoreMap? data) {
    data ??= {};
    color = _colorFromJson(data['color'] as int? ?? brandColor.value);
    messageLifetimeMode = MessageLifetimeMode.values[data['messageLifetime'] as int? ?? 0];
  }
}

enum MessageLifetimeMode {
  afterViewed,
  hours24,
}

int _colorToJson(Color value) => value.value;
Color _colorFromJson(int value) => Color(value);
