import 'package:char/firebase_options.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
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
          home: FutureBuilder(
            initialData: false,
            future: future,
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return StreamBuilder(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Home();
                    }
                    return Landing();
                  },
                );
              }
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          ),
        );
      },
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
        title: Text('Char'),
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 10),
          child: SizedBox(
            width: 500,
            child: Center(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(999.9)),
                  fillColor: Colors.black26,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
                  filled: true,
                  hintText: 'Search Char',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  hoverColor: Colors.black12,
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
              ),
            ),
          ),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.settings)), SizedBox(width: 10.0)],
      ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Char', style: TextStyle(fontSize: 28.0)),
            SizedBox(width: 24.0),
            SizedBox(height: 60, child: VerticalDivider()),
            SizedBox(width: 24.0),
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
          ],
        ),
      ),
    );
  }
}
