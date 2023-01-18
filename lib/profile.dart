import 'dart:ui' as ui;

import 'package:char/firebase/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final CharUser user;

  const ProfilePage({required this.user, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
        leadingWidth: 82.0,
        centerTitle: true,
        title: Text('Profile'),
      ),
      body: ListView(
        padding: EdgeInsets.all(18.0),
        children: [
          Container(
            width: 152.0,
            height: 152.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.user.getImage(fallbackUrl: FirebaseAuth.instance.currentUser?.photoURL),
                fit: BoxFit.fitHeight,
              ),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 24.0),
          CharEditableTextField(
            title: Row(
              children: [
                Text('Default alias'),
                SizedBox(width: 4.0),
              ],
            ),
            initialText: widget.user.defaultAlias,
            onSave: (value) async {
              final previous = widget.user.defaultAlias;
              await widget.user.push(defaultAlias: value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Default alias updated!'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () async {
                      await widget.user.push(defaultAlias: previous);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24.0),
          ElevatedButton(
            style: ButtonStyle(
              shadowColor: MaterialStatePropertyAll(Colors.transparent),
            ),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
            child: Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class CharEditableTextField extends StatefulWidget {
  final Widget title;
  final String initialText;
  final void Function(String value) onSave;

  const CharEditableTextField({required this.title, required this.initialText, required this.onSave, super.key});

  @override
  State<CharEditableTextField> createState() => _CharEditableTextFieldState();
}

class _CharEditableTextFieldState extends State<CharEditableTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String text;
  var isEditing = false;

  @override
  void initState() {
    text = widget.initialText;
    _controller = TextEditingController(text: text);
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 90.0,
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: EdgeInsets.all(14.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.title,
                DefaultTextStyle(
                  style: TextStyle(fontSize: 18.0),
                  child: Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: isEditing
                          ? TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _controller.text = text;
                                    setState(() => isEditing = false);
                                  },
                                  icon: Icon(Icons.restore),
                                ),
                              ),
                            )
                          : Text(text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.0),
          isEditing
              ? FilledButton(
                  onPressed: () {
                    if (text != _controller.text) widget.onSave(_controller.text);
                    setState(() {
                      isEditing = !isEditing;
                      text = _controller.text;
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0))),
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                  ),
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: Icon(Icons.done),
                  ),
                )
              : FilledButton.tonal(
                  onPressed: () {
                    _focusNode.requestFocus();
                    setState(() {
                      isEditing = !isEditing;
                      text = _controller.text;
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0))),
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                  ),
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: Icon(Icons.edit),
                  ),
                ),
        ],
      ),
    );
  }
}

class FirebaseImage extends ImageProvider<FirebaseImage> {
  final String ref;
  final String? fallbackUrl;
  final double scale;

  const FirebaseImage(this.ref, {this.fallbackUrl, this.scale = 1.0});

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(FirebaseImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'FirebaseImage(${describeIdentity(key.ref)})',
    );
  }

  Future<ui.Codec> _loadAsync(FirebaseImage key, DecoderBufferCallback decode) async {
    assert(key == this);
    Uint8List? bytes;
    try {
      bytes = await FirebaseStorage.instance.ref(ref).getData();
    } catch (e) {
      bytes = null;
    }
    if (bytes == null) {
      if (fallbackUrl == null) throw Exception('FirebaseImage couldn\'t resolve reference and no fallback url was provided');
      bytes = await http.get(Uri.parse(fallbackUrl!)).then((value) => value.bodyBytes);
      print(fallbackUrl);
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes!));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FirebaseImage && other.ref == ref && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(ref.hashCode, scale);
}
