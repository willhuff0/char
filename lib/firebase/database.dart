import 'package:cloud_firestore/cloud_firestore.dart';

late final CollectionReference usersCollection;
late final CollectionReference roomsCollection;

void initDatabase() {
  usersCollection = FirebaseFirestore.instance.collection('users');
  roomsCollection = FirebaseFirestore.instance.collection('rooms');
}
