import 'package:char/firebase/room.dart';
import 'package:char/firebase/user.dart';
import 'package:char/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final User user;

  const Home({required this.user, super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final Future future;
  late final CharUser user;
  late final List<CharRoom> rooms;

  @override
  void initState() {
    future = CharUser.idAndPull(widget.user.uid, createIfNew: true).then((value) async {
      user = value!;
      rooms = await user.getJoinedRooms();
      if (mounted) setState(() {});
    }).then((value) => true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: false,
        future: future,
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Scaffold(
              appBar: AppBar(
                toolbarHeight: 64,
                shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
                leadingWidth: 82.0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                leading: Center(child: Text('Char', style: Theme.of(context).textTheme.titleLarge)),
                title: isDesktop
                    ? Padding(
                        padding: const EdgeInsets.only(right: 24, top: 10, bottom: 10),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 500.0, maxWidth: 500.0),
                          child: Center(child: CharSearchBar()),
                        ),
                      )
                    : null,
                actions: [
                  SizedBox(
                    height: 64.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDesktop) ...[
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('search');
                            },
                            icon: Icon(Icons.search),
                            constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0),
                          ),
                          SizedBox(width: 4.0),
                        ],
                        IconButton(onPressed: () {}, icon: Icon(Icons.settings), constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0)),
                        SizedBox(width: 4.0),
                        IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, 'profile', arguments: user);
                            },
                            icon: Icon(Icons.person),
                            constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0)),
                        SizedBox(width: 14.0),
                      ],
                    ),
                  ),
                ],
              ),
              body: ListView(
                padding: EdgeInsets.all(14.0),
                children: rooms
                    .map((e) => ListTile(
                          contentPadding: EdgeInsets.all(7.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                          title: Text(e.name),
                          subtitle: e.lastMessage == null ? null : Text(e.lastMessage!.accessibilityText),
                          leading: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: CircleAvatar(),
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, 'chat', arguments: e);
                          },
                        ))
                    .toList(),
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () async {
                  final result = await showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return BottomSheet(
                            onClosing: () {},
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            minLines: 1,
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                              hintText: 'Add members to new room',
                                            ),
                                            keyboardType: TextInputType.name,
                                          ),
                                        ),
                                        SizedBox(width: 14.0),
                                        FloatingActionButton(
                                          onPressed: () async {
                                            final room = await CharRoom.create(user, 'bruh');
                                            Navigator.pop(context, room);
                                          },
                                          child: Icon(Icons.navigate_next),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            });
                      });
                  if (result != null) {
                    final id = result.ref.id;
                    user.ref.update({
                      'ownedRooms': FieldValue.arrayUnion([id]),
                      'joinedRooms': FieldValue.arrayUnion([id]),
                    });
                    setState(() {
                      rooms.add(result);
                      user.ownedRooms.add(id);
                      user.joinedRooms.add(id);
                    });
                  }
                },
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class CharSearchBar extends StatelessWidget {
  final bool focused;

  const CharSearchBar({
    this.focused = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: focused,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(999.9)),
        fillColor: Colors.black26,
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
        filled: true,
        hintText: 'Search Char',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        hoverColor: Colors.black12,
        prefixIcon: Center(child: Icon(Icons.search, size: 20.0)),
        prefixIconConstraints: BoxConstraints(minWidth: 45.0, maxWidth: 45.0),
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6.0,
            vertical: 2.0,
          ),
          child: IconButton(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

class HomeSearchPage extends StatelessWidget {
  const HomeSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
        centerTitle: true,
        title: CharSearchBar(focused: true),
      ),
    );
  }
}
