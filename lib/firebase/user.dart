import 'package:char/firebase/room.dart';
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

  Future<bool> pull({bool createIfNew = false}) async {
    final snapshot = await ref.get();
    late Map<String, dynamic> data;
    if (!snapshot.exists) {
      if (!createIfNew) return false;
      await ref.set(data = {
        'name': FirebaseAuth.instance.currentUser!.displayName,
      });
    } else {
      data = snapshot.data()! as Map<String, dynamic>;
    }
    defaultAlias = data['name'];
    ownedRooms = data['ownedRooms']?.cast<String>() ?? [];
    joinedRooms = data['ownedRooms']?.cast<String>() ?? [];
    return true;
  }

  static Future<CharUser?> idAndPull(String id, {bool createIfNew = false}) async {
    final user = CharUser.id(id);
    await user.pull(createIfNew: createIfNew);
    return user;
  }

  Future<List<CharRoom>> getOwnedRooms() => Future.wait(ownedRooms.map((e) => CharRoom.idAndPull(e)));
  Future<List<CharRoom>> getJoinedRooms() => Future.wait(joinedRooms.map((e) => CharRoom.idAndPull(e)));

  Future<void> push({String? defaultAlias}) => ref.update({
        if (defaultAlias != null) 'name': this.defaultAlias = defaultAlias,
      });

  FirebaseImage getImage({String? fallbackUrl}) => FirebaseImage('users/${ref.id}/icon.jpg', fallbackUrl: fallbackUrl);
}
