import 'package:char/firebase/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CharUser {
  late final DocumentReference ref;

  late final String defaultAlias;
  late final List<String> ownedRooms;
  late final List<String> joinedRooms;

  CharUser.id(String id) {
    ref = FirebaseFirestore.instance.doc('users/$id');
  }

  Future<bool> pull({bool createIfNew = true}) async {
    var snapshot = await ref.get().then((value) => value.data() as Map?);
    if (snapshot == null) {
      if (!createIfNew) return false;
      ref.set(snapshot = {
        'name': FirebaseAuth.instance.currentUser?.displayName,
      });
      return true;
    }
    defaultAlias = snapshot['name'];
    ownedRooms = snapshot['ownedRooms'] ?? [];
    joinedRooms = snapshot['ownedRooms'] ?? [];
    return true;
  }

  static Future<CharUser> idAndPull(String id, {bool createIfNew = true}) async {
    final user = CharUser.id(id);
    await user.pull(createIfNew: createIfNew);
    return user;
  }

  Future<List<CharRoom>> getOwnedRooms() => Future.wait(ownedRooms.map((e) => CharRoom.idAndPull(e)));
  Future<List<CharRoom>> getJoinedRooms() => Future.wait(joinedRooms.map((e) => CharRoom.idAndPull(e)));
}
