import 'package:char/chat.dart';
import 'package:char/firebase/room.dart';
import 'package:char/firebase_options.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home.dart';

late bool isDesktop;

void main() {
  //if (kIsWeb) usePathUrlStrategy();
  runApp(App());
}

const brandColor = Color(0xFF3CA533);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final future = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((value) => true);
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
          routes: {
            'search': (context) => HomeSearchPage(),
            'chat': (context) => ChatRoomPage(room: CharRoom.id('lFWv9JWENFPeNpmI1quX')),
          },
          home: LayoutBuilder(builder: (context, constraints) {
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
                        return Home(user: snapshot.data!);
                      }
                      return Landing();
                    },
                  );
                }
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              },
            );
          }),
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
            ...isDesktop ? [SizedBox(width: 24.0), SizedBox(height: 60, child: VerticalDivider()), SizedBox(width: 24.0)] : [SizedBox(height: 24.0)],
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      final googleUser = await GoogleSignIn().signIn();
                      final googleAuth = await googleUser?.authentication;
                      if (googleAuth != null) {
                        final credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await FirebaseAuth.instance.signInWithCredential(credential);
                      } else {
                        setState(() => loading = false);
                      }
                    },
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.all(22.0)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
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
