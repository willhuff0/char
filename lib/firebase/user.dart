import 'package:char/firebase/room.dart';
import 'package:char/main.dart';
import 'package:char/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CharUser {
  late final DocumentReference ref;

  late String defaultAlias;
  late final List<String> ownedRooms;
  late final List<String> joinedRooms;

  CharUser.id(String id) {
    ref = FirebaseFirestore.instance.doc('users/$id');
  }

  Future<bool> pull({bool createIfNew = true}) async {
    var snapshot = await ref.get().then((value) async {
      if (value.exists) return value.data() as FirestoreMap?;
      if (!createIfNew) return null;
      final newSnapshot = {
        'name': FirebaseAuth.instance.currentUser?.displayName,
      };
      await ref.set(newSnapshot);
      return newSnapshot;
    });
    if (snapshot == null) return false;
    defaultAlias = snapshot['name'] as String;
    ownedRooms = (snapshot['ownedRooms'] as List?)?.cast() ?? [];
    joinedRooms = (snapshot['joinedRooms'] as List?)?.cast() ?? [];
    return true;
  }

  static Future<CharUser?> idAndPull(String id, {bool createIfNew = false}) async {
    final user = CharUser.id(id);
    await user.pull(createIfNew: createIfNew);
    return user;
  }

  Future<List<CharRoom>> getOwnedRooms() => Future.wait(ownedRooms.map((e) => CharRoom.idAndPull(e)).toList());
  Future<List<CharRoom>> getJoinedRooms() => Future.wait(joinedRooms.map((e) => CharRoom.idAndPull(e)).toList());

  Future<void> push({String? defaultAlias}) => ref.update({
        if (defaultAlias != null) 'name': this.defaultAlias = defaultAlias,
      });

  FirebaseImage getImage({String? fallbackUrl}) => FirebaseImage('users/${ref.id}/icon.jpg', fallbackUrl: fallbackUrl);
}
