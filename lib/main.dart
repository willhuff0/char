import 'package:char/chat.dart';
import 'package:char/firebase/room.dart';
import 'package:char/firebase/user.dart';
import 'package:char/firebase_options.dart';
import 'package:char/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home.dart';

const useEmulators = true;

late bool isDesktop;

void main() {
  //if (kIsWeb) usePathUrlStrategy();
  runApp(App());
}

void checkRedirectLogin() async {
  try {
    final result = await FirebaseAuth.instance.getRedirectResult();
    if (result.user != null) {
      await result.user!.reload();
    }
  } finally {}
}

const brandColor = Color(0xFF3CA533);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final future = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((value) async {
      if (useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
        FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
        await FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
      }
      return true;
    });
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: brandColor,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: brandColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: lightColorScheme.background,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: darkColorScheme.background,
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case null:
              case '/':
                return MaterialPageRoute(
                    builder: (context) => LayoutBuilder(builder: (context, constraints) {
                          isDesktop = constraints.maxWidth > 600;
                          return FutureBuilder(
                            initialData: false,
                            future: future,
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return StreamBuilder(
                                  stream: FirebaseAuth.instance.authStateChanges(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      print('Logged in ${snapshot.data!.email}.');
                                      return Home(user: snapshot.data!);
                                    }
                                    print('Logged out.');
                                    return Landing();
                                  },
                                );
                              }
                              return Scaffold(body: Center(child: CircularProgressIndicator()));
                            },
                          );
                        }));
              case 'search':
                return MaterialPageRoute(builder: (context) => HomeSearchPage());
              case 'chat':
                if (settings.arguments != null) return MaterialPageRoute(builder: (context) => ChatRoomPage(room: settings.arguments as CharRoom));
                return null;
              case 'profile':
                if (settings.arguments != null) return MaterialPageRoute(builder: (context) => ProfilePage(user: settings.arguments as CharUser));
                return null;
            }
          },
        );
      },
    );
  }
}

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  var loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          final children = [
            Text('Char', style: TextStyle(fontSize: 28.0)),
            ...isDesktop
                ? [
                    SizedBox(width: 24.0),
                    SizedBox(height: 60, child: VerticalDivider()),
                    SizedBox(width: 24.0)
                  ]
                : [SizedBox(height: 24.0)],
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        if (kIsWeb) {
                          final provider = GoogleAuthProvider()
                            ..scopes.addAll(['profile', 'email']);

                          await FirebaseAuth.instance.signInWithPopup(provider);
                          return;
                        }

                        final googleUser = await GoogleSignIn().signIn();
                        final googleAuth = await googleUser?.authentication;
                        if (googleAuth != null) {
                          final credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );
                          await FirebaseAuth.instance
                              .signInWithCredential(credential);
                        }
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.all(22.0)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0))),
              ),
              child: Text('Sign in with Google'),
            ),
          ];
          return isDesktop
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                );
        }),
      ),
    );
  }
}
